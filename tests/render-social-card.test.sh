#!/bin/sh
# The social card's contrast gate refuses text under 4.5:1 and names a passing shade; card text is
# escaped; a missing Chrome is named; ntkit's own card (assets/social.html) passes the same gate.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
render=$root/skills/package-nt/references/render-social-card.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }
args="--name Tally --tagline x --facts <b>MIT</b>"

# No Chrome needed: a stub "Chrome" keeps the filled HTML and writes no screenshot.
printf '#!/bin/sh\nfor a; do case $a in file://*) cp "${a#file://}" "%s/captured.html" ;; esac; done\n' "$tmp" >"$tmp/chrome"
chmod +x "$tmp/chrome"
# --name and --tagline are text: "R&D" and "<" are escaped, --facts stays HTML
if CHROME=$tmp/chrome "$render" --name 'R&D' --tagline 'a <i>b' --facts '<b>MIT</b>' --accent '#0e7490' \
  --out "$tmp/e.png" 2>"$tmp/err"; then fail "a stub Chrome that wrote nothing still passed"; fi
grep -q 'Chrome wrote no screenshot' "$tmp/err" || fail "no screenshot went unreported: $(cat "$tmp/err")"
grep -q '<span>R&amp;D</span>' "$tmp/captured.html" || fail "--name was not escaped"
grep -q '<h1>a &lt;i&gt;b</h1>' "$tmp/captured.html" || fail "--tagline was not escaped"
grep -q '<b>MIT</b>' "$tmp/captured.html" || fail "--facts lost its HTML"
# a missing Chrome is named, not silent
if CHROME=$tmp/no-chrome "$render" $args --accent '#0e7490' --out "$tmp/f.png" 2>"$tmp/err"; then fail "a missing Chrome passed"; fi
grep -q 'Google Chrome not found' "$tmp/err" || fail "a missing Chrome was not named: $(cat "$tmp/err")"
# ntkit's own card passes the gate (it stops at the stub, before touching social.png) ...
CHROME=$tmp/chrome sh "$root/assets/render-social.sh" 2>"$tmp/err" && fail "the stub Chrome rendered a card"
grep -q 'contrast:' "$tmp/err" && fail "assets/social.html fails the contrast gate: $(cat "$tmp/err")"
grep -q 'Chrome wrote no screenshot' "$tmp/err" || fail "render-social.sh did not reach Chrome: $(cat "$tmp/err")"
# ... and the gate refuses the 3.68:1 accent it used to carry
mkdir "$tmp/assets"; cp "$root/assets/render-social.sh" "$tmp/assets/"
sed 's/#0e7490/#0891b2/g' "$root/assets/social.html" >"$tmp/assets/social.html"
CHROME=$tmp/chrome sh "$tmp/assets/render-social.sh" 2>"$tmp/err" && fail "render-social.sh accepted 3.68:1 text"
grep -q 'contrast: #0891b2 on #ffffff is 3.68:1' "$tmp/err" || fail "render-social.sh did not refuse 3.68:1: $(cat "$tmp/err")"

[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ] && command -v sips >/dev/null \
  || { echo "needs Google Chrome and sips (macOS)"; exit 77; }

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
