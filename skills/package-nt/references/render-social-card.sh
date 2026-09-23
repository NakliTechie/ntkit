#!/bin/sh
# Render a 1280x640 social card from social-card-template.html (same dir) at 2x, then
# downsample so the type is crisp. No npm deps: headless Chrome + sips (macOS).
#
# Usage:
#   render-social-card.sh --name "ntkit" --tagline "The rigor layer for AI-assisted development." \
#     --facts '<b>23 slash commands</b> &nbsp;\xc2\xb7&nbsp; every repo &nbsp;\xc2\xb7&nbsp; MIT' \
#     --accent "#0891b2" --out ./assets/social.png
#
# --facts takes literal HTML (so you control bolding/spacing directly) — put the one
# phrase worth emphasizing in <b>...</b>, separate clauses with " &nbsp;·&nbsp; ".
# Run this once for the repo's marketing/social.png and once for the app's own
# public/social.png (or wherever it serves static assets) — same template, same look,
# two surfaces (see references/social-preview.md and README-DOCTRINE's "two surfaces" note).
set -eu
here=$(cd "$(dirname "$0")" && pwd)

NAME=""; TAGLINE=""; FACTS=""; ACCENT="#0891b2"; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --tagline) TAGLINE="$2"; shift 2 ;;
    --facts) FACTS="$2"; shift 2 ;;
    --accent) ACCENT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[ -n "$NAME" ] && [ -n "$TAGLINE" ] && [ -n "$OUT" ] || {
  echo "usage: $0 --name <name> --tagline <one line> --facts <html> --accent <#hex> --out <path.png>" >&2
  exit 1
}

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

NAME="$NAME" TAGLINE="$TAGLINE" FACTS="$FACTS" ACCENT="$ACCENT" python3 - "$here/social-card-template.html" "$tmp/filled.html" <<'PY'
import os, sys
src, dst = sys.argv[1], sys.argv[2]
html = open(src).read()
html = html.replace("__NAME__", os.environ["NAME"])
html = html.replace("__TAGLINE__", os.environ["TAGLINE"])
html = html.replace("__FACTS__", os.environ["FACTS"])
html = html.replace("__ACCENT__", os.environ["ACCENT"])
open(dst, "w").write(html)
PY

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size=1280,640 \
  --screenshot="$tmp/2x.png" "file://$tmp/filled.html" 2>/dev/null

mkdir -p "$(dirname "$OUT")"
sips -z 640 1280 "$tmp/2x.png" --out "$OUT" >/dev/null
sips -g pixelWidth -g pixelHeight "$OUT" | tail -2
ls -l "$OUT" | awk '{print "  " $5 " bytes"}'
