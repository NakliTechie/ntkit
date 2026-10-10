#!/bin/sh
# Refusal: the reply names tracelens and the remedy (install, or archive), and nothing is written.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
grep -qi 'tracelens' "$RESULT" || fail "the reply does not name tracelens"
grep -Eqi 'uv tool install|tracelens archive|no archive' "$RESULT" || fail "the reply gives no remedy"
ls plan/findings-*.md >/dev/null 2>&1 && fail "a findings file was written"
[ -z "$(git status --porcelain)" ] || fail "the working tree changed"
echo PASS
