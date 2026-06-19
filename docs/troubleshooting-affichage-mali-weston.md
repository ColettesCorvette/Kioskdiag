# Kioskdiag sur RK3568 — l'histoire complète des galères d'affichage

## Le problème de départ

La borne est une carte **RK3568** avec GPU **Mali-G52 Bifrost**
qui doit afficher l'appli Flutter **kioskdiag** en kiosque, **plein écran**, en
**portrait**, avec **accélération matérielle GL** le rendu logiciel llvmpipe est
trop lent.

Au début on lançait l'appli avec l'embedder **flutter-pi**. 
Ça affichait, mais à chaque arrêt/redémarrage de l'appli
le kernel plantait :

```
Unable to handle kernel paging request ...
drm_gem_object_release_handle
```

### Cause racine du crash kernel

C'est un **use-after-free** dans le DRM du kernel. Quand flutter-pi
ferme `/dev/dri/card0` à l'arrêt, la libération des handles GEM touche de la
mémoire déjà libérée → oops kernel → parfois la carte ne reboot plus.

C'est un bug kernel/driver Mali et pas un bug de l'appli. On ne peut pas le
corriger proprement sans toucher au kernel.

## L'idée qui débloque tout

> Si l'appli ne ferme jamais `card0`, le bug ne se déclenche jamais.

Donc : on intercale un compositeur Wayland (weston) qui possède `card0` en
permanence. L'appli devient un simple client de weston : elle ne touche
plus jamais au DRM. Weston, lui, garde le fd ouvert tant que la borne tourne →
le chemin de code bugué `release_handle` à la fermeture n'est **jamais**
emprunté.

**Stack finale qui marche :**

```
getty autologin  →  weston (détient card0, backend DRM)
                         └─ kioskdiag (client wl_egl_window, embedder flutter-elinux)
                              └─ rendu Mali g24p0 hardware (EGL/GLES via le blob)
```

## Les pistes essayées et pourquoi elles sont mortes

| Piste | Résultat | Pourquoi abandonnée |
|-------|----------|---------------------|
| **KASAN kernel** | — | Builder un kernel diagnostic pour traquer l'UAF : trop lourd. Abandonné au profit du contournement weston. |
| **flutter-pi direct** | plante | le fameux bug : ferme `card0` → UAF GEM kernel. |
| **GTK3 sous Wayland** `flutter build linux` | **écran noir** | L'embedder GTK3 **rend** bien en GLES mais ne présente jamais sa frame sous Wayland : `gdk_cairo_draw_from_gl` ne commit aucun buffer. Prouvé indépendamment par un `GtkGLArea` minimal de 25 lignes → noir alors que le GPU dessine. Indépendant de la version Flutter, pas lié à Impeller. Cul-de-sac structurel. |
| **cage / wlroots 0.12** | segfault / D-state | Le vieux blob Mali système et wlroots se bloquent sur un deadlock `drm_master`. Incompatibilité blob/compositeur. |
| **logiciel / llvmpipe** | lent | catastrophe niveau perf. |
| **weston `[output] transform=90`** | segfault embedder | Faire la rotation portrait côté compositeur fait crasher l'embedder eLinux. → rotation déplacée dans l'appli. |
| **weston DRM et flutter-elinux Wayland** | **MARCHE** | weston possède `card0`, elinux est un client `wl_egl_window` brut comme `weston-simple-egl` qui présente réellement. |

### Pourquoi flutter-elinux et pas GTK3 ?

`flutter build linux` produit un embedder GTK3. GTK3 ne sait pas présenter le
GLES Mali sous Wayland (cf. tableau). flutter-elinux (le fork Sony,
<https://github.com/sony/flutter-elinux>) a un backend Wayland natif qui crée
un `wl_egl_window` brut et fait le `eglSwapBuffers`. Même code
Dart, on change juste l'embedder.

## Les 4 pièges Mali/EGL et leurs correctifs

Une fois la stack weston+elinux choisie, il a fallu débloquer 4 problèmes de bas
niveau. Ce sont eux qui causaient écran noir ou segfault  à répétition.

### 1. Le bon blob Mali : `g24p0` combiné 

Le kernel a un driver Mali **DDK g18p0**. Le blob userspace système
`libmali-bifrost-g52-g2p0-*` est trop vieux pour ce kernel :

- `KBASE_IOCTL_MEM_JIT_INIT` → `Cannot allocate memory` puis double free.
- `eglQueryString()` renvoie **NULL** → crash dans `strstr(NULL, "EGL_KHR_partial_update")`.

**Fix** : utiliser le blob combiné g24p0
`libmali-bifrost-g52-g24p0-x11-wayland-gbm.so`. 
Il a les symboles modernes `gbm_bo_get_fd_for_plane`et matche le kernel. 
On l'utilise et pour weston et pour le client via des symlinks (cf. `deploy/run-weston-elinux.sh`).

> Le blob `g24p0-gbm` seul (non combiné) cible la mauvaise plateforme.
> Il faut bien la variante **x11-wayland-gbm** combinée.

### 2. `eglGetDisplay` fait du X11 par défaut → `deploy/eglshim.c`

Le blob combiné dans l'API legacy `eglGetDisplay()` choisit X11 par
défaut (l'API ne précise pas la plateforme, elle est ambiguë). Sans serveur X,
il traite le `wl_display` comme un `Display` X11 et crashe dans libX11. 
Et `EGL_PLATFORM=wayland` ne suffit pas pour l'API legacy.

**Fix** : `LD_PRELOAD` d'un shim minuscule (`deploy/eglshim.c`) qui réécrit
`eglGetDisplay` pour appeler `eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT=0x31D8, wl_display, NULL)` → plateforme Wayland forcée. 
Compilé sur la carte :

```sh
gcc -shared -fPIC -O2 -o eglshim.so eglshim.c -ldl
```

### 3. Rotation portrait : 

- `weston [output] transform=90` → segfault de l'embedder eLinux.
- `kioskdiag --fullscreen --rotation=90` → `xdg_surface geometry (600x1024) larger than fullscreen state (1024x600)`.

**Fix** : la rotation se fait dans le code Dart via un `RotatedBox`
`_quarterTurns` dans `lib/screens/home_shell.dart`. Le défaut est `1`. 
Le bouton double-flèche du header tourne d'un quart et l'appui long remet le portrait.

### 4. weston a besoin d'un vrai VT

Lancer weston sans VT actif → blocage sur `VT_WAITACTIVE`. On le lance via un VT
réel : `sudo openvt -fs -c 2 -- …`. Variables clés :
`LIBSEAT_BACKEND=builtin`, `XDG_RUNTIME_DIR=/run/user/0`, shell
`kiosk-shell.so`, `require-input=false`, `idle-time=0`.

## Comment lancer 

1. **Build** sur Mac Apple Silicon, arm64 natif :
   ```sh
   docker build -f Dockerfile.elinux --target export \
     --output type=local,dest=dist-elinux .
   ```
2. Copier le bundle `dist-elinux/` dans `/data/kioskdiag-gtk/` sur la carte, avec
   `eglshim.so` et `run-weston-elinux.sh`.
3. Lancer :
   ```sh
   sudo openvt -fs -c 2 -- /data/kioskdiag-gtk/run-weston-elinux.sh
   ```
Le script `deploy/run-weston-elinux.sh` contient la bonne config commentée