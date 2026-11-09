#!/bin/sh
# windup-nt/bin/marketing.sh lists marketing/ files and brag-output*/ folders, drop or keep by the plan's open items.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/windup-nt/bin/marketing.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
cd "$t"; mkdir -p plan marketing brag-output-2026-10-09-101500/work
head -c 4096 /dev/zero >marketing/launch.mp4; head -c 10 /dev/zero >marketing/launch.jpg
head -c 10 /dev/zero >marketing/hero-x.png; head -c 10 /dev/zero >brag-output-2026-10-09-101500/work/f.png
mkdir marketing/proof-cut; : >marketing/proof-cut/.source; head -c 10 /dev/zero >marketing/proof-cut/take1.mov
echo log >brag-output.log                          # a file, not a render folder: never listed
printf '%s\n' '# Workplan' '- [x] **P1** old promo marketing/launch.mp4 shipped' >plan/workplan.md
printf '%s\n' '## Now' '- [~] re-cut marketing/hero-x.png for LinkedIn' >plan/pending.md
out=$(sh "$script" plan); bad=0
expect() { printf '%s\n' "$out" | awk -F '\t' -v c="$1" -v d="$2" '$1 == c && $2 == d { f = 1 } END { exit !f }' || { echo "FAIL: expected $1 $2"; bad=1; }; }
expect drop marketing/launch.mp4
expect drop marketing/launch.jpg
expect keep marketing/hero-x.png
expect drop brag-output-2026-10-09-101500
expect keep marketing/proof-cut                    # .source marker, cited by nothing
printf '%s\n' "$out" | grep -q 'brag-output.log' && { echo "FAIL: a brag-output file is listed"; bad=1; }
sh "$script" none 2>/dev/null && { echo "FAIL: a missing plan dir exits 0"; bad=1; }
rm -rf marketing brag-output*; [ -z "$(sh "$script" plan)" ] || { echo "FAIL: output with nothing to sweep"; bad=1; }
[ "$bad" = 0 ] && echo "marketing: ok"
exit "$bad"
