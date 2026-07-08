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
├── models/                   # données affichées — tout est en mock pour l'instant
├── screens/
│   ├── home_shell.dart       # en-tête, rotation, navigation entre les 4 onglets
│   ├── dashboard_screen.dart # uptime, disque, perf mémoire/CPU
│   ├── lecteurs_screen.dart  # liste des lecteurs (RFID, QR, bouton)
│   ├── tests_screen.dart     # commandes de rotation + test du bouton poussoir
│   └── connectivite_screen.dart # config réseau + pavé numérique tactile
├── util/                     # code par plateforme (imports conditionnels io/stub)
└── widgets/                  # cartes, graphes, anneau disque, pastilles, pavé
```

Les quatre onglets existent mais les données sont encore mockées
(`DiagnosticData.mock`, `ReaderInfo.mock`) : les vraies métriques système et la
vraie config réseau restent à brancher.

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
# copier le bundle à la racine de /data/kioskdiag/
rsync -a --delete dist-elinux/ orbinea@fluxia:/data/kioskdiag/

# compiler le shim EGL, une fois, sur la carte
gcc -shared -fPIC -O2 -o eglshim.so eglshim.c -ldl

# lancer en autonome (weston + appli) via un VT réel
sudo openvt -fs -c 2 -- /data/kioskdiag/run-weston-elinux.sh
```

En fonctionnement normal, kioskdiag n'est pas lancé comme ça : c'est le geste
4 coins qui le démarre en client du weston de kioskview (voir
[deploy/README-acces-diag.md](deploy/README-acces-diag.md)).

## Notes

- `macos/` et `web/` ne sont pas versionnés : ils ne servent qu'au dev local et
  se régénèrent avec `flutter create`.
- `pubspec.lock` est versionné. Les bundles `dist-elinux/` / `dist-linux/` non.
- Le blob Mali est versionné compressé dans `deploy/blobs/` (voir son README) :
  c'est le seul binaire du projet qu'on ne sait pas reconstruire.
