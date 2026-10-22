#!/bin/sh
# Meta mode refuses a skill with no references/: it says why, starts no campaign and edits nothing.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
grep -qi 'references' "$RESULT" || fail "the reply does not name the missing references/ folder"
[ -z "$(find . -name lab.json -not -path './.git/*' 2>/dev/null)" ] || fail "a campaign state file was written"
[ ! -e skills/notes-nt/references ] || fail "the loop created references/ itself"
[ -z "$(git status --porcelain -- skills README.md)" ] || fail "tracked files changed"
git branch --list 'lab/*' | grep -q . && fail "a lab branch was created"
echo PASS
