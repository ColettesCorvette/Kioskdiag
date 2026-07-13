#!/bin/sh
# Lance kioskdiag comme CLIENT du weston kioskview (socket wayland-tc), à la
# demande (déclenché par gesture-daemon). Mono-instance via verrou flock.
set -eu

BUNDLE=/data/kioskdiag
BIN="$BUNDLE/kioskdiag"
SHIMSO="$BUNDLE/eglshim.so"
MALI=/data/mali/libmali-bifrost-g52-g24p0-x11-wayland-gbm.so
SHIM=/run/kioskview-mali          # même base que le script weston kioskview
WDISP=wayland-tc

# Mono-instance : verrou flock sur un fd dédié, tenu pour toute la durée du
# processus (relâché automatiquement à la sortie/au crash/au kill, même à
# travers le `exec` plus bas). Supprime le TOCTOU et le faux positif par
# réutilisation de PID de l'ancien mécanisme à base de pidfile.
exec 9>/run/kioskdiag.lock
flock -n 9 || exit 0

[ -e "$MALI" ]   || { echo "blob Mali absent: $MALI" >&2; exit 1; }
[ -e "$SHIMSO" ] || { echo "eglshim.so absent: $SHIMSO" >&2; exit 1; }
[ -x "$BIN" ]    || { echo "binaire kioskdiag absent: $BIN" >&2; exit 1; }

# Symlinks Mali côté CLIENT (EGL/GLES + wl_egl_window depuis le blob g24p0).
mkdir -p "$SHIM/wl"
for f in libEGL.so.1 libGLESv2.so.2 libwayland-egl.so.1; do ln -sf "$MALI" "$SHIM/wl/$f"; done

export XDG_RUNTIME_DIR=/run/user/0

# Le critère client/autonome est l'ÉTAT DU SERVICE kiosque, pas la présence du
# fichier socket : un weston tué laisse son socket sur le disque, et un client
# qui s'y connecte segfaulte. Le socket ne sert qu'à attendre que weston soit
# prêt une fois le service jugé vivant.
# Le verrou flock (fd 9) traverse les exec : mono-instance dans les deux modes.
state=$(systemctl is-active kioskview-kiosk.service 2>/dev/null || true)
case "$state" in
  active|activating|reloading)
    # Kiosque vivant (ou en train de revenir) -> kioskdiag CLIENT de son weston.
    i=0; while [ ! -S "$XDG_RUNTIME_DIR/$WDISP" ] && [ "$i" -lt 40 ]; do i=$((i+1)); sleep 0.25; done
    [ -S "$XDG_RUNTIME_DIR/$WDISP" ] || { echo "kiosque '$state' mais socket $WDISP absent" >&2; exit 1; }
    exec env WAYLAND_DISPLAY="$WDISP" EGL_PLATFORM=wayland LD_PRELOAD="$SHIMSO" \
      LD_LIBRARY_PATH="$SHIM/wl:$BUNDLE/lib" \
      "$BIN" --bundle="$BUNDLE" --no-cursor >/tmp/kioskdiag-diag.log 2>&1
    ;;
  *)
    # Kiosque mort -> kioskdiag en weston AUTONOME : l'accès diag par le geste
    # survit à un kioskview HS. VT3 pour ne pas marcher sur le VT2 du
    # kiosque ; à la sortie de kioskdiag, run-weston-elinux.sh éteint son
    # weston (trap) et systemd peut relancer le kiosque normalement.
    echo "kiosque '$state' -> kioskdiag en weston autonome (VT3)" >&2
    exec openvt -fsw -c 3 -- "$BUNDLE/run-weston-elinux.sh"
    ;;
esac
