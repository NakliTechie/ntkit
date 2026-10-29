#!/bin/sh
# evals/run.sh --runs/--without: argument checks and the cost ceiling (via --dry-run, no
# model call), and evals/summary.py's pass rates, flips and per-arm means.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
run=$root/evals/run.sh; summary=$root/evals/summary.py
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
bad=0
case1=$(basename "$(ls -d "$root"/evals/cases/*/ | head -1)")
some=$(cd "$root" && ls skills/*/SKILL.md | head -1)

refuses() { if sh "$run" "$@" >"$t/o" 2>&1; then echo "FAIL: accepted: $*"; bad=1; fi; }
refuses --dry-run --runs 0 "$case1"
refuses --dry-run --runs x "$case1"
refuses --dry-run --without SUBSTANCE.md "$case1"          # outside skills/: never installed
refuses --dry-run --without skills/no-such-file.md "$case1"
refuses --dry-run --without skills/../README.md "$case1"
refuses --dry-run 'no-such-case-*'
printf 'not a patch\n' >"$t/bad.patch"
refuses --dry-run --without "$t/bad.patch" "$case1"
NT_EVAL_MAX_USD=1; export NT_EVAL_MAX_USD
refuses --dry-run --runs 3 --without "$some" "$case1"   # ceiling over $1
grep -q "refusing: ceiling" "$t/o" || { echo "FAIL: no ceiling refusal message"; bad=1; }
NT_EVAL_MAX_USD=1000

out=$(sh "$run" --dry-run --runs 3 --without "$some" "$case1")
printf '%s\n' "$out" | grep -q "1 case(s) x 3 run(s) x 2 arm(s)" || { echo "FAIL: plan line: $out"; bad=1; }
printf '%s\n' "$out" | grep -q "arm B: delete $some" || { echo "FAIL: arm B line: $out"; bad=1; }

# a patch made the way git writes one applies, and dry-run names it
cp "$root/$some" "$t/edited"; echo "extra line" >>"$t/edited"
diff -u "$root/$some" "$t/edited" | sed "1s|.*|--- a/$some|; 2s|.*|+++ b/$some|" >"$t/ok.patch" || true
out=$(sh "$run" --dry-run --without "$t/ok.patch" "$case1") || { echo "FAIL: valid patch refused"; bad=1; }
printf '%s\n' "$out" | grep -q "arm B: patch" || { echo "FAIL: patch arm line: $out"; bad=1; }

tab=$(printf '\t')
{
  printf 'case\tarm\trun\tpass\tcost\tturns\tin\tout\tcache_read\tcache_write\tms\n'
  printf 'c1\tA\t1\t1\t0.10\t4\t100\t50\t1000\t10\t2000\n'
  printf 'c1\tA\t2\t1\t0.10\t4\t100\t50\t1000\t10\t2000\n'
  printf 'c1\tB\t1\t0\t0.20\t8\t200\t70\t2000\t20\t4000\n'
  printf 'c1\tB\t2\t1\t0.20\t8\t200\t70\t2000\t20\t4000\n'
  printf 'c2\tA\t1\t0\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c2\tA\t2\t0\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c2\tB\t1\t1\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c2\tB\t2\t0\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c3\tA\t1\t1\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c3\tA\t2\t1\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c3\tB\t1\t1\t0.10\t2\t10\t5\t0\t0\t1000\n'
  printf 'c3\tB\t2\t1\t0.10\t2\t10\t5\t0\t0\t1000\n'
} >"$t/runs.tsv"
s=$(python3 "$summary" "$t/runs.tsv")
has() { printf '%s\n' "$s" | grep -qF -- "$1" || { echo "FAIL: summary lacks: $1"; bad=1; }; }
has "c1: 2/2  1/2"
has "c2: 0/2  1/2"
has "flipped: 1 case(s) pass less in arm B, 1 pass more"
has "worse in B: c1"
has "better in B: c2"
printf '%s\n' "$s" | grep -q "in B: c3" && { echo "FAIL: unchanged case listed as flipped"; bad=1; }
has "A  4/6  2.7  40  20  333  3  1.3  \$0.10"
has "B  4/6  4.0  73  27  667  7  2.0  \$0.13"
python3 "$summary" 2>/dev/null && { echo "FAIL: summary without args exits 0"; bad=1; }

[ "$bad" = 0 ] && echo "eval-ab: ok"
exit "$bad"
