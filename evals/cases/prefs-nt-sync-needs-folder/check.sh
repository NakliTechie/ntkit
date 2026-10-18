#!/bin/sh
# Sync with no folder stops and names init: ./prefs is not created, the project is untouched.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ -s "$RESULT" ] || fail "no final reply"
grep -Eqi 'init' "$RESULT" || fail "the reply does not point at /prefs-nt init"
[ ! -e prefs ] || fail "the preferences folder was created"
[ "$(git rev-parse HEAD)" = "$(cat "$META/head")" ] || fail "HEAD moved"
git diff --quiet && git diff --cached --quiet || fail "tracked files were modified or staged"
[ -z "$(git status --porcelain --untracked-files=all | grep -v '^?? \.claude/')" ] || fail "files were added"
echo PASS
