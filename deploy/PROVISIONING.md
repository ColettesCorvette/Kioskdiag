# Provisioning de la borne RK3568

Ce fichier, c'est le journal de bord de l'installation de la borne fluxia.
La consigne qu'on m'a donnée : noter **exactement ce que j'ai installé, comment,
et dans quel ordre**. Parce qu'à la fin il faudra repartir d'une image propre,
tout réinstaller dedans en suivant ce document, faire un snapshot de la mémoire
flash (eMMC) qui servira d'image de référence pour les futures bornes, et
mettre à jour la config Puppet pour convertir le parc existant à ce
fonctionnement.

Donc règle simple : toute commande passée sur la borne doit finir ici. Si un
truc manque, c'est un bug de ce document.

## Vue d'ensemble

La borne fait tourner deux applis sur le même écran :

- **kioskview** : l'écran client permanent (Core2, Vue + Go en Docker).
  Affiché au boot, toujours visible. Tourne sous weston + chromium en kiosque.
- **kioskdiag** : le diag/config tourniquet (Flutter, embedder flutter-elinux).
  Client du même weston, lancé à la demande par un geste 4 coins sur la dalle,
  fermé par le bouton Quitter ou un timeout d'inactivité (3 min).

Pourquoi weston au milieu : le GPU (Mali-G52) n'accélère qu'en Wayland avec le
blob Mali g24p0 — X11 retombe en rendu logiciel, trop lent. Et surtout, weston
garde `/dev/dri/card0` ouvert en permanence et les deux applis ne sont que des
clients. C'est ce qui évite le crash kernel (GEM use-after-free) qu'on avait
quand l'appli possédait card0 elle-même (détail dans
`docs/diagnostic-crash.md` du dépôt kioskdiag).

## Le disque : on ne repartitionne JAMAIS

eMMC ~29 Go, table GPT Rockchip. Root fait 6 Go, `/data` fait 22,8 Go.

Les partitions p1 à p5 (secteurs 16384 à 491519) sont la zone bootloader, avec
des offsets U-Boot figés. Si on y touche, la carte ne boote plus et il faut
passer en maskrom (démonter le dissipateur, court-circuiter deux pins de
l'eMMC). Donc : on n'y touche pas, et on n'agrandit pas root. Tout ce qui
grossit va sur `/data`. Root est référencé par PARTUUID dans la cmdline, pas
par numéro de partition.

## Journal d'installation

Dans l'ordre où je l'ai fait, depuis l'image d'origine de la borne
(**TODO à vérifier sur borne** : nom/version exacte de l'image d'origine).
Weston, Docker, gcc et les blobs de base étaient déjà dessus.

### 1. Déporter Docker et containerd sur /data

Root (6 Go) saturait. Ce que j'ai déplacé :

- **Docker** : data-root sur `/data/docker`, driver `fuse-overlayfs`. Réglé
  dans `/etc/docker/daemon.json`.
- **containerd** : il gardait ~1 Go de blobs d'images (namespace moby) sur
  `/var/lib/containerd`. Bind-mount vers `/data/containerd` via une ligne dans
  `/etc/fstab` :

      /data/containerd  /var/lib/containerd  none  bind  0 0

- **Nettoyage** : `apt clean`, vacuum de journald, vieilles révisions snap,
  `/var/lib/apt/lists`.

Piège au reboot : le bind-mount containerd dépend de `/data` (mmcblk0p8) monté
avant containerd. Si `/data` ne monte pas, containerd démarre vide. Après
chaque reboot, vérifier avec `ctr -n moby images ls`.

### 2. sudoers du kiosque

weston en seat builtin veut root, donc le kiosque a besoin de sudo sans mot de
passe : fichier `/etc/sudoers.d/kioskview-kiosk`.

### 3. kioskview (l'écran client)

Source : le dépôt `~/kioskview` sur le Mac. Avant on était en X11
(startx + matchbox + chromium) qui tournait en logiciel ; on est passé à
weston. Fichiers posés sur la carte :

- `/home/orbinea/run-weston-chromium.sh` — lance weston DRM + kiosk-shell +
  chromium. Vient de `~/kioskview/deploy/`.
- `/etc/systemd/system/kioskview-kiosk.service` — démarre ce script sur un
  VT réel au boot (openvt sur VT2, `User=root`, `Restart=always`).

Config weston : backend DRM, kiosk-shell, `idle-time=0`,
`LIBSEAT_BACKEND=builtin`, socket `wayland-tc` dans
`XDG_RUNTIME_DIR=/run/user/0`, shims Mali dans `/run/kioskview-mali`. Sortie
sur le panel `DSI-1` (HDMI débranché), rotation portrait via
`[output] transform=rotate-90` (weston 13 refuse `90` tout court).

chromium côté client : `--ozone-platform=wayland --kiosk --no-sandbox
--disable-gpu --user-data-dir=/tmp/chromium-kiosk http://127.0.0.1:8082`.

Le contenu servi sur :8082 vient du container `turnstile`
(`alpha.srv.orbinea:5000/kioskview:arm-2026.20.5`), en `restart=always`, géré
par Docker tout seul — le script ne le lance pas.

Deux noms sont partagés avec kioskdiag : le socket `wayland-tc` et le dossier
`/run/kioskview-mali`. Si on les change ici, il faut les changer aussi dans
`launch-kioskdiag.sh`.

### 4. Le blob Mali

- Posé en `/data/kioskdiag-pi/libmali-bifrost-g52-g24p0-x11-wayland-gbm.so`
  (le dossier s'appelle encore kioskdiag-pi, vestige de l'époque flutter-pi).
- Provenance : `~/tripod-debs` sur le Mac. Une copie compressée est versionnée
  dans `deploy/blobs/` avec son sha256 — voir `deploy/blobs/README.md` pour la
  restaurer.
- C'est la variante **combinée x11-wayland-gbm**, pas `g24p0-gbm` seul (qui
  cible la mauvaise plateforme et ne marche pas).

