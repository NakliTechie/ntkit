#!/bin/sh
# Exactly one dated line, newest first under ## Decisions; nothing else touched, nothing committed.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ -f plan/history.md ] || fail "plan/history.md is gone"
d=$(diff "$META/history.before" plan/history.md || true)
added=$(printf '%s\n' "$d" | grep -c '^> ' || true)
removed=$(printf '%s\n' "$d" | grep -c '^< ' || true)
[ "$added" -eq 1 ] || fail "expected 1 added line, got $added"
[ "$removed" -eq 0 ] || fail "expected 0 removed lines, got $removed"
line=$(printf '%s\n' "$d" | sed -n 's/^> //p')
printf '%s\n' "$line" | grep -Eq "^- $(date +%Y-%m-%d) .*CSV" || fail "added line is not '- <today> <decision>': $line"
first=$(awk '/^## Decisions/ { f = 1; next } f && /^- / { print; exit }' plan/history.md)
printf '%s\n' "$first" | grep -q CSV || fail "the new decision is not first under ## Decisions"
[ "$(git rev-list --count HEAD)" -eq 1 ] || fail "a commit was made"
git diff --quiet HEAD || fail "a tracked file changed"
echo PASS
