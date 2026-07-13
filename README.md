# Kioskdiag — Config / Diagnostic Tourniquets

Appli Flutter de configuration et de diagnostic des tourniquets. Elle tourne en
kiosque plein écran sur une borne RK3568 — la même qui affiche en permanence
kioskview, l'écran client — et on l'ouvre à la demande par un geste sur la
dalle tactile (les 4 coins). Pour le dev, elle se lance aussi sur Mac ou dans
Chrome, avec une simulation de la dalle 600×1024.

## Développement local

Sur Mac ou navigateur :

```sh
flutter pub get
flutter run -d macos        # ou -d chrome
flutter analyze
flutter test                            # tests widget (test/screens, test/widgets)
flutter test test/screens/home_shell_layout_test.dart   # un seul fichier
```

En preview web, l'appli s'affiche dans un cadre qui simule la dalle de la borne
(600×1024 portrait, 1024×600 après rotation), pour développer sans le matériel.

## Ce qu'il y a dans `lib/`

```
lib/
├── main.dart                 # point d'entrée
├── app.dart                  # MaterialApp + thème Material 3
├── theme.dart                # palette de couleurs
├── models/                   # données affichées ; les .mock servent de repli aux services
├── screens/
│   ├── home_shell.dart       # en-tête, rotation, navigation entre les 4 onglets
│   ├── dashboard_screen.dart # uptime, disque, perf mémoire/CPU
│   ├── lecteurs_screen.dart  # liste des lecteurs (RFID, QR, bouton)
│   ├── tests_screen.dart     # commandes de rotation + test du bouton poussoir
│   └── connectivite_screen.dart # config réseau + pavé numérique tactile
├── services/                 # vraies données (uptime/disque via /proc, câble
│                             # ethernet via /sys, gatectl en HTTP port 8080)
├── util/                     # code par plateforme (imports conditionnels io/stub)
└── widgets/                  # cartes, graphes, anneau disque, pastilles, pavé
```

Sur la borne, les onglets affichent les vraies données via `services/`
(imports conditionnels io/stub, car `dart:io` n'existe pas en web). Sur Mac et
dans les tests, où /proc et /sys n'existent pas, les services retombent sur
les valeurs des constructeurs `.mock` — mock et fallbacks doivent rester
identiques. Le contrat HTTP avec la gatectl est une proposition non
confirmée (voir `turnstile_control_io.dart`).

Un détail qui compte : la rotation de l'écran se fait **dans l'appli** (un
`RotatedBox`), jamais côté weston — son transform de sortie fait crasher
l'embedder. Portrait par défaut, ajustable avec le bouton double-flèche du
header, ou par borne avec la variable d'environnement `KIOSKDIAG_ROTATION`
(0 à 3, en quarts de tour).

## La borne : RK3568 + GPU Mali

L'appli tourne comme client de weston. C'est weston qui détient
`/dev/dri/card0`, l'appli n'y touche jamais : ça évite un crash kernel
(use-after-free GEM) qu'on se prenait quand l'appli possédait le DRM elle-même,
du temps de flutter-pi. Le rendu est accéléré par le blob Mali g24p0, via
l'embedder flutter-elinux (le fork de Sony) en backend Wayland.

Tout l'historique — les pistes essayées, les quatre pièges Mali/EGL, pourquoi
pas GTK3 — est raconté dans
[docs/troubleshooting-affichage-mali-weston.md](docs/troubleshooting-affichage-mali-weston.md).
L'analyse du crash kernel d'origine est dans
[docs/diagnostic-crash.md](docs/diagnostic-crash.md).

### Construire le bundle

Build Docker arm64 (depuis le Mac) :

```sh
docker build -f Dockerfile.elinux --target export \
  --output type=local,dest=dist-elinux .
```

### Déployer et lancer

Le déploiement complet de la borne (les deux apps, les services, le blob Mali,
le démon de geste) est documenté pas à pas dans
[deploy/PROVISIONING.md](deploy/PROVISIONING.md). Version courte pour kioskdiag
seul :

```sh
# copier le bundle — PAS de --delete : /data/kioskdiag/ contient aussi les
# scripts, eglshim et gesture-daemon. lib/ et data/ appartiennent à orbinea ;
# le dossier racine à root, donc le binaire top-level (qui ne change que si
# l'embedder change) passe par sudo.
rsync -a dist-elinux/lib dist-elinux/data orbinea@fluxia:/data/kioskdiag/
scp dist-elinux/kioskdiag orbinea@fluxia:/tmp/ \
  && ssh -t orbinea@fluxia sudo install -m755 /tmp/kioskdiag /data/kioskdiag/

# compiler le shim EGL, une fois, sur la carte
gcc -shared -fPIC -O2 -o eglshim.so eglshim.c -ldl

# lancer en autonome (weston + appli) via un VT réel
sudo openvt -fs -c 2 -- /data/kioskdiag/run-weston-elinux.sh
```

En fonctionnement normal, kioskdiag n'est pas lancé comme ça : c'est le geste
4 coins qui le démarre en client du weston de kioskview — et si ce weston
est mort, `launch-kioskdiag.sh` bascule tout seul en weston autonome, l'accès
diag survit à un kioskview HS (voir
[deploy/README-acces-diag.md](deploy/README-acces-diag.md)).

## Notes

- `macos/` et `web/` ne sont pas versionnés : ils ne servent qu'au dev local et
  se régénèrent avec `flutter create`.
- `pubspec.lock` est versionné. Les bundles `dist-elinux/` / `dist-linux/` non.
- Le blob Mali est versionné compressé dans `deploy/blobs/` (voir son README) :
  c'est le seul binaire du projet qu'on ne sait pas reconstruire.
