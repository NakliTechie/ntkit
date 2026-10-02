#!/bin/sh
# The four planted structure findings carry IDs at their files; the injected payment
# gateway (a real seam: a production adapter plus a test adapter) is not Stray or Test
# value; and the pass stayed read-only.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
report=$(ls plan/forward-pass-*.md 2>/dev/null | head -1)
[ -n "$report" ] || fail "no plan/forward-pass-<date>.md"
# A line carrying a finding ID of class $1 (a token such as S3 or H1) and the path $2.
has() { grep -Eq "(^|[^A-Za-z0-9])$1[0-9]+([^0-9]|$).*$2" "$report"; }
has S 'src/billing\.js' || fail "legacyRounding (no caller) has no S finding at src/billing.js"
has S 'src/http\.js' || fail "the get() pass-through has no S finding at src/http.js"
has S 'src/store/' || fail "StoreFactory (one adapter) has no S finding under src/store/"
has '[CHM]' 'src/routes/export\.js' \
  || fail "the weaker copy of the invoice-read rule has no severity finding at src/routes/export.js"
! has '(S|T)' 'src/pay\.js' || fail "the injected payment gateway was flagged as Stray or Test value"
[ "$(git rev-parse HEAD)" = "$(cat "$META/head")" ] || fail "HEAD moved"
git diff --quiet && git diff --cached --quiet || fail "tracked files changed: forward-pass-nt is read-only"
echo PASS
