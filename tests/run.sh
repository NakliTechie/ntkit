#!/bin/sh
# Free, deterministic tests for the scripts ntkit ships and the checks its evals use.
# No model calls. Each tests/*.test.sh exits 0 pass, 1 fail, 77 skip (a missing tool).
# Usage: tests/run.sh [name-glob]      e.g. tests/run.sh 'bake-*'
set -u
here=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0; skip=0
for t in "$here"/${1:-*}.test.sh; do
  [ -f "$t" ] || continue
  name=$(basename "$t" .test.sh)
  log=$(sh "$t" 2>&1); rc=$?
  case $rc in
    0) echo "PASS  $name"; pass=$((pass + 1)) ;;
    77) echo "SKIP  $name  ($(printf '%s\n' "$log" | tail -1))"; skip=$((skip + 1)) ;;
    *) echo "FAIL  $name"; printf '%s\n' "$log" | sed 's/^/      /'; fail=$((fail + 1)) ;;
  esac
done
echo "$pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ]
