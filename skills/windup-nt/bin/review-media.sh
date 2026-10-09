#!/bin/sh
# List the media that review runs left in plan/ for /windup-nt's media sweep. Changes nothing.
# A review (/ux-review-nt, /walkthrough-nt) keeps its recordings and screenshots in
# plan/<report>-run/ while its findings are open; the report, beat logs and JSON are the record.
# Prints one tab-separated line per run directory that still holds media, oldest name first:
#   <class> <dir> <files> <KB> <detail>
# Classes:
#   done  no open item in plan/pending.md or plan/workplan.md cites the report: delete the media.
#   open  an open item ([ ] or [~]) cites it, by the report's name or its date key
#         (ux-review-2026-10-09 for ux-review-2026-10-09-codex): keep the media for the fixer.
# Media: *.webm *.mp4 *.mov *.cast *.png *.jpg *.jpeg *.gif
# Usage: review-media.sh [plan-dir]
set -eu
plan=${1:-plan}
[ -d "$plan" ] || { echo "no plan directory: $plan" >&2; exit 2; }
open_items=$(cat "$plan/pending.md" "$plan/workplan.md" 2>/dev/null | grep -E '^[[:space:]]*- \[( |~)\]' || true)
for d in "$plan"/*-run; do
  [ -d "$d" ] || continue
  files=$(find "$d" -type f \( -name '*.webm' -o -name '*.mp4' -o -name '*.mov' -o -name '*.cast' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' \) | wc -l | tr -d ' ')
  [ "$files" -gt 0 ] || continue
  kb=$(find "$d" -type f \( -name '*.webm' -o -name '*.mp4' -o -name '*.mov' -o -name '*.cast' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' \) -exec du -k {} + | awk '{s += $1} END {print s + 0}')
  stem=$(basename "$d"); stem=${stem%-run}
  key=$(printf '%s' "$stem" | sed -E 's/^(.*[0-9]{4}-[0-9]{2}-[0-9]{2}[a-z]?).*/\1/')
  cite=$(printf '%s\n' "$open_items" | grep -F -e "$stem" -e "$key" | head -1 || true)
  if [ -n "$cite" ]; then
    printf 'open\t%s\t%s\t%s\t%s\n' "$d" "$files" "$kb" "cited: $(printf '%s' "$cite" | sed 's/^[[:space:]]*//' | cut -c1-80)"
  else
    printf 'done\t%s\t%s\t%s\t%s\n' "$d" "$files" "$kb" "no open item cites $stem"
  fi
done
