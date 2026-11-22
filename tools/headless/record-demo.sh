#!/usr/bin/env bash
# Records docs/gameplay.gif and docs/options.png (seed 1997, ~25 s).
# Run from the repository root after "make":
#   nix-shell tools/headless/shell.nix --run tools/headless/record-demo.sh
set -e
H=$(dirname "$0")/hl.sh
OUT=${HL_DIR:-/tmp/xcraft-hl-$(id -u)}/frames
rm -rf "$OUT"; mkdir -p "$OUT"

$H stop; sleep 1
$H start 1016x740; $H game; sleep 3
$H move 490 524; sleep 0.3; $H click; sleep 0.5   # seed field
$H key 1997; $H keyname Return; sleep 0.5
$H shot "$OUT/menu.png"
$H move 695 450; sleep 0.3; $H click; sleep 5     # Play
$H move 1000 700

( for i in $(seq -w 1 140); do $H shot "$OUT/f$i.png"; sleep 0.12; done ) &
REC=$!
act () { $H move "$1" "$2"; sleep 0.4; $H click; sleep "$3"; }
sleep 1.5
act 671 377 1.0; act 156 342 0.8; act 580 250 1.5   # worker: T-hall
act 701 377 1.0; act 156 150 0.8; act 790 340 1.5   # worker: move
act 701 408 1.0; act 156 150 0.8; act 880 340 1.0   # king: move
$H move 990 700
wait $REC
$H stop

magick -delay 18 -loop 0 "$OUT"/f*.png -layers Optimize docs/gameplay.gif
magick "$OUT/menu.png" -crop 800x600+0+0 +repage docs/options.png
ls -la docs/gameplay.gif docs/options.png
