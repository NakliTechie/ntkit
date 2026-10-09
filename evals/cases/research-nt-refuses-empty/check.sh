#!/bin/sh
# No question: the reply shows the invocations, and nothing is written (not even plan/).
set -eu
fail() { echo "FAIL: $*"; exit 1; }
grep -Eqi 'go <[^>]*slug>|harnesses verify citations' "$RESULT" || fail "the reply does not show the usage"
[ ! -e plan ] || fail "plan/ exists: an empty call wrote something"
[ -z "$(git status --porcelain)" ] || fail "the working tree changed"
echo PASS
