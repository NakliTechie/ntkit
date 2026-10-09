#!/bin/sh
# windup-nt/bin/review-media.sh lists run directories with media, done or open by the plan's open items.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/windup-nt/bin/review-media.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
p=$t/plan; mkdir -p "$p/ux-review-2026-10-01-run" "$p/ux-review-2026-10-09-codex-run/phone" "$p/walkthrough-2026-10-05-run" "$p/ux-review-2026-10-03-run"
head -c 4096 /dev/zero >"$p/ux-review-2026-10-01-run/journey.webm"; head -c 10 /dev/zero >"$p/ux-review-2026-10-01-run/001.png"
head -c 10 /dev/zero >"$p/ux-review-2026-10-09-codex-run/phone/Phone.webm"
head -c 10 /dev/zero >"$p/walkthrough-2026-10-05-run/a.png"
echo '{}' >"$p/ux-review-2026-10-03-run/beats.json"                       # no media: not listed
printf '%s\n' '# Workplan' '- [x] **H1** fixed (ux-review-2026-10-01)' '- [ ] **M1** phone exit [from: ux-review-2026-10-09]' >"$p/workplan.md"
printf '%s\n' '## Now' '- [~] walkthrough-2026-10-05 retest' >"$p/pending.md"
out=$(sh "$script" "$p"); bad=0
expect() { printf '%s\n' "$out" | awk -F '\t' -v c="$1" -v d="$p/$2" '$1 == c && $2 == d { f = 1 } END { exit !f }' || { echo "FAIL: expected $1 $2"; bad=1; }; }
expect done ux-review-2026-10-01-run
expect open ux-review-2026-10-09-codex-run
expect open walkthrough-2026-10-05-run
printf '%s\n' "$out" | grep -q 'ux-review-2026-10-03-run' && { echo "FAIL: a run without media is listed"; bad=1; }
printf '%s\n' "$out" | awk -F '\t' '$2 ~ /10-01-run$/ && $3 == 2 { f = 1 } END { exit !f }' || { echo "FAIL: file count"; bad=1; }
sh "$script" "$t/none" 2>/dev/null && { echo "FAIL: a missing plan dir exits 0"; bad=1; }
[ "$bad" = 0 ] && echo "review-media: ok"
exit "$bad"
