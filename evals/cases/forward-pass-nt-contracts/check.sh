#!/bin/sh
# Both contract bugs carry severity IDs at their files, the duration finding cites the
# README contract, the banker's-rounding bait is not a finding, the coverage map uses
# the contract-checked mark, and the pass stayed read-only.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
report=$(ls plan/forward-pass-*.md 2>/dev/null | head -1)
[ -n "$report" ] || fail "no plan/forward-pass-<date>.md"
# A line carrying a finding ID of class $1 (a token such as H1) and the path $2.
has() { grep -Eq "(^|[^A-Za-z0-9])$1[0-9]+([^0-9]|$).*$2" "$report"; }
has '[CHM]' 'src/money\.js' || fail "splitEvenly (shares do not sum) has no severity finding at src/money.js"
has '[CHM]' 'src/duration\.js' || fail "parseDuration (1h = 60) has no severity finding at src/duration.js"
grep -Eq 'README\.md:[0-9]+' "$report" || fail "no finding cites the README.md contract by path:line"
! has '[CHML]' 'src/round\.js' || fail "the documented banker's rounding was flagged as a bug"
grep -qi 'contract-checked' "$report" || fail "the coverage map has no contract-checked mark"
[ "$(git rev-parse HEAD)" = "$(cat "$META/head")" ] || fail "HEAD moved"
git diff --quiet && git diff --cached --quiet || fail "tracked files changed: forward-pass-nt is read-only"
echo PASS
