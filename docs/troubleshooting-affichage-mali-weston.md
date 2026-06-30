# Kioskdiag sur RK3568 : l'affichage Mali, et comment on y est arrivé

## Le problème de départ

La borne est une carte RK3568 avec GPU Mali-G52 Bifrost. Elle doit afficher
l'appli Flutter kioskdiag en kiosque, plein écran, en portrait, avec
accélération GL. Le rendu logiciel llvmpipe est trop lent.

Au début on lançait l'appli avec l'embedder flutter-pi. Ça affichait, mais à
chaque arrêt/redémarrage de l'appli le kernel plantait :

```
Unable to handle kernel paging request ...
drm_gem_object_release_handle
```

### Cause du crash kernel

C'est un use-after-free dans le DRM du kernel. Quand flutter-pi ferme
/dev/dri/card0 à l'arrêt, la libération des handles GEM touche de la mémoire
déjà libérée, d'où l'oops, et parfois la carte ne reboote plus.

C'est un bug kernel/driver Mali, pas un bug de l'appli. On ne peut pas le
corriger proprement sans toucher au kernel.

## L'idée qui débloque

Si l'appli ne ferme jamais card0, le bug ne se déclenche jamais. On intercale
donc un compositeur Wayland (weston) qui possède card0 en permanence. L'appli
devient un client de weston et ne touche plus au DRM. weston garde le fd ouvert
tant que la borne tourne, donc le chemin bugué (release_handle à la fermeture)
n'est jamais emprunté.

Stack finale :

```
getty autologin  →  weston (détient card0, backend DRM)
                         └─ kioskdiag (client wl_egl_window, embedder flutter-elinux)
                              └─ rendu Mali g24p0 hardware (EGL/GLES via le blob)
```

## Les pistes essayées

| Piste | Résultat | Pourquoi abandonnée |
|-------|----------|---------------------|
| KASAN kernel | — | Builder un kernel diag pour traquer l'UAF, trop lourd. Remplacé par le contournement weston. |
| flutter-pi direct | plante | Ferme card0, d'où l'UAF GEM kernel. |
| GTK3 sous Wayland (`flutter build linux`) | écran noir | L'embedder GTK3 rend bien en GLES mais ne présente jamais sa frame sous Wayland : gdk_cairo_draw_from_gl ne commit aucun buffer. Reproduit avec un GtkGLArea de 25 lignes, noir alors que le GPU dessine. Indépendant de la version Flutter et d'Impeller. |
| cage / wlroots 0.12 | segfault / D-state | Le vieux blob Mali et wlroots se bloquent sur un deadlock drm_master. Incompatibilité blob/compositeur. |
| logiciel / llvmpipe | lent | Perf inacceptable. |
| weston `[output] transform=90` | segfault embedder | La rotation côté compositeur fait crasher l'embedder eLinux. Rotation déplacée dans l'appli. |
| weston DRM + flutter-elinux Wayland | marche | weston possède card0, elinux est un client wl_egl_window brut comme weston-simple-egl, qui présente vraiment. |

### flutter-elinux plutôt que GTK3

`flutter build linux` produit un embedder GTK3, et GTK3 ne sait pas présenter le
GLES Mali sous Wayland (voir le tableau). flutter-elinux (le fork Sony,
https://github.com/sony/flutter-elinux) a un backend Wayland natif qui crée un
wl_egl_window brut et fait l'eglSwapBuffers. Même code Dart, on change juste
l'embedder.

## Les quatre pièges Mali/EGL

Une fois la stack weston + elinux choisie, il a fallu débloquer quatre problèmes
bas niveau. Ce sont eux qui donnaient écran noir ou segfault à répétition.

### 1. Le bon blob Mali : g24p0 combiné

Le kernel a un driver Mali DDK g18p0. Le blob userspace système
`libmali-bifrost-g52-g2p0-*` est trop vieux pour ce kernel :

- `KBASE_IOCTL_MEM_JIT_INIT` renvoie `Cannot allocate memory` puis double free.
- `eglQueryString()` renvoie NULL, d'où un crash dans
  `strstr(NULL, "EGL_KHR_partial_update")`.

Fix : le blob combiné `libmali-bifrost-g52-g24p0-x11-wayland-gbm.so`. Il a les
symboles modernes (gbm_bo_get_fd_for_plane) et matche le kernel. On l'utilise
pour weston et pour le client, via des symlinks (voir
deploy/run-weston-elinux.sh).

Attention : le blob `g24p0-gbm` seul (non combiné) cible la mauvaise plateforme.
Il faut la variante x11-wayland-gbm combinée.

### 2. eglGetDisplay part en X11 par défaut

Dans l'API legacy, le blob combiné fait `eglGetDisplay()` en X11 par défaut
(l'API ne précise pas la plateforme). Sans serveur X, il traite le wl_display
comme un Display X11 et crashe dans libX11. `EGL_PLATFORM=wayland` ne suffit pas
pour l'API legacy.

Fix : un LD_PRELOAD minuscule (deploy/eglshim.c) qui réécrit eglGetDisplay pour
appeler `eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT=0x31D8, wl_display, NULL)`,
ce qui force la plateforme Wayland. Compilé sur la carte :

```sh
gcc -shared -fPIC -O2 -o eglshim.so eglshim.c -ldl
```

### 3. Rotation portrait

- `weston [output] transform=90` fait segfaulter l'embedder eLinux.
- `kioskdiag --fullscreen --rotation=90` donne
  `xdg_surface geometry (600x1024) larger than fullscreen state (1024x600)`.

Fix : la rotation se fait dans le code Dart, via un RotatedBox `_quarterTurns`
dans lib/screens/home_shell.dart (défaut 1). Le bouton double-flèche du header
tourne d'un quart, l'appui long remet le portrait.

### 4. weston a besoin d'un vrai VT

Sans VT actif, weston bloque sur VT_WAITACTIVE. On le lance sur un VT réel :
`sudo openvt -fs -c 2 -- …`. Variables clés : LIBSEAT_BACKEND=builtin,
XDG_RUNTIME_DIR=/run/user/0, shell kiosk-shell.so, require-input=false,
idle-time=0.

## Lancer

1. Build sur Mac Apple Silicon (arm64 natif) :
   ```sh
   docker build -f Dockerfile.elinux --target export \
     --output type=local,dest=dist-elinux .
   ```
2. Copier le bundle dist-elinux/ dans /data/kioskdiag-gtk/ sur la carte, avec
   eglshim.so et run-weston-elinux.sh.
3. Lancer :
   ```sh
   sudo openvt -fs -c 2 -- /data/kioskdiag-gtk/run-weston-elinux.sh
   ```

Le script deploy/run-weston-elinux.sh contient la config commentée.
