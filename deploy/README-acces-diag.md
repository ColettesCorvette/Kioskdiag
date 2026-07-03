# Accès diag par le geste 4 coins : déploiement

Le principe : un petit démon C lit le tactile en evdev et, quand on tape les
4 coins de l'écran dans l'ordre, il lance kioskdiag par-dessus kioskview.

Deux noms sont partagés avec le kiosque kioskview : le socket `wayland-tc`
et la base `/run/kioskview-mali`, définis par `kioskview-kiosk.service`
(dépôt `~/kioskview`). Ils doivent rester identiques entre cette unité et
`launch-kioskdiag.sh`, sinon kioskdiag ne trouvera pas le compositeur.

## 1. Identifier le touchscreen

```bash
libinput list-devices        # repérer la dalle, noter son /dev/input/eventX
```

Sinon `cat /proc/bus/input/devices` et chercher la dalle capacitive. Sur la
borne de dev c'est `ILITEK ILITEK-TP` sur event5 — mais le numéro peut changer
d'une carte à l'autre.

Si le geste ne remonte pas alors que weston reçoit bien le tactile, vérifier
que libinput ne fait pas d'EVIOCGRAB exclusif (par défaut il n'en fait pas).

## 2. Compiler et poser les binaires (sur la carte)

```bash
gcc -DSELFTEST -O2 -o /tmp/gd-selftest gesture-daemon.c && /tmp/gd-selftest   # doit afficher OK
gcc -O2 -o /usr/local/bin/gesture-daemon gesture-daemon.c
install -m 755 launch-kioskdiag.sh /usr/local/bin/launch-kioskdiag.sh
```

Le selftest d'abord : si la logique de détection est cassée, autant le voir
avant de poser le binaire.

## 3. Installer le service

Remplacer `eventX` par le vrai device trouvé à l'étape 1 :

```bash
sed "s#/dev/input/eventX#/dev/input/event5#" gesture-daemon.service \
  | sudo tee /etc/systemd/system/gesture-daemon.service
sudo systemctl daemon-reload
sudo systemctl enable --now gesture-daemon.service
sudo systemctl status gesture-daemon.service --no-pager
```

Piège vécu : un sed raté qui laisse `eventN` littéral pointe sur un device qui
n'existe pas, et le service tourne dans le vide. Relire l'ExecStart.

## 4. Tester

- Taper les 4 coins HG, HD, BD, BG en moins de 5 s : kioskdiag apparaît plein
  écran.
- Test négatif : des taps au centre ou un appui simple ne déclenchent rien.
- Bouton Quitter : retour kioskview.
- 3 min sans toucher kioskdiag : retour auto kioskview.
- kioskview reste réactif au tactile (le démon ne vole pas les events).
- Survit au reboot : après `sudo reboot`, `systemctl is-enabled gesture-daemon`
  vaut `enabled` et le geste marche toujours.
- Si l'ordre des coins ne colle pas au sens physique de la dalle (écran monté
  autrement), ajuster `EXPECTED[]` dans `gesture-daemon.c` et recompiler.

## Logs

```bash
journalctl -u gesture-daemon.service -f
tail -f /tmp/kioskdiag-diag.log
```