### 5. kioskdiag (le bundle Flutter)

Construit sur le Mac en Docker arm64 :

    docker build -f Dockerfile.elinux --target export \
      --output type=local,dest=dist-elinux .

Déployé **à la racine** de `/data/kioskdiag-gtk/` — le lanceur attend
`kioskdiag`, `lib/` et `data/` directement là, pas dans un sous-dossier :

    rsync -a --delete dist-elinux/ orbinea@fluxia:/data/kioskdiag-gtk/

À côté du bundle : `eglshim.so`, compilé sur la carte depuis
`deploy/eglshim.c`. C'est un LD_PRELOAD qui force
`eglGetPlatformDisplayEXT` en Wayland (sinon le blob part en X11 et crashe) :

    gcc -shared -fPIC -O2 -o /data/kioskdiag-gtk/eglshim.so \
        /data/kioskdiag-gtk/eglshim.c -ldl

### 6. Le démon de geste et le lanceur

Trois fichiers :

- `/usr/local/bin/gesture-daemon` — lit l'evdev du tactile, détecte la
  séquence 4 coins. Compilé depuis `deploy/gesture-daemon.c`.
- `/usr/local/bin/launch-kioskdiag.sh` — lance kioskdiag comme client de
  `wayland-tc`. Vient de `deploy/launch-kioskdiag.sh`. Mono-instance via
  `/run/kioskdiag.pid`.
- `/etc/systemd/system/gesture-daemon.service` — lance le démon au boot,
  après kioskview-kiosk.

Compilation (le selftest doit afficher OK avant de poser le binaire) :

    gcc -DSELFTEST -O2 -o /tmp/gd-selftest deploy/gesture-daemon.c && /tmp/gd-selftest
    gcc -O2 -o /usr/local/bin/gesture-daemon deploy/gesture-daemon.c
    install -m 755 deploy/launch-kioskdiag.sh /usr/local/bin/launch-kioskdiag.sh

(Le warning `ignoring return value of 'system'` au build est sans conséquence.)

Trouver le touchscreen :

    sudo libinput list-devices

Sur cette borne c'est `ILITEK ILITEK-TP`, soit `/dev/input/event5`. La
numérotation eventN n'est **pas** garantie stable d'une carte à l'autre — dans
Puppet il faudra résoudre le device par son nom, pas coder event5 en dur (voir
la section Puppet).

Installer le service :

    sed 's#/dev/input/eventX#/dev/input/event5#' deploy/gesture-daemon.service \
      | sudo tee /etc/systemd/system/gesture-daemon.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now gesture-daemon.service

Attention : un sed raté qui laisse `eventN` littéral donne un device qui
n'existe pas. Vérifier l'ExecStart et que `systemctl status` dit bien
`active (running)`.

### 7. Paquets installés à la main

Un seul : `libinput-tools` (pour `libinput list-devices`). Ça tire
`python3-libevdev` et `python3-pyudev`. C'est un outil de provisioning, pas une
dépendance runtime. Tout le reste (weston, docker, gcc, les libs Wayland) était
déjà sur l'image d'origine.

**TODO à vérifier sur borne** : figer les versions exactes
(`apt list --installed | grep …`) de weston, docker, libinput-tools au moment
du snapshot, et les noter ici.

## Arborescence cible

Ce que la borne doit contenir une fois provisionnée, en plus de l'image de
base :

