#!/bin/sh
# windup-nt/bin/scratch.sh lists scratchpad entries as drop or keep (named by an open item), and other
# sessions' scratchpads as older (idle over 24 hours) or recent (may be live).
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/windup-nt/bin/scratch.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
proj=$t/proj; sp=$proj/sess-now/scratchpad; old=$proj/sess-old/scratchpad; empty=$proj/sess-empty/scratchpad
mkdir -p "$sp/capture" "$sp/comp" "$sp/.hidden" "$old" "$empty" "$t/plan"
head -c 8192 /dev/zero >"$sp/capture/a.png"; head -c 4096 /dev/zero >"$sp/comp/index.html"; echo x >"$sp/probe.json"; echo y >"$sp/.hidden/h"
head -c 2048 /dev/zero >"$old/x"; find "$proj/sess-old" -exec touch -t 202001010000 {} +   # idle for years
live=$proj/sess-live/scratchpad; mkdir -p "$live"; echo z >"$live/render.log"            # written just now
paused=$proj/sess-paused/scratchpad; mkdir -p "$paused"; echo p >"$paused/p"   # scratch idle, transcript fresh
find "$proj/sess-paused" -exec touch -t 202001010000 {} +
mkdir -p "$t/transcripts/proj"; echo '{}' >"$t/transcripts/proj/sess-paused.jsonl"
echo '{}' >"$t/transcripts/proj/sess-old.jsonl"; touch -t 202001010000 "$t/transcripts/proj/sess-old.jsonl"
export NT_TRANSCRIPTS=$t/transcripts
printf '%s\n' '- [x] done item names probe.json' >"$t/plan/workplan.md"
printf '%s\n' '## Now' '- [~] re-cut the video from scratchpad comp/ tomorrow' >"$t/plan/pending.md"
out=$(sh "$script" "$sp" "$t/plan"); bad=0
expect() { printf '%s\n' "$out" | awk -F '\t' -v c="$1" -v p="$2" '$1 == c && $2 == p { f = 1 } END { exit !f }' || { echo "FAIL: expected $1 $2"; bad=1; }; }
expect drop "$sp/capture"
expect drop "$sp/probe.json"         # a closed item does not hold it
expect drop "$sp/.hidden"
expect keep "$sp/comp"               # an open item names it
expect older "$old"
expect recent "$live"                # a sibling written today may be a live session: never offered for deletion
expect recent "$paused"              # idle scratch but a fresh transcript: the session may resume
printf '%s\n' "$out" | grep -q "sess-empty" && { echo "FAIL: an empty earlier session is listed"; bad=1; }
# ext4 (Linux) reports 4 KB for an empty folder where APFS reports 0; an empty session stays unlisted there too.
mkdir "$t/bin"; realdu=$(command -v du)
printf '#!/bin/sh\n"%s" "$@" | awk '"'"'{ if ($1 < 4) $1 = 4; print }'"'"'\n' "$realdu" >"$t/bin/du"; chmod +x "$t/bin/du"
PATH="$t/bin:$PATH" sh "$script" "$sp" "$t/plan" | grep -q "sess-empty" && { echo "FAIL: an empty session is listed when du says 4 KB"; bad=1; }
printf '%s\n' "$out" | grep -q "sess-now/scratchpad	" && { echo "FAIL: current scratchpad listed as older"; bad=1; }
first=$(printf '%s\n' "$out" | head -1 | cut -f2); [ "$first" = "$sp/capture" ] || { echo "FAIL: largest entry not first ($first)"; bad=1; }
sh "$script" "$t/none" 2>/dev/null && { echo "FAIL: a missing scratchpad exits 0"; bad=1; }
[ "$bad" = 0 ] && echo "scratch: ok"
exit "$bad"
