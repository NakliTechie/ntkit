#!/bin/sh
# Render assets/social.png (GitHub's 1280×640 social card) from assets/social.html at 2x,
# then downsample so the type is crisp. Re-run after workflow.svg changes.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size=1280,640 \
  --screenshot="$tmp/2x.png" "file://$here/social.html" 2>/dev/null
sips -z 640 1280 "$tmp/2x.png" --out "$here/social.png" >/dev/null
sips -g pixelWidth -g pixelHeight "$here/social.png" | tail -2
ls -l "$here/social.png" | awk '{print "  " $5 " bytes"}'
