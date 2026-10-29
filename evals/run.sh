#!/bin/sh
# ntkit model evals. Each case builds a scratch project from a fixture, installs THIS
# checkout's skills into it, runs one prompt through headless `claude -p`, then runs a
# deterministic check.sh on what the run left behind. Costs model usage; the free
# script tests are tests/run.sh.
#
# Usage:  evals/run.sh [--runs N] [--without PATH] [--dry-run] [case-glob]
#   evals/run.sh 'package-nt-*'                       one run per case
#   evals/run.sh --runs 3 'research-nt-*'             three runs per case, pass rate each
#   evals/run.sh --runs 5 --without skills/x/references/y.md 'x-*'
#   evals/run.sh --runs 5 --without rule-off.patch 'x-*'
# --without runs each case N times as checked out (arm A) and N times with one change
# (arm B): a file or folder under skills/ deleted from the installed copy, or a .patch /
# .diff (paths like skills/..., as `git diff` writes them) applied to it. The report
# compares pass rates, flipped cases, turns, tokens, time and cost; it answers "does this
# rule change behaviour?", so it exits 0 whatever the pass rates. --dry-run prints the
# plan and the cost ceiling, then stops before any model call.
# Env:    NT_EVAL_MODEL       model alias for claude -p (default: opus)
#         NT_EVAL_CONFIG_DIR  the Claude config dir evals run under (default: ~/.ntkit-eval)
#         NT_EVAL_KEEP=1      keep passing cases' scratch dirs too (default: kept on fail only)
#         NT_EVAL_MAX_USD     refuse a run whose ceiling (runs x arms x each case's budget)
#                             exceeds this (default 25)
#
# Why a separate config dir: user-level skills in ~/.claude/skills load in every run,
# --setting-sources included, and beat a project skill of the same name. An installed
# copy would shadow the checkout under test. The eval dir has no skills, no CLAUDE.md,
# no hooks, so each run sees only the scratch project's .claude/skills. Log it in once:
#   CLAUDE_CONFIG_DIR=~/.ntkit-eval claude auth login
#
# A case is evals/cases/<name>/ with:
#   prompt    the one prompt, usually a slash command
#   setup.sh  builds the scratch project in the current dir ($FIXTURES, $META available)
#   check.sh  exit 0 = pass; runs in the scratch dir ($RESULT = final reply text, $META)
#   budget    optional USD cap for the run (default 5)
#   timeout   optional seconds (default 1800)
set -eu
here=$(cd "$(dirname "$0")" && pwd); root=$(dirname "$here")
runs=1; without=""; dry=0
while [ $# -gt 0 ]; do
  case $1 in
    --runs) runs=${2:?--runs needs a number}; shift 2 ;;
    --without) without=${2:?--without needs a path}; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
case $runs in ''|*[!0-9]*|0) echo "--runs must be a positive integer" >&2; exit 2 ;; esac
glob=${1:-*}; model=${NT_EVAL_MODEL:-opus}; cfg=${NT_EVAL_CONFIG_DIR:-$HOME/.ntkit-eval}
max_usd=${NT_EVAL_MAX_USD:-25}

# Arm B's change, checked before anything runs.
kind=""; change=""
if [ -n "$without" ]; then
  case $without in
    *.patch|*.diff)
      [ -f "$without" ] || { echo "--without: no such patch: $without" >&2; exit 2; }
      change=$(cd "$(dirname "$without")" && pwd)/$(basename "$without"); kind=patch
      t=$(mktemp -d); cp -R "$root/skills" "$t/skills"
      (cd "$t" && patch -p1 --silent --dry-run <"$change") >/dev/null 2>&1 || {
        rm -rf "$t"; echo "--without: $without does not apply to skills/ in this checkout" >&2; exit 2; }
      rm -rf "$t" ;;
    skills/?*)
      case $without in *..*) echo "--without: path may not contain .." >&2; exit 2 ;; esac
      [ -e "$root/$without" ] || { echo "--without: no such path in this checkout: $without" >&2; exit 2; }
      change=${without%/}; kind=delete ;;
    *) echo "--without takes a path under skills/ or a .patch/.diff file: $without" >&2; exit 2 ;;
  esac
fi
if [ -n "$kind" ]; then arms="A B"; else arms="A"; fi

# Cost ceiling: every run can spend up to its case's budget.
ncase=0; ceiling=0
for case_dir in "$here"/cases/$glob; do
  [ -f "$case_dir/prompt" ] || continue
  b=$(cat "$case_dir/budget" 2>/dev/null || echo 5)
  ncase=$((ncase + 1)); ceiling=$(awk -v c="$ceiling" -v b="$b" 'BEGIN{print c + b}')
done
[ "$ncase" -gt 0 ] || { echo "no case matches: $glob" >&2; exit 2; }
narms=$(echo $arms | wc -w | tr -d ' ')
ceiling=$(awk -v c="$ceiling" -v r="$runs" -v a="$narms" 'BEGIN{printf "%.2f", c * r * a}')
echo "plan: $ncase case(s) x $runs run(s) x $narms arm(s); ceiling \$$ceiling (limit \$$max_usd)"
[ -z "$kind" ] || echo "arm B: $kind $without"
if awk -v c="$ceiling" -v m="$max_usd" 'BEGIN{exit !(c > m)}'; then
  echo "refusing: ceiling \$$ceiling is over NT_EVAL_MAX_USD=\$$max_usd; raise it to run" >&2; exit 2
