# Accès diag kioskdiag par geste 4 coins — déploiement

## 1. Identifier le touchscreen

```bash
libinput list-devices        # repérer le périphérique tactile, noter son /dev/input/eventX
```

Ou : `cat /proc/bus/input/devices` (chercher la dalle capacitive).

Vérifier qu'aucun grab exclusif : si le geste ne remonte pas alors que weston reçoit le tactile, contrôler que libinput n'EVIOCGRAB pas (cas par défaut : non).

## 2. Compiler et poser les binaires (sur la carte)

```bash
gcc -DSELFTEST -O2 -o /tmp/gd-selftest gesture-daemon.c && /tmp/gd-selftest   # doit afficher OK
gcc -O2 -o /usr/local/bin/gesture-daemon gesture-daemon.c
install -m 755 launch-kioskdiag.sh /usr/local/bin/launch-kioskdiag.sh
```

## 3. Installer le service (remplacer eventX par le vrai device)

```bash
sed "s#/dev/input/eventX#/dev/input/event5#" gesture-daemon.service \
  | sudo tee /etc/systemd/system/gesture-daemon.service
sudo systemctl daemon-reload
sudo systemctl enable --now gesture-daemon.service
sudo systemctl status gesture-daemon.service --no-pager
```

## 4. Tester

- Taper les 4 coins HG → HD → BD → BG en < 5 s → kioskdiag apparaît plein écran.
- **Test négatif** : taps au centre / appui simple → ne déclenche PAS kioskdiag.
- Bouton "Quitter" → retour kioskview.
- 3 min sans toucher kioskdiag → retour auto kioskview.
- Vérifier que kioskview reste réactif au tactile (events non volés).
- **Survit au reboot** : `sudo reboot`, puis `systemctl is-enabled gesture-daemon` = `enabled` et le geste fonctionne toujours.
- Calibrer l'ordre des coins : si HG/HD/... ne correspond pas au sens physique, ajuster `EXPECTED[]` dans gesture-daemon.c et recompiler.

## Logs

```bash
journalctl -u gesture-daemon.service -f
tail -f /tmp/kioskdiag-diag.log
```
