#!/bin/sh
# Render assets/social.png (GitHub's 1280×640 social card) from assets/social.html at 2x,
# then downsample so the type is crisp. Re-run after workflow.svg changes.
# Contrast gate first: every `color:` in social.html must reach 4.5:1 (WCAG AA) on the page
# background, the same rule as package-nt's render-social-card.sh; a miss exits 1.
# Set CHROME to the Chrome binary when it is not at the macOS default path.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
python3 - "$here/social.html" <<'PY'
import re, sys
css = open(sys.argv[1]).read()
def lum(c):
    v = [int(c[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    v = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v]
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]
bg = re.search(r"body\s*\{[^}]*background:\s*(#[0-9a-fA-F]{6})", css).group(1)
bad = 0
for fg in sorted(set(re.findall(r"(?<![-\w])color:\s*(#[0-9a-fA-F]{6})", css))):
    hi, lo = sorted((lum(fg), lum(bg)), reverse=True)
    r = (hi + 0.05) / (lo + 0.05)
    if r < 4.5:
        bad = 1
        print(f"contrast: {fg} on {bg} is {r:.2f}:1, text needs 4.5:1", file=sys.stderr)
sys.exit(bad)
PY
CHROME=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
[ -x "$CHROME" ] || { echo "Google Chrome not found at $CHROME; set CHROME to its binary" >&2; exit 1; }
command -v sips >/dev/null || { echo "sips not found: the downsample step needs macOS" >&2; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$CHROME" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=2 --window-size=1280,640 \
  --screenshot="$tmp/2x.png" "file://$here/social.html" 2>"$tmp/chrome.err" || true
[ -s "$tmp/2x.png" ] || { echo "Chrome wrote no screenshot:" >&2; tail -5 "$tmp/chrome.err" >&2; exit 1; }
sips -z 640 1280 "$tmp/2x.png" --out "$here/social.png" >/dev/null
sips -g pixelWidth -g pixelHeight "$here/social.png" | tail -2
ls -l "$here/social.png" | awk '{print "  " $5 " bytes"}'