fi
[ "$dry" -eq 0 ] || exit 0

# A clean environment: no parent Claude session's variables (they break auth when this
# runs inside a Claude Code session) and no NT_PLAN_STORE (it would put the scratch
# project's plan/ into the real plan store).
clean() { env -i HOME="$HOME" USER="${USER:-}" LOGNAME="${LOGNAME:-}" PATH="$PATH" \
  LANG="${LANG:-en_US.UTF-8}" TMPDIR="${TMPDIR:-/tmp}" TERM=dumb CLAUDE_CONFIG_DIR="$cfg" "$@"; }

command -v claude >/dev/null || { echo "claude CLI not on PATH" >&2; exit 2; }
clean claude auth status 2>/dev/null | grep -q '"loggedIn": true' || {
  echo "no login for $cfg; run once in a terminal: CLAUDE_CONFIG_DIR=$cfg claude auth login" >&2; exit 2; }

NOTE="This is an automated ntkit eval. The working directory is a disposable scratch \
project. Stay inside it: read and write nothing outside it, push nothing, and contact no \
network host except localhost. No person is present, so ask no questions: where a skill \
offers a default, take it."

stamp=$(date +%Y%m%d-%H%M%S); out="$here/results/$stamp"; mkdir -p "$out"
tsv="$out/runs.tsv"; printf 'case\tarm\trun\tpass\tcost\tturns\tin\tout\tcache_read\tcache_write\tms\n' >"$tsv"
pass=0; fail=0
for case_dir in "$here"/cases/$glob; do
  [ -f "$case_dir/prompt" ] || continue
  name=$(basename "$case_dir")
  budget=$(cat "$case_dir/budget" 2>/dev/null || echo 5)
  secs=$(cat "$case_dir/timeout" 2>/dev/null || echo 1800)
  for arm in $arms; do
    i=1
    while [ "$i" -le "$runs" ]; do
      # one run keeps the plain log names; repeated or A/B runs get arm and index
      if [ "$runs" -eq 1 ] && [ "$arm" = A ] && [ -z "$kind" ]; then tag=$name; else tag=$name.$arm$i; fi
      work=$(mktemp -d "${TMPDIR:-/tmp}/nt-eval-$name.XXXXXX"); meta=$(mktemp -d)
      if ! (cd "$work" && FIXTURES="$here/fixtures" META="$meta" sh "$case_dir/setup.sh") \
          >"$out/$tag.setup.log" 2>&1; then
        echo "FAIL  $tag  (setup; see $out/$tag.setup.log)"; fail=$((fail + 1))
        printf '%s\t%s\t%s\t0\t0\t0\t0\t0\t0\t0\t0\n' "$name" "$arm" "$i" >>"$tsv"
        rm -rf "$work" "$meta"; i=$((i + 1)); continue
      fi
      mkdir -p "$work/.claude/skills" && cp -R "$root"/skills/* "$work/.claude/skills/"
      if [ "$arm" = B ]; then
        case $kind in
          delete) rm -rf "$work/.claude/${change}" ;;
          patch) (cd "$work/.claude" && patch -p1 --silent <"$change") ;;
        esac
      fi
      # the harness's copy of the skills is not part of the project under test
      [ ! -d "$work/.git" ] || echo "/.claude/" >>"$work/.git/info/exclude"
      (cd "$work" && clean perl -e 'alarm shift @ARGV; exec @ARGV or die "exec: $!"' "$secs" \
        claude -p "$(cat "$case_dir/prompt")" --model "$model" --strict-mcp-config \
          --permission-mode bypassPermissions --output-format json --no-session-persistence \
          --max-budget-usd "$budget" --append-system-prompt "$NOTE") \
        >"$out/$tag.json" 2>"$out/$tag.stderr" || true
      stats=$(python3 - "$out/$tag.json" "$out/$tag.txt" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    d = {}
open(sys.argv[2], "w").write(d.get("result") or "")
u = d.get("usage") or {}
print("\t".join(str(x) for x in (
    f"{d.get('total_cost_usd', 0):.4f}", d.get("num_turns", 0), u.get("input_tokens", 0),
    u.get("output_tokens", 0), u.get("cache_read_input_tokens", 0),
    u.get("cache_creation_input_tokens", 0), d.get("duration_ms", 0))))
PY
)
      cost=$(printf '%s' "$stats" | awk -F'\t' '{printf "$%.2f", $1}')
      if (cd "$work" && RESULT="$out/$tag.txt" META="$meta" sh "$case_dir/check.sh") \
          >"$out/$tag.check.log" 2>&1; then
        echo "PASS  $tag  $cost"; pass=$((pass + 1)); ok=1
        [ "${NT_EVAL_KEEP:-0}" = 1 ] || rm -rf "$work" "$meta"
      else
        echo "FAIL  $tag  $cost  $(tail -1 "$out/$tag.check.log")  (scratch kept: $work)"
        fail=$((fail + 1)); ok=0
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$arm" "$i" "$ok" "$stats" >>"$tsv"
      i=$((i + 1))
    done
  done
done
echo "$pass passed, $fail failed; logs in $out"
if [ -n "$kind" ] || [ "$runs" -gt 1 ]; then
  python3 "$here/summary.py" "$tsv" | tee "$out/summary.txt"
fi
# A/B mode measures; it never gates. Plain and repeated runs fail on any failed run.
[ -n "$kind" ] || [ "$fail" -eq 0 ]
