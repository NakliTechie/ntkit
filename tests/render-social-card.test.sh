#!/bin/sh
# The social card's contrast gate refuses text under 4.5:1 and names a passing shade.
set -eu
[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ] && command -v sips >/dev/null \
  || { echo "needs Google Chrome and sips (macOS)"; exit 77; }
render=$(cd "$(dirname "$0")/.." && pwd)/skills/package-nt/references/render-social-card.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }
args="--name Tally --tagline x --facts <b>MIT</b>"

# ntkit's own bright accent as text: 3.68:1, refused, with a suggestion that itself passes
if "$render" $args --accent '#0891b2' --out "$tmp/a.png" 2>"$tmp/err"; then fail "3.68:1 text passed the gate"; fi
grep -q '3.68:1' "$tmp/err" || fail "the refusal does not state the ratio: $(cat "$tmp/err")"
[ ! -e "$tmp/a.png" ] || fail "a refused card was still rendered"
shade=$(sed -n 's/.*nearest passing shade: \(#[0-9a-f]\{6\}\).*/\1/p' "$tmp/err")
[ -n "$shade" ] || fail "no suggested shade in: $(cat "$tmp/err")"
"$render" $args --accent '#0891b2' --accent-text "$shade" --out "$tmp/b.png" >/dev/null \
  || fail "the suggested shade $shade does not pass the gate"
[ "$(sips -g pixelWidth -g pixelHeight "$tmp/b.png" | awk '/pixel/ { printf "%s ", $2 }')" = "1280 640 " ] \
  || fail "the card is not 1280x640"

# the bar colour alone is decoration: a bright --accent with dark --accent-text passes
"$render" $args --accent '#ffd400' --accent-text '#1f2328' --out "$tmp/c.png" >/dev/null \
  || fail "a bright bar with dark text was refused"
# a non-hex colour is refused before rendering
if "$render" $args --accent teal --out "$tmp/d.png" 2>/dev/null; then fail "--accent teal was accepted"; fi
echo ok