```
/data/
├── docker/                     # data-root Docker (daemon.json)
├── containerd/                 # bind-mounté sur /var/lib/containerd (fstab)
├── kioskdiag-pi/
│   └── libmali-bifrost-g52-g24p0-x11-wayland-gbm.so   # blob Mali (sha256 dans deploy/blobs/README.md)
└── kioskdiag-gtk/              # bundle flutter-elinux à la racine
    ├── kioskdiag               # binaire embedder
    ├── lib/  data/             # runtime du bundle
    ├── eglshim.c  eglshim.so   # shim EGL (compilé sur place)
    └── run-weston-elinux.sh    # lancement autonome (debug)

/usr/local/bin/
├── gesture-daemon              # compilé depuis deploy/gesture-daemon.c
└── launch-kioskdiag.sh

/home/orbinea/
└── run-weston-chromium.sh      # vient de ~/kioskview/deploy/

/etc/
├── docker/daemon.json          # data-root=/data/docker, fuse-overlayfs
├── fstab                       # + ligne bind /data/containerd
├── sudoers.d/kioskview-kiosk
└── systemd/system/
    ├── kioskview-kiosk.service
    ├── gesture-daemon.service  # ExecStart avec le bon /dev/input/eventN
    └── kioskdiag.service       # démarrage manuel seulement (debug)
```

## Ordre de démarrage

    boot
     └─ kioskview-kiosk.service   weston DRM sur VT2, socket wayland-tc, chromium
         └─ gesture-daemon.service  lit le tactile, attend le geste
              └─ geste 4 coins → launch-kioskdiag.sh → kioskdiag client de wayland-tc

kioskdiag n'a pas de service au boot : il est lancé à la demande. On en revient
à kioskview par le bouton Quitter ou par le timeout d'inactivité (3 min) :
kioskdiag fait `exit(0)` et chromium réapparaît dessous.

## Vers l'image de référence (snapshot eMMC)

Le but final : une image qu'on flashe sur chaque nouvelle borne, suivie d'un
passage Puppet pour la conf par-borne. Procédure prévue :

### 1. Valider la borne

- Reboot complet, puis dérouler la checklist de
  `deploy/README-acces-diag.md` (geste, quitter, timeout, survie au reboot).
- `/data` monté, `ctr -n moby images ls` peuplé, container `turnstile` up.

### 2. Nettoyer avant snapshot

Tout ce qui est propre à CETTE borne ou périssable ne doit pas partir dans
l'image :

- logs : `journalctl --vacuum-time=1s`, vider `/tmp/*.log` (weston, kioskdiag) ;
- historique shell (`~/.bash_history` de orbinea et root) ;
- bail DHCP et identifiants réseau spécifiques ;
- clés SSH d'hôte : à trancher — les régénérer au premier boot est plus propre
  (**TODO** : décider avec l'équipe + le mécanisme, service firstboot ?) ;
- machine-id : vider `/etc/machine-id` pour qu'il se régénère au boot
  (**TODO à valider** : vérifier que l'image d'origine le gère).

### 3. Dumper l'eMMC

Deux options, à trancher au moment de le faire :

- en maskrom avec `upgrade_tool` de Rockchip (propre, mais il faut ouvrir la
  borne) ;
- `dd` de `/dev/mmcblk0` à chaud, système figé au maximum (services stoppés,
  `sync`, remount ro si possible). Acceptable si l'image est vérifiée après.

**TODO** : documenter ici la commande exacte retenue et la taille/le sha de
l'image produite.

### 4. Archiver ensemble

L'image, ce document, et les artefacts (bundle kioskdiag, blob Mali, sources
gesture-daemon/eglshim) au même endroit, avec les versions.

### 5. Restaurer sur une borne neuve

Flasher l'image, laisser Puppet faire la conf par-borne (touchscreen, identité,
réseau, rotation). Puis revérifier que `/data` monte et que
`ctr -n moby images ls` est peuplé.

## Conversion du parc via Puppet

Ce qu'il faudra porter en manifests pour amener une borne existante à l'état
de l'image de référence, sans reflash :

- **Fichiers statiques** : `daemon.json`, la ligne fstab containerd, le
  sudoers, `run-weston-chromium.sh`, `kioskview-kiosk.service`,
  `launch-kioskdiag.sh`, `gesture-daemon.service`.
- **Binaires compilés** (`gesture-daemon`, `eglshim.so`) : soit committer les
  arm64, soit un exec de compilation idempotent (`creates =>`).
- **Le bundle kioskdiag** comme artefact versionné déployé dans
  `/data/kioskdiag-gtk/`, et le blob Mali dans `/data/kioskdiag-pi/`
  (vérifiable par son sha256).
- **Le touchscreen** : ne pas coder event5 en dur. Le résoudre par nom
  (ILITEK), soit par une règle udev qui crée un symlink stable type
  `/dev/input/touchscreen`, soit par un ExecStartPre qui lit
  `/proc/bus/input/devices`.
- **La conf par-borne** : la variable d'environnement `KIOSKDIAG_ROTATION`
  (0 à 3, quarts de tour) pour les tourniquets dont l'écran est monté dans
  l'autre sens — même logique que le `transform=` du weston.ini de
  kioskview.
- **Les invariants** : `wayland-tc` et `/run/kioskview-mali` identiques
  entre l'unité weston kioskview et `launch-kioskdiag.sh`.
