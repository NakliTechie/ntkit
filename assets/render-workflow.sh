#!/bin/sh
# Render assets/workflow.png (the README hero) from assets/workflow.svg at 2x,
# then downsample so the type is crisp. Re-run after workflow.svg changes, then
# re-run render-social.sh too — it crops from this same SVG.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
W=1600; H=990
cat > "$tmp/shot.html" <<EOF
<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;background:#fff}
img{display:block;width:${W}px;height:${H}px}
</style></head><body><img src="file://$here/workflow.svg"></body></html>
EOF
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size=${W},${H} \
  --screenshot="$tmp/2x.png" "file://$tmp/shot.html" 2>/dev/null
sips -z "$H" "$W" "$tmp/2x.png" --out "$here/workflow.png" >/dev/null
sips -g pixelWidth -g pixelHeight "$here/workflow.png" | tail -2
ls -l "$here/workflow.png" | awk '{print "  " $5 " bytes"}'
