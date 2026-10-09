#!/bin/sh
# windup-nt/bin/scratch.sh lists scratchpad entries as drop, keep (named by an open item) or older (earlier sessions).
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/windup-nt/bin/scratch.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
proj=$t/proj; sp=$proj/sess-now/scratchpad; old=$proj/sess-old/scratchpad; empty=$proj/sess-empty/scratchpad
mkdir -p "$sp/capture" "$sp/comp" "$sp/.hidden" "$old" "$empty" "$t/plan"
head -c 8192 /dev/zero >"$sp/capture/a.png"; head -c 4096 /dev/zero >"$sp/comp/index.html"; echo x >"$sp/probe.json"; echo y >"$sp/.hidden/h"
head -c 2048 /dev/zero >"$old/x"
printf '%s\n' '- [x] done item names probe.json' >"$t/plan/workplan.md"
printf '%s\n' '## Now' '- [~] re-cut the video from scratchpad comp/ tomorrow' >"$t/plan/pending.md"
out=$(sh "$script" "$sp" "$t/plan"); bad=0
expect() { printf '%s\n' "$out" | awk -F '\t' -v c="$1" -v p="$2" '$1 == c && $2 == p { f = 1 } END { exit !f }' || { echo "FAIL: expected $1 $2"; bad=1; }; }
expect drop "$sp/capture"
expect drop "$sp/probe.json"         # a closed item does not hold it
expect drop "$sp/.hidden"
expect keep "$sp/comp"               # an open item names it
expect older "$old"
printf '%s\n' "$out" | grep -q "sess-empty" && { echo "FAIL: an empty earlier session is listed"; bad=1; }
printf '%s\n' "$out" | grep -q "sess-now/scratchpad	" && { echo "FAIL: current scratchpad listed as older"; bad=1; }
first=$(printf '%s\n' "$out" | head -1 | cut -f2); [ "$first" = "$sp/capture" ] || { echo "FAIL: largest entry not first ($first)"; bad=1; }
sh "$script" "$t/none" 2>/dev/null && { echo "FAIL: a missing scratchpad exits 0"; bad=1; }
[ "$bad" = 0 ] && echo "scratch: ok"
exit "$bad"
