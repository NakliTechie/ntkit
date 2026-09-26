#!/bin/sh
# Render a 1280x640 social card from social-card-template.html (same dir) at 2x, then
# downsample so the type is crisp. No npm deps: headless Chrome + sips (macOS).
#
# Usage:
#   render-social-card.sh --name "ntkit" --tagline "The rigor layer for AI-assisted development." \
#     --facts '<b>21 slash commands</b> &nbsp;&#183;&nbsp; every repo &nbsp;&#183;&nbsp; MIT' \
#     --accent "#0891b2" --accent-text "#0e7490" --out ./assets/social.png
#
# --facts takes literal HTML (so you control bolding/spacing directly) — put the one
# phrase worth emphasizing in <b>...</b>, separate clauses with " &nbsp;·&nbsp; ".
# --accent colours the brand bar (decoration, no contrast minimum). --accent-text colours
# the bold facts text and defaults to --accent.
# Contrast gate: before rendering, every text colour token in the template's :root
# (--ink, --muted, --accent-text) must reach 4.5:1 (WCAG AA) against --bg. A miss exits 1
# and prints the nearest passing shade of that colour; there is no override flag.
# Run this once for the repo's marketing/social.png and once for the app's own
# public/social.png (or wherever it serves static assets) — same template, same look,
# two surfaces (see references/social-preview.md and README-DOCTRINE's "two surfaces" note).
set -eu
here=$(cd "$(dirname "$0")" && pwd)

NAME=""; TAGLINE=""; FACTS=""; ACCENT="#0891b2"; ACCENT_TEXT=""; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --tagline) TAGLINE="$2"; shift 2 ;;
    --facts) FACTS="$2"; shift 2 ;;
    --accent) ACCENT="$2"; shift 2 ;;
    --accent-text) ACCENT_TEXT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[ -n "$NAME" ] && [ -n "$TAGLINE" ] && [ -n "$OUT" ] || {
  echo "usage: $0 --name <name> --tagline <one line> --facts <html> --accent <#hex> [--accent-text <#hex>] --out <path.png>" >&2
  exit 1
}
[ -n "$ACCENT_TEXT" ] || ACCENT_TEXT=$ACCENT

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

NAME="$NAME" TAGLINE="$TAGLINE" FACTS="$FACTS" ACCENT="$ACCENT" ACCENT_TEXT="$ACCENT_TEXT" \
  python3 - "$here/social-card-template.html" "$tmp/filled.html" <<'PY'
import os, re, sys
src, dst = sys.argv[1], sys.argv[2]
for flag, key in (("--accent", "ACCENT"), ("--accent-text", "ACCENT_TEXT")):
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", os.environ[key]):
        sys.exit(f"{flag} must be a #rrggbb hex colour, got {os.environ[key]!r}")
html = open(src).read()
for key in ("NAME", "TAGLINE", "FACTS", "ACCENT_TEXT", "ACCENT"):
    html = html.replace(f"__{key}__", os.environ[key])

def lum(hexc):
    def ch(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (int(hexc[i:i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)

def ratio(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)

def nearest_pass(fg, bg):  # mix fg toward black (light bg) or white (dark bg) until it passes
    target = 0 if lum(bg) > 0.18 else 255
    r, g, b = (int(fg[i:i + 2], 16) for i in (1, 3, 5))
    for step in range(101):
        t = step / 100
        c = "#" + "".join(f"{round(v + (target - v) * t):02x}" for v in (r, g, b))
        if ratio(c, bg) >= 4.5:
            return c
    return None

root = re.search(r":root\s*\{([^}]*)\}", html)
tokens = dict(re.findall(r"--([a-z-]+):\s*(#[0-9a-fA-F]{6})", root.group(1) if root else ""))
missing = [t for t in ("bg", "ink", "muted", "accent-text") if t not in tokens]
if missing:
    sys.exit(f"template :root is missing colour tokens: {', '.join(missing)}")
bg, failed = tokens["bg"], False
for t in ("ink", "muted", "accent-text"):
    r = ratio(tokens[t], bg)
    if r < 4.5:
        failed = True
        print(f"contrast: --{t} {tokens[t]} on --bg {bg} is {r:.2f}:1, text needs 4.5:1; "
              f"nearest passing shade: {nearest_pass(tokens[t], bg)}", file=sys.stderr)
if failed:
    sys.exit(1)
open(dst, "w").write(html)
PY

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size=1280,640 \
  --screenshot="$tmp/2x.png" "file://$tmp/filled.html" 2>/dev/null

mkdir -p "$(dirname "$OUT")"
sips -z 640 1280 "$tmp/2x.png" --out "$OUT" >/dev/null
sips -g pixelWidth -g pixelHeight "$OUT" | tail -2
ls -l "$OUT" | awk '{print "  " $5 " bytes"}'
