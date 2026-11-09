#!/bin/sh
# guide-nt's statecheck.py: every reachable state checked, shortest broken path, guards switched off
# one at a time, and a bad model reported as exit 2 without a traceback. No network, no Java.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
check=$(cd "$(dirname "$0")/.." && pwd)/skills/guide-nt/bin/statecheck.py
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; cd "$tmp"
fail() { echo "FAIL: $*"; cat out 2>/dev/null; exit 1; }
rcof() { rc=0; python3 "$check" "$@" >out 2>&1 || rc=$?; echo "$rc"; }

# A refund: the customer ships the parcel back, the shop confirms, then pays. Rule: no money before
# the parcel is back. MONEY_GUARD=0 removes the guard on paying.
cat > refund.py <<'PY'
import os
GUARD = os.environ.get("MONEY_GUARD", "1") == "1"
def init():
    yield {"refund": "requested", "parcel": "with customer"}
def actions(s, g):
    if s["parcel"] == "with customer":
        yield "customer ships it back", {**s, "parcel": "in transit"}
    if s["parcel"] == "in transit":
        yield "shop receives it", {**s, "parcel": "back"}
    if s["refund"] == "requested" and (not GUARD or g("parcel is back", s["parcel"] == "back")):
        yield "shop pays", {**s, "refund": "paid"}
    if s["refund"] == "requested" and g("dead guard", True):
        yield "nothing", dict(s)
RULES = {"No money before the parcel is back":
         lambda s: s["refund"] != "paid" or s["parcel"] == "back"}
GUARDS = {"parcel is back": "No money before the parcel is back"}
PY

[ "$(rcof refund.py)" -eq 0 ] || fail "a holding model failed"
grep -q '^checked: 4 states, 3 steps, all 1 rules hold$' out || fail "wrong summary for the holding model"

[ "$(MONEY_GUARD=0 rcof refund.py)" -eq 1 ] || fail "a broken model passed"
grep -q '^BROKEN: No money before the parcel is back — after 1 step(s)' out || fail "broken path is not the shortest"
grep -q '1. shop pays' out || fail "broken path does not name the action"

[ "$(rcof refund.py --break-guards)" -eq 0 ] || fail "--break-guards changed the exit code"
grep -q 'without parcel is back: "No money before the parcel is back" breaks in 1 step(s)' out || fail "guard break not reported"
grep -q 'without dead guard: every rule still holds' out || fail "dead guard not reported"

[ "$(rcof refund.py --json)" -eq 0 ] || fail "--json failed"
python3 -c 'import json,sys; d=json.load(open("out")); assert d["states"]==4 and d["broken"] is None' || fail "--json output wrong"

[ "$(rcof refund.py --max-states 2)" -eq 1 ] || fail "the state limit did not fail the run"
grep -q 'stopped at the state limit (2)' out || fail "state limit not reported"

printf 'def init():\n    yield 1\ndef actions(s, g):\n    return []\nRULES = {"x": lambda s: True}\n' > bad.py
[ "$(rcof bad.py)" -eq 2 ] || fail "a non-dict state was not a model error"
grep -q 'bad model: TypeError' out || fail "bad model message missing"
! grep -q Traceback out || fail "bad model raised a traceback"
printf 'def init():\n    return iter(())\ndef actions(s, g):\n    return []\nRULES = {"x": lambda s: True}\n' > none.py
[ "$(rcof none.py)" -eq 2 ] || fail "a model with no starting state passed"
grep -q 'no starting state' out || fail "no-start message missing"
[ "$(rcof refund.py --max-states 0)" -eq 2 ] || fail "--max-states 0 was accepted"
# a guard whose removal opens an unbounded walk: the guard-off run hits the limit, so the run fails
cat > grow.py <<'PY'
def init():
    yield {"n": 0}
def actions(s, g):
    if g("cap", s["n"] < 3):
        yield "step", {"n": s["n"] + 1}
RULES = {"n stays small": lambda s: s["n"] < 1000}
PY
[ "$(rcof grow.py --break-guards --max-states 50)" -eq 1 ] || fail "a capped guard-off walk passed"
grep -q 'without cap: stopped at the state limit' out || fail "capped guard-off walk not reported"
printf 'x = 1\n' > empty.py
[ "$(rcof empty.py)" -eq 2 ] || fail "a model with no init was accepted"
echo "statecheck: ok"
