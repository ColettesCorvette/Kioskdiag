# Kioskdiag — Config / Diagnostic Tourniquets

Application Flutter de configuration et de diagnostic des tourniquets.

## Développement local

Sur Mac ou navigateur :

```sh
flutter pub get
flutter run -d macos        # ou -d chrome
flutter analyze
flutter test
```

## Structure de `lib/`

```
lib/
├── main.dart                 # point d'entrée
├── app.dart                  # MaterialApp + thème
├── theme.dart                # palette de couleurs
├── models/
│   └── diagnostic_data.dart  # données affichées, en mock pour l'instant
├── screens/
│   ├── home_shell.dart       # en-tête + navigation entre onglets
│   └── dashboard_screen.dart # onglet Dashboard : uptime, disque, perf
└── widgets/                  # cartes, graphes, anneau disque, pastilles
```

Les onglets Lecteurs, Tests et Connectivité restent à implémenter. Les vraies
métriques système remplaceront `DiagnosticData.mock`.

## Cible : borne RK3568 / GPU Mali

L'app tourne en kiosque comme **client de weston**. weston détient `/dev/dri/card0`,
l'app n'y touche jamais. Cela évite le crash kernel use-after-free GEM qui
survenait avec flutter-pi. Le rendu est accéléré matériellement par le blob Mali
g24p0 via l'embedder **flutter-elinux** en backend Wayland.

L'historique complet des problèmes et des correctifs est dans
[docs/troubleshooting-affichage-mali-weston.md](docs/troubleshooting-affichage-mali-weston.md).

### Construire le bundle

Build Docker arm64, reproductible :

```sh
docker build -f Dockerfile.elinux --target export \
  --output type=local,dest=dist-elinux .
```

### Déployer et lancer

Copier sur la carte le bundle `dist-elinux/`, le script
`deploy/run-weston-elinux.sh` et `deploy/eglshim.c` dans `/data/kioskdiag-gtk/`.

Compiler le shim EGL sur la carte une fois :

```sh
gcc -shared -fPIC -O2 -o eglshim.so eglshim.c -ldl
```

Lancer via un VT réel :

```sh
sudo openvt -fs -c 2 -- /data/kioskdiag-gtk/run-weston-elinux.sh
```

Le script `run-weston-elinux.sh` contient la configuration commentée : symlinks
du blob Mali, weston en backend DRM, lancement du client avec
`LD_PRELOAD=eglshim.so`. La rotation portrait se fait dans l'app, jamais via le
transform de weston qui fait crasher l'embedder.

## Notes

- `macos/` et `web/` ne sont pas versionnés, ils servent au dev/test local et
  sont régénérables via `flutter create`.
- `pubspec.lock` est versionné.
- Les bundles de build `dist-elinux/` et `dist-linux/` ne sont pas versionnés.
