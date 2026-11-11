#!/bin/sh
# The reply is a triage table: alpha runnable, beta excluded for the hold, gamma excluded
# for the GPU. Nothing launched: no worktree, no autopilot branch, no new commit anywhere.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
line() { grep -i "$1" "$RESULT" | grep -i "$2" >/dev/null || fail "$3"; }
line alpha runnable "alpha is not marked runnable"
line beta 'hold' "beta is not excluded as on hold"
line gamma 'gpu\|hardware' "gamma is not excluded for the GPU"
grep -i beta "$RESULT" | grep -iv 'runnable' >/dev/null || fail "beta has no excluded line"
for r in alpha beta gamma; do
  [ -d "$r/.git" ] || fail "$r is gone"
  [ ! -e "$r/.worktrees" ] || fail "$r has a worktree: triage launched a run"
  [ -z "$(git -C "$r" branch --list 'autopilot/*')" ] || fail "$r has an autopilot branch"
  [ "$(git -C "$r" rev-list --count HEAD)" = 1 ] || fail "$r gained a commit"
  [ -z "$(git -C "$r" status --porcelain)" ] || fail "$r working tree changed"
done
echo PASS
