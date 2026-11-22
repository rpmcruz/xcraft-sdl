#!/usr/bin/env bash
# Run and drive xcraft inside a headless sway (Wayland only, no X11).
# Use inside "nix-shell tools/headless/shell.nix".
#
#   hl.sh start [WxH]   start the compositor (default 1016x740)
#   hl.sh game          start ./xcraft in it (log: $HL_DIR/game.log)
#   hl.sh shot FILE     screenshot of the whole output
#   hl.sh move X Y      move the pointer
#   hl.sh click [left|middle|right]
#   hl.sh key TEXT      type text        hl.sh keyname NAME   (e.g. Return)
#   hl.sh stop
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
GAME=$(cd "$HERE/../.." && pwd)
HL_DIR=${HL_DIR:-/tmp/xcraft-hl-$(id -u)}      # short: it holds sockets
export XDG_RUNTIME_DIR=$HL_DIR/run
unset DISPLAY
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"

env_wl () {
  export WAYLAND_DISPLAY=$(cd "$XDG_RUNTIME_DIR" && ls wayland-* 2>/dev/null | grep -v lock | head -1)
  export SWAYSOCK=$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -1)
}

build_vptr () {
  [ -x "$HL_DIR/vptr" ] && return
  xml=$(pkg-config --variable=pkgdatadir wlr-protocols)/unstable/wlr-virtual-pointer-unstable-v1.xml
  wayland-scanner client-header "$xml" "$HL_DIR/wlr-virtual-pointer-unstable-v1-client-protocol.h"
  wayland-scanner private-code  "$xml" "$HL_DIR/vptr-protocol.c"
  cc -O2 -I"$HL_DIR" -o "$HL_DIR/vptr" "$HERE/vptr.c" "$HL_DIR/vptr-protocol.c" \
     $(pkg-config --cflags --libs wayland-client)
}

case "$1" in
  start)
    mode=${2:-1016x740}
    build_vptr
    cat > "$HL_DIR/config" <<CFG
xwayland disable
output HEADLESS-1 mode --custom $mode
output HEADLESS-1 bg #202020 solid_color
default_border none
for_window [title="xcraft"] floating enable, move position 0 0
CFG
    WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
      sway -c "$HL_DIR/config" > "$HL_DIR/sway.log" 2>&1 < /dev/null &
    echo $! > "$HL_DIR/sway.pid"; disown
    sleep 2
    rm -f "$HL_DIR/ptr.fifo"; mkfifo "$HL_DIR/ptr.fifo"
    env_wl
    "$HL_DIR/vptr" "$HL_DIR/ptr.fifo" > "$HL_DIR/vptr.log" 2>&1 < /dev/null &
    echo $! > "$HL_DIR/vptr.pid"; disown
    sleep 0.5
    echo "extent ${mode%x*} ${mode#*x}" > "$HL_DIR/ptr.fifo" ;;
  game)
    env_wl
    (cd "$GAME" && exec env SDL_VIDEODRIVER=wayland ./xcraft) \
      > "$HL_DIR/game.log" 2>&1 < /dev/null &
    echo $! > "$HL_DIR/game.pid"; disown ;;
  shot)    env_wl; grim "$2" ;;
  move)    echo "move $2 $3" > "$HL_DIR/ptr.fifo" ;;
  click)
    case ${2:-left} in left) n=1;; middle) n=2;; right) n=3;; esac
    echo "press $n" > "$HL_DIR/ptr.fifo"; sleep 0.08
    echo "release $n" > "$HL_DIR/ptr.fifo" ;;
  key)     env_wl; wtype -s 300 "$2" ;;     # pause: first key after keymap upload
  keyname) env_wl; wtype -k "$2" ;;
  stop)
    [ -p "$HL_DIR/ptr.fifo" ] &&
      timeout 1 sh -c "echo quit > '$HL_DIR/ptr.fifo'" 2>/dev/null || true
    for p in game vptr sway; do        # only our own processes
      [ -f "$HL_DIR/$p.pid" ] && kill "$(cat "$HL_DIR/$p.pid")" 2>/dev/null || true
      rm -f "$HL_DIR/$p.pid"
    done ;;
esac
