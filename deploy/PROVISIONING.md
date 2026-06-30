# Provisioning borne RK3568

Notes d'install de la borne fluxia. Objectif : pouvoir repartir d'une image
propre, tout réinstaller, faire un snapshot eMMC pour les prochaines bornes, et
porter le tout dans Puppet pour convertir le parc.

La borne fait tourner deux apps sur le même écran :

- kioskview : l'écran client permanent (Core2, Vue+Go en Docker). Affiché au
  boot, toujours visible. Tourne sous weston + chromium kiosk.
- kioskdiag : le diag/config tourniquet (Flutter/elinux). Client du même weston,
  lancé à la demande par un geste 4 coins, fermé par un bouton ou un timeout.

Le GPU (Mali-G52) n'accélère qu'en Wayland avec le blob Mali g24p0. X11 retombe
en rendu logiciel, trop lent. weston garde /dev/dri/card0 ouvert en permanence et
les deux apps sont de simples clients. C'est ce qui évite le crash kernel (GEM
use-after-free) qu'on avait quand l'app possédait card0 elle-même.


## Partitionnement : on n'y touche pas

eMMC ~29 Go, table GPT Rockchip. Root fait 6 Go, /data fait 22.8 Go.

Les partitions p1 à p5 (secteurs 16384 à 491519) sont la zone bootloader, avec
des offsets U-Boot figés. Si on les touche la carte ne boote plus et il faut
passer en maskrom (démonter le dissipateur, court-circuiter deux pins de l'eMMC).
On n'y touche pas. Root est référencé par PARTUUID dans la cmdline, pas par
numéro de partition.

Conséquence : on n'agrandit pas root. Tout ce qui grossit va sur /data.


## Système de base et disque

Root (6 Go) saturait. Ce qu'on a déporté sur /data :

- Docker : data-root sur /data/docker, driver fuse-overlayfs. Réglé dans
  `/etc/docker/daemon.json`.
- containerd : 1 Go de blobs d'images (namespace moby) qui restait sur
  /var/lib/containerd. Bind-mount vers /data/containerd, via une ligne fstab :
  `/data/containerd  /var/lib/containerd  none  bind  0 0`.
- Nettoyage : `apt clean`, vacuum journald, vieilles révisions snap, apt/lists.

Le kiosk a besoin de sudo sans mot de passe (weston en seat builtin veut root) :
`/etc/sudoers.d/kioskview-kiosk`.

Au reboot, le bind-mount containerd dépend de /data (mmcblk0p8) monté avant
containerd. Si /data ne monte pas, containerd démarre vide. Après un reboot,
vérifier avec `ctr -n moby images ls`.


## kioskview (écran client)

Source : `~/kioskview` sur le Mac, déployé sur la carte. Avant on était en X11
(startx + matchbox + chromium), qui tournait en logiciel. On est passé à weston.

Fichiers posés sur la carte :

- `/home/orbinea/run-weston-chromium.sh` : lance weston DRM + kiosk-shell +
  chromium. Vient de `~/kioskview/deploy/`.
- `/etc/systemd/system/kioskview-kiosk.service` : démarre ce script sur un VT
  réel au boot (openvt sur VT2, User=root, Restart=always).
- blob Mali : `/data/kioskdiag-pi/libmali-bifrost-g52-g24p0-x11-wayland-gbm.so`
  (vient de `~/tripod-debs` sur le Mac).

Config weston : backend DRM, kiosk-shell, idle-time=0, LIBSEAT_BACKEND=builtin.
Socket `wayland-tc` dans XDG_RUNTIME_DIR=/run/user/0. Shims Mali dans
`/run/kioskview-mali`. Sortie sur le panel `DSI-1` (HDMI débranché), rotation
portrait via `[output] transform=rotate-90` (weston 13 refuse `90` tout court).

chromium côté client : `--ozone-platform=wayland --kiosk --no-sandbox
--disable-gpu --user-data-dir=/tmp/chromium-kiosk http://127.0.0.1:8082`.

Le contenu servi sur :8082 vient du container `turnstile`
(`alpha.srv.orbinea:5000/kioskview:arm-2026.20.5`), qui est en restart=always et
géré par Docker. Le script ne le lance pas.

Deux noms sont partagés avec kioskdiag : le socket `wayland-tc` et le dossier
`/run/kioskview-mali`. Si on les change ici, les changer dans launch-kioskdiag.sh.


## kioskdiag (diag à la demande)

### Le bundle

Construit sur le Mac en Docker arm64 :

    docker build -f Dockerfile.elinux --target export \
      --output type=local,dest=dist-elinux .

Déployé à la racine de /data/kioskdiag-gtk/. Le lanceur attend `kioskdiag`,
`lib/` et `data/` directement là, pas dans un sous-dossier :

    rsync -a --delete dist-elinux/ orbinea@fluxia:/data/kioskdiag-gtk/

À côté du bundle, eglshim.so, compilé sur la carte depuis deploy/eglshim.c. C'est
un LD_PRELOAD qui force eglGetPlatformDisplayEXT en Wayland (sinon le blob part
en X11 et crashe) :

    gcc -shared -fPIC -O2 -o /data/kioskdiag-gtk/eglshim.so \
        /data/kioskdiag-gtk/eglshim.c -ldl

### Le démon de geste et le lanceur

Trois fichiers :

- `/usr/local/bin/gesture-daemon` : lit l'evdev du tactile, détecte la séquence
  4 coins. Compilé depuis deploy/gesture-daemon.c.
- `/usr/local/bin/launch-kioskdiag.sh` : lance kioskdiag comme client de
  `wayland-tc`. Vient de deploy/launch-kioskdiag.sh. Mono-instance via
  /run/kioskdiag.pid.
- `/etc/systemd/system/gesture-daemon.service` : lance le démon au boot, après
  kioskview-kiosk.

Compilation (le selftest doit afficher OK avant de poser le binaire) :

    gcc -DSELFTEST -O2 -o /tmp/gd-selftest deploy/gesture-daemon.c && /tmp/gd-selftest
    gcc -O2 -o /usr/local/bin/gesture-daemon deploy/gesture-daemon.c
    install -m 755 deploy/launch-kioskdiag.sh /usr/local/bin/launch-kioskdiag.sh

Le warning `ignoring return value of 'system'` au build est sans conséquence.

### Trouver le touchscreen

    sudo libinput list-devices

Sur cette borne c'est `ILITEK ILITEK-TP`, soit /dev/input/event5. La
numérotation eventN n'est pas garantie stable d'une carte à l'autre, donc dans
Puppet il vaut mieux résoudre le device par son nom que coder event5 en dur
(voir plus bas).

### Installer le service

    sed 's#/dev/input/eventX#/dev/input/event5#' deploy/gesture-daemon.service \
      | sudo tee /etc/systemd/system/gesture-daemon.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now gesture-daemon.service

Attention : un sed qui remplace eventX par eventN (le N littéral) laisse un
device qui n'existe pas. Vérifier l'ExecStart et que `systemctl status` dit bien
active (running).


## Paquets installés à la main

Seulement libinput-tools, pour `libinput list-devices`. Ça tire python3-libevdev
et python3-pyudev. C'est un outil de provisioning, pas une dépendance runtime. Le
reste (weston, blobs, docker, gcc) était déjà sur l'image.


## Ordre de démarrage

    boot
     └─ kioskview-kiosk.service   weston DRM sur VT2, socket wayland-tc, chromium
         └─ gesture-daemon.service  lit event5, attend le geste
              └─ geste 4 coins → launch-kioskdiag.sh → kioskdiag client de wayland-tc

kioskdiag n'a pas de service à lui, il est lancé à la demande. On en revient à
kioskview par le bouton Quitter ou par le timeout d'inactivité (3 min) :
kioskdiag fait exit(0) et chromium réapparaît dessous.


## Pour Puppet

À porter en manifests :

- Les fichiers statiques : daemon.json, la ligne fstab containerd, le sudoers,
  run-weston-chromium.sh, kioskview-kiosk.service, launch-kioskdiag.sh,
  gesture-daemon.service.
- Les binaires compilés (gesture-daemon, eglshim.so) : soit committer les arm64,
  soit un exec de compilation idempotent (creates =>).
- Le bundle kioskdiag comme artefact versionné déployé dans /data/kioskdiag-gtk/,
  et le blob Mali dans /data/kioskdiag-pi/.
- Le touchscreen : ne pas coder event5 en dur. Le résoudre par nom (ILITEK), soit
  par une règle udev qui crée un symlink stable type /dev/input/touchscreen, soit
  par un ExecStartPre qui lit /proc/bus/input/devices.
- Garder wayland-tc et /run/kioskview-mali identiques entre les deux unités.


## Snapshot eMMC

Une fois la borne validée :

1. Arrêter les services qui écrivent, faire un sync.
2. Dumper l'eMMC : soit en maskrom avec upgrade_tool de Rockchip, soit dd de
   mmcblk0 à chaud en lecture seule si c'est acceptable.
3. Garder l'image, ce fichier, et les artefacts (binaires, bundle, blob) au même
   endroit.
4. Pour une nouvelle borne : flasher l'image puis laisser Puppet faire la conf
   par-borne (résolution du touchscreen, identité, réseau).

Après un flash, revérifier que /data monte et que `ctr -n moby images ls` est
peuplé.
