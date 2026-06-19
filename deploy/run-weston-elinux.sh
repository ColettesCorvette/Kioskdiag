#!/bin/sh
# Lance kioskdiag (embedder flutter-elinux WAYLAND) en kiosque sous weston.
# === CONFIG GAGNANTE (validée hardware sur la borne RK3568 / Mali g24p0) ===
#
# Pourquoi cette stack :
#  - GTK3 ne présente pas le GLES Mali sous Wayland -> on utilise l'embedder
#    flutter-elinux (client wl_egl_window brut, comme weston-simple-egl).
#  - weston possède /dev/dri/card0 -> l'appli n'y touche jamais -> plus de
#    use-after-free GEM (le bug de flutter-pi).
#  - Blob Mali g24p0 COMBINÉ (x11-wayland-gbm) : le g2p0 système est trop vieux
#    (eglQueryString NULL / JIT). g24p0-gbm seul = mauvaise plateforme.
#  - eglshim.so : le blob combiné fait du X11 par défaut dans eglGetDisplay
#    (legacy, ambigu) et CRASHE sans serveur X. Le shim réécrit eglGetDisplay
#    -> eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT) pour forcer le Wayland.
#  - Rotation portrait : PAS via weston `[output] transform=` (ça fait segfaulter
#    l'embedder eLinux) -> on la fait DANS l'appli (RotatedBox / _quarterTurns).
set -eu

BUNDLE=/data/kioskdiag-gtk
BIN="$BUNDLE/kioskdiag"
SHIM=/run/kioskdiag-mali
WDISP=wayland-tbx
MALI=/data/kioskdiag-pi/libmali-bifrost-g52-g24p0-x11-wayland-gbm.so
SHIMSO="$BUNDLE/eglshim.so"
[ -e "$MALI" ]   || { echo "blob absent: $MALI" >&2; exit 1; }
[ -e "$SHIMSO" ] || { echo "eglshim.so absent: $SHIMSO" >&2; exit 1; }

rm -rf "$SHIM"; mkdir -p "$SHIM/gbm" "$SHIM/wl"
# weston (compositeur) : plateforme GBM
for f in libEGL.so.1 libGLESv2.so.2 libgbm.so.1; do ln -sf "$MALI" "$SHIM/gbm/$f"; done
# client eLinux : EGL/GLES + wl_egl_window, tous depuis le blob g24p0
for f in libEGL.so.1 libGLESv2.so.2 libwayland-egl.so.1; do ln -sf "$MALI" "$SHIM/wl/$f"; done

export XDG_RUNTIME_DIR=/run/user/0; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
export LIBSEAT_BACKEND=builtin
printf '[core]\nshell=kiosk-shell.so\nrequire-input=false\nidle-time=0\n' >/run/weston.ini

echo ">> weston"
LD_LIBRARY_PATH="$SHIM/gbm" weston --backend=drm --socket="$WDISP" \
    --config=/run/weston.ini --log=/tmp/weston.log &
WPID=$!
i=0; while [ ! -S "$XDG_RUNTIME_DIR/$WDISP" ] && [ "$i" -lt 40 ]; do i=$((i+1)); sleep 0.25; done
[ -S "$XDG_RUNTIME_DIR/$WDISP" ] || { echo "weston KO"; cat /tmp/weston.log; kill "$WPID" 2>/dev/null||true; exit 1; }
sleep 1

echo ">> kioskdiag (eLinux/wayland, Mali g24p0 hardware)"
WAYLAND_DISPLAY="$WDISP" EGL_PLATFORM=wayland LD_PRELOAD="$SHIMSO" \
    LD_LIBRARY_PATH="$SHIM/wl:$BUNDLE/lib" \
    "$BIN" --bundle="$BUNDLE" --no-cursor >/tmp/tbx.log 2>&1 &
CPID=$!
echo ">> PID $CPID"
wait "$CPID"
