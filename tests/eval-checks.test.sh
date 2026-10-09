#!/bin/sh
# Every eval case's check.sh must fail on a project where the skill never ran: a check
# that passes untouched proves nothing. Builds each case's setup only; no model call.
set -eu
evals=$(cd "$(dirname "$0")/.." && pwd)/evals
bad=0
for c in "$evals"/cases/*/; do
  name=$(basename "$c"); work=$(mktemp -d); meta=$(mktemp -d); : >"$meta/empty-result"
  (cd "$work" && FIXTURES="$evals/fixtures" META="$meta" sh "$c/setup.sh") >/dev/null 2>&1 \
    || { echo "FAIL: $name setup.sh failed"; bad=1; continue; }
  if (cd "$work" && RESULT="$meta/empty-result" META="$meta" sh "$c/check.sh") >/dev/null 2>&1; then
    echo "FAIL: $name check.sh passes on a project the skill never touched"; bad=1
  fi
  rm -rf "$work" "$meta"
done
[ "$bad" -eq 0 ] && echo ok
