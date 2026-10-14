#!/bin/sh
# List the promo output /windup-nt's marketing sweep must clean. Changes nothing.
# /package-nt writes heroes, cards and launch videos to marketing/ and leaves brag-output*/ behind
# when a render fails. These are local and regenerable (gitignored), so windup clears them, by name.
# One exception: a proof video (playbook skills/package-nt/references/proof-video.md) holds live recordings of
# the app that cannot be made again. Its folder carries a .source marker, and a marked folder is always
# kept, cited or not, so an uncited proof folder is never silently deleted.
# Prints one tab-separated line per file in marketing/ and per brag-output*/ folder, largest first:
#   <class> <path> <KB> <detail>
# Classes:
#   drop  nothing open cites it and it holds no .source marker: delete this entry by name.
#   keep  an open item ([ ] or [~]) in plan/pending.md or plan/workplan.md names it (by file name or
#         stem), or it is a folder holding a .source marker (irreplaceable recordings, not regenerable).
# Usage: marketing.sh [plan-dir]     (run from the repo root)
set -eu
plan=${1:-plan}
[ -d "$plan" ] || { echo "no plan directory: $plan" >&2; exit 2; }
open_items=$(cat "$plan/pending.md" "$plan/workplan.md" 2>/dev/null | grep -E '^[[:space:]]*- \[( |~)\]' || true)
for p in marketing/* brag-output*; do
  [ -e "$p" ] || continue
  kb=$(du -sk "$p" | awk '{print $1}')
  name=$(basename "$p"); stem=${name%.*}
  cite=$(printf '%s\n' "$open_items" | grep -F -e "$name" -e "$p" | head -1 || true)
  [ -n "$cite" ] || [ -d "$p" ] || cite=$(printf '%s\n' "$open_items" | grep -F -e "marketing/$stem" | head -1 || true)
  if [ -d "$p" ] && [ -e "$p/.source" ]; then
    printf 'keep\t%s\t%s\t%s\n' "$p" "$kb" "irreplaceable: .source marker (live recordings, not regenerable)"
  elif [ -n "$cite" ]; then
    printf 'keep\t%s\t%s\t%s\n' "$p" "$kb" "cited: $(printf '%s' "$cite" | sed 's/^[[:space:]]*//' | cut -c1-80)"
  else
    printf 'drop\t%s\t%s\t%s\n' "$p" "$kb" "no open item names $name"
  fi
done | sort -t"$(printf '\t')" -k3,3nr
