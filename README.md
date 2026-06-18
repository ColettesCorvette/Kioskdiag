# Kioskdiag — Config / Diagnostic Tourniquets

Application **Flutter** de configuration et de diagnostic des tourniquets.

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
└── widgets/                  # cartes, graphes, anneau disque, pastilles…
```

Les onglets Lecteurs / Tests / Connectivité restent à implémenter. Les vraies
métriques système remplaceront `DiagnosticData.mock`.

## Cible : carte RK3568 avec GPU Mali

Sur la carte, l'app tourne via **flutter-pi** : rendu **directement sur l'écran
via le GPU**.

> **Ne pas builder en GTK desktop** avec `flutter build linux`. Sur cette carte,
> le GL de X11 repose entièrement sur le pilote Mali propriétaire
> flutter-pi contourne X et parle au GPU en direct → accélération matérielle
> Mali, plein écran.

### Construire le bundle

flutter-pi suit une version de Flutter pour laquelle son moteur est publié : **3.41.7**. 

Avec Docker, reproductible et recommandé :

```sh
docker build --target export --output type=local,dest=dist .
# dist/ = flutter-pi + app.so + libflutter_engine.so + icudtl.dat + assets
```

Ou directement sur l'hôte :

```sh
git -C <flutter-sdk> worktree add --detach ~/flutter341 3.41.7
export PATH="$HOME/flutter341/bin:$HOME/.pub-cache/bin:$PATH"
dart pub global activate flutterpi_tool
flutter pub get
flutterpi_tool build --arch arm64 --cpu generic --release
# build/flutter-pi/aarch64-generic/
```

### Déployer et lancer

```sh
scp -r dist/* orbinea@<carte>:/data/kioskdiag-pi/
```

Sur la carte, points à connaître :

- **Lib Mali GBM** : poser le bon blob `libmali-…-gbm.so` dans le bundle, car les
  libs Mali du système peuvent être incohérentes. Faire pointer `libEGL.so.1`,
  `libGLESv2.so.2` et `libgbm.so.1` dessus, puis lancer avec `LD_LIBRARY_PATH`
  réglé sur le bundle.
- **`libatomic.so.1`** requis : `sudo apt-get install -y libatomic1`.
- **Libérer l'écran** : couper le serveur X avant de lancer.
- **Bon device DRM** : flutter-pi auto-sélectionne parfois le mauvais nœud, on force la carte d'affichage `card0` en lui passant un FD ouvert.

```sh
sudo systemctl stop getty@tty1
sudo pkill -x Xorg
cd /data/kioskdiag-pi
sudo bash -c 'exec 3<>/dev/dri/card0; \
  LD_LIBRARY_PATH=. ./flutter-pi --release --drm-fd 3 -r 90 -d "154,86" .'
```

- `-r 90` : dalle 1024×600 montée en **portrait**.
- `-d "154,86"` : dimensions physiques de la dalle, environ 7 pouces, pour la
  bonne échelle de l'UI.

Au démarrage, un **service systemd** lance ce `run.sh` automatiquement, avec
`Conflicts=getty@tty1`, `Restart=always` et `TimeoutStopSec=5s`. 

## Notes

- `macos/` et `web/` ne sont pas versionnés, ils servent au dev/test local ;
  régénérables via `flutter create`.
- `pubspec.lock` **est** versionné.
