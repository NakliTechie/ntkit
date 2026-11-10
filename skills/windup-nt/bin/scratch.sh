#!/bin/sh
# List the session scratch /windup-nt must clean on exit. Changes nothing.
# The session scratchpad (the directory supplied by the caller) holds intermediate files:
# captures, renders, clones, probe output. It is session-private, so windup clears it, by name.
# Prints one tab-separated line per top-level entry, largest first:
#   <class> <path> <KB> <detail>
# Classes:
#   drop  nothing open cites it: delete this entry by name.
#   keep  an open item ([ ] or [~]) in plan/pending.md or plan/workplan.md names it: keep for the next session.
#   older  a scratchpad of another session of the same project (a sibling under the same parent),
#          with neither it nor that session's transcript written for NT_SCRATCH_IDLE_DAYS (default 7):
#          list it and ask; delete by name only when the user says so.
#   recent a sibling, or its session's transcript (<session-id>.jsonl under NT_TRANSCRIPTS, default
#          ~/.claude/projects), written within that time, or a sibling whose session id appears in a running
#          process's command line (a paused or resumed session): it may be live. List it; never delete.
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
# Other sessions of this project: <parent>/<other-session>/scratchpad
days=${NT_SCRATCH_IDLE_DAYS:-7}; idle=$((days * 1440))
parent=$(dirname "$(dirname "$sp")"); me=$(basename "$(dirname "$sp")")
for s in "$parent"/*/scratchpad; do
  [ -d "$s" ] || continue
  [ "$(basename "$(dirname "$s")")" = "$me" ] && continue
  [ -n "$(ls -A "$s")" ] || continue  # empty: du -sk says 0 on APFS but 4 on ext4, so ask ls
  kb=$(du -sk "$s" | awk '{print $1}')
  id=$(basename "$(dirname "$s")")
  tdir=${NT_TRANSCRIPTS:-$HOME/.claude/projects}
  if [ -n "$(find "$s" -mmin -"$idle" | head -1)" ]; then
    printf 'recent\t%s\t%s\t%s\n' "$s" "$kb" "another session wrote here in the last $days day(s); it may be live"
  elif [ -d "$tdir" ] && [ -n "$(find "$tdir" -name "$id.jsonl" -mmin -"$idle" 2>/dev/null | head -1)" ]; then
    printf 'recent\t%s\t%s\t%s\n' "$s" "$kb" "that session's transcript changed in the last $days day(s); it may be live"
  elif command -v pgrep >/dev/null 2>&1 && pgrep -f -- "$id" >/dev/null 2>&1; then
    printf 'recent\t%s\t%s\t%s\n' "$s" "$kb" "a running process names this session; it is live"
  else
    printf 'older\t%s\t%s\t%s\n' "$s" "$kb" "earlier session of this project, idle over $days day(s)"
  fi
done
