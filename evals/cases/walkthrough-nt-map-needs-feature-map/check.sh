#!/bin/sh
# Refusal: the reply names the missing map and the full walkthrough, and nothing changes.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
grep -qi 'verify/features' "$RESULT" || fail "the reply does not name verify/features/"
grep -Eqi 'full .*walkthrough|/walkthrough-nt( |`|$)' "$RESULT" || fail "the reply does not point at a full walkthrough"
[ -e verify ] && fail "a verify/ directory was created"
[ -z "$(git status --porcelain)" ] || fail "the working tree changed"
echo PASS
