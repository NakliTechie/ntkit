#!/bin/sh
# init on an existing folder stops and says so: every file in ./prefs is unchanged, none added.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ -s "$RESULT" ] || fail "no final reply"
grep -Eqi 'already|exists' "$RESULT" || fail "the reply does not say the folder already exists"
[ "$(cd prefs && find . -type f | sort | xargs shasum)" = "$(cat "$META/prefs.sums")" ] || fail "./prefs changed"
[ "$(git rev-parse HEAD)" = "$(cat "$META/head")" ] || fail "HEAD moved"
git diff --quiet && git diff --cached --quiet || fail "tracked files were modified or staged"
echo PASS
