#!/bin/sh
# Render a 1280x640 social card from social-card-template.html (same dir) at 2x, then
# downsample so the type is crisp. No npm deps: headless Chrome + sips (macOS). Set CHROME to
# the Chrome binary when it is not at the macOS default path.
#
# Usage:
#   render-social-card.sh --name "ntkit" --tagline "Software engineering for vibe coding." \
#     --facts '<b>21 slash commands</b> &nbsp;&#183;&nbsp; every repo &nbsp;&#183;&nbsp; MIT' \
#     --accent "#0891b2" --accent-text "#0e7490" --out ./assets/social.png
#
# --name and --tagline are plain text (escaped, so "R&D" or "<" print as typed).
# --facts takes literal HTML (so you control bolding/spacing directly) — put the one
# phrase worth emphasizing in <b>...</b>, separate clauses with " &nbsp;·&nbsp; ".
# --accent colours the brand bar (decoration, no contrast minimum). --accent-text colours
# the bold facts text and defaults to --accent.
# Contrast gate: before rendering, every text colour token in the template's :root
# (--ink, --muted, --accent-text) must reach 4.5:1 (WCAG AA) against --bg. A miss exits 1
# and prints the nearest passing shade of that colour; there is no override flag.
# Run this once for the repo's marketing/social.png and once for the app's own
# card at marketing/social-app.png, which the user ships into their static assets — same
# template, same look, two surfaces (see references/social-card-build.md).
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
import html as h, os, re, sys
src, dst = sys.argv[1], sys.argv[2]
for flag, key in (("--accent", "ACCENT"), ("--accent-text", "ACCENT_TEXT")):
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", os.environ[key]):
        sys.exit(f"{flag} must be a #rrggbb hex colour, got {os.environ[key]!r}")
vals = {k: os.environ[k] for k in ("FACTS", "ACCENT_TEXT", "ACCENT")}
vals.update({k: h.escape(os.environ[k]) for k in ("NAME", "TAGLINE")})  # plain text, not HTML
html = re.sub(r"__(NAME|TAGLINE|FACTS|ACCENT_TEXT|ACCENT)__", lambda m: vals[m.group(1)], open(src).read())

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

CHROME=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
[ -x "$CHROME" ] || { echo "Google Chrome not found at $CHROME; set CHROME to its binary" >&2; exit 1; }
command -v sips >/dev/null || { echo "sips not found: the downsample step needs macOS" >&2; exit 1; }
"$CHROME" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size=1280,640 \
  --screenshot="$tmp/2x.png" "file://$tmp/filled.html" 2>"$tmp/chrome.err" || true
[ -s "$tmp/2x.png" ] || { echo "Chrome wrote no screenshot:" >&2; tail -5 "$tmp/chrome.err" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
sips -z 640 1280 "$tmp/2x.png" --out "$OUT" >/dev/null
sips -g pixelWidth -g pixelHeight "$OUT" | tail -2
ls -l "$OUT" | awk '{print "  " $5 " bytes"}'
