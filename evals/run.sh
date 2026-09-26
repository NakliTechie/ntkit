#!/bin/sh
# ntkit model evals. Each case builds a scratch project from a fixture, installs THIS
# checkout's skills into it, runs one prompt through headless `claude -p`, then runs a
# deterministic check.sh on what the run left behind. Costs model usage; the free
# script tests are tests/run.sh.
#
# Usage:  evals/run.sh [case-glob]          e.g.  evals/run.sh 'package-nt-*'
# Env:    NT_EVAL_MODEL       model alias for claude -p (default: opus)
#         NT_EVAL_CONFIG_DIR  the Claude config dir evals run under (default: ~/.ntkit-eval)
#         NT_EVAL_KEEP=1      keep passing cases' scratch dirs too (default: kept on fail only)
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
glob=${1:-*}; model=${NT_EVAL_MODEL:-opus}; cfg=${NT_EVAL_CONFIG_DIR:-$HOME/.ntkit-eval}

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
pass=0; fail=0
for case_dir in "$here"/cases/$glob; do
  [ -f "$case_dir/prompt" ] || continue
  name=$(basename "$case_dir")
  work=$(mktemp -d "${TMPDIR:-/tmp}/nt-eval-$name.XXXXXX"); meta=$(mktemp -d)
  if ! (cd "$work" && FIXTURES="$here/fixtures" META="$meta" sh "$case_dir/setup.sh") \
      >"$out/$name.setup.log" 2>&1; then
    echo "FAIL  $name  (setup; see $out/$name.setup.log)"; fail=$((fail + 1)); continue
  fi
  mkdir -p "$work/.claude/skills" && cp -R "$root"/skills/* "$work/.claude/skills/"
  # the harness's copy of the skills is not part of the project under test
  [ ! -d "$work/.git" ] || echo "/.claude/" >>"$work/.git/info/exclude"
  budget=$(cat "$case_dir/budget" 2>/dev/null || echo 5)
  secs=$(cat "$case_dir/timeout" 2>/dev/null || echo 1800)
  (cd "$work" && clean perl -e 'alarm shift @ARGV; exec @ARGV or die "exec: $!"' "$secs" \
    claude -p "$(cat "$case_dir/prompt")" --model "$model" --strict-mcp-config \
      --permission-mode bypassPermissions --output-format json --no-session-persistence \
      --max-budget-usd "$budget" --append-system-prompt "$NOTE") \
    >"$out/$name.json" 2>"$out/$name.stderr" || true
  cost=$(python3 - "$out/$name.json" "$out/$name.txt" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    d = {}
open(sys.argv[2], "w").write(d.get("result") or "")
print(f"${d.get('total_cost_usd', 0):.2f}")
PY
)
  if (cd "$work" && RESULT="$out/$name.txt" META="$meta" sh "$case_dir/check.sh") \
      >"$out/$name.check.log" 2>&1; then
    echo "PASS  $name  $cost"; pass=$((pass + 1))
    [ "${NT_EVAL_KEEP:-0}" = 1 ] || rm -rf "$work" "$meta"
  else
    echo "FAIL  $name  $cost  $(tail -1 "$out/$name.check.log")  (scratch kept: $work)"
    fail=$((fail + 1))
  fi
done
echo "$pass passed, $fail failed; logs in $out"
[ "$fail" -eq 0 ]
