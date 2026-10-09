#!/bin/sh
# List the session scratch /windup-nt must clean on exit. Changes nothing.
# Claude's session scratchpad (the path its system prompt names) holds intermediate files:
# captures, renders, clones, probe output. It is session-private, so windup clears it, by name.
# Prints one tab-separated line per top-level entry, largest first:
#   <class> <path> <KB> <detail>
# Classes:
#   drop  nothing open cites it: delete this entry by name.
#   keep  an open item ([ ] or [~]) in plan/pending.md or plan/workplan.md names it: keep for the next session.
#   older a scratchpad of an earlier session of the same project (a sibling under the same parent):
#         list it and ask; delete by name only when Chirag says so.
# Never prints, and windup never deletes, anything outside the given scratchpad or its sibling sessions.
# Usage: scratch.sh <scratchpad-dir> [plan-dir]
set -eu
sp=${1:?usage: scratch.sh <scratchpad-dir> [plan-dir]}
plan=${2:-plan}
[ -d "$sp" ] || { echo "no scratchpad: $sp" >&2; exit 2; }
open_items=$(cat "$plan/pending.md" "$plan/workplan.md" 2>/dev/null | grep -E '^[[:space:]]*- \[( |~)\]' || true)
for p in "$sp"/* "$sp"/.[!.]*; do
  [ -e "$p" ] || continue
  kb=$(du -sk "$p" | awk '{print $1}')
  name=$(basename "$p")
  cite=$(printf '%s\n' "$open_items" | grep -F -e "$name" | head -1 || true)
  if [ -n "$cite" ]; then
    printf 'keep\t%s\t%s\t%s\n' "$p" "$kb" "cited: $(printf '%s' "$cite" | sed 's/^[[:space:]]*//' | cut -c1-80)"
  else
    printf 'drop\t%s\t%s\t%s\n' "$p" "$kb" "no open item names $name"
  fi
done | sort -t"$(printf '\t')" -k3,3nr
# Earlier sessions of this project: <parent>/<other-session>/scratchpad
parent=$(dirname "$(dirname "$sp")"); me=$(basename "$(dirname "$sp")")
for s in "$parent"/*/scratchpad; do
  [ -d "$s" ] || continue
  [ "$(basename "$(dirname "$s")")" = "$me" ] && continue
  kb=$(du -sk "$s" | awk '{print $1}')
  [ "$kb" -gt 0 ] || continue
  printf 'older\t%s\t%s\t%s\n' "$s" "$kb" "earlier session of this project"
done
