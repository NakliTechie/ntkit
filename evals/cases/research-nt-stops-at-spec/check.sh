#!/bin/sh
# One run directory, a spec that passes check.py, State SPEC-READY, the go command in the reply,
# and nothing past the stop: no sections/, no draft, no report, no verify.json.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
set -- plan/research/*/
[ -d "$1" ] || fail "no run directory under plan/research/"
[ "$#" -eq 1 ] || fail "$# run directories; one call makes one"
run=${1%/}
[ -f "$run/run.md" ] || fail "no run.md"
state=$(sed -n 3p "$run/run.md")
[ "$state" = "State: SPEC-READY" ] || fail "run.md line 3 is '$state', not 'State: SPEC-READY'"
python3 .claude/skills/research-nt/bin/check.py spec "$run" || fail "spec.md fails check.py spec"
[ ! -e "$run/sections" ] || fail "sections/ exists: research started before approval"
for f in draft.md report.md verify.json; do
  [ ! -e "$run/$f" ] || fail "$f exists: the run went past the stop"
done
grep -Eq 'go [0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+' "$RESULT" || fail "the reply does not give the go command"
echo PASS
