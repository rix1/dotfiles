#!/bin/sh
# render.sh <file.html> <out.png> [width] [height]
# Renders an HTML/SVG page to a 2x PNG with headless Chrome.
set -e
html=$1; out=$2; w=${3:-1600}; h=${4:-1000}
case "$html" in /*) ;; *) html="$PWD/$html" ;; esac
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size="$w,$h" \
  --screenshot="$out" "file://$html" >/dev/null 2>&1
test -s "$out"
