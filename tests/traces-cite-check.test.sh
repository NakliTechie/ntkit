#!/bin/sh
# traces-nt cite_check.py against a synthetic tracelens archive: a clean findings file, a missing
# file, a line past the end, a finding with no pointer, a bad fix-target type, a missing Measure
# line, an empty file, and a missing archive. No model calls.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
CC=$(cd "$(dirname "$0")/.." && pwd)/skills/traces-nt/bin/cite_check.py
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
bad=0
expect() { # expect <description> <exit code> <substring> <findings file> [extra args]
  desc=$1; want_rc=$2; want=$3; file=$4; shift 4
  set +e; out=$(TRACELENS_HOME="$work/home" python3 "$CC" "$file" "$@" 2>&1); rc=$?; set -e
  if [ "$rc" -ne "$want_rc" ]; then
    echo "FAIL $desc: exit $rc, wanted $want_rc"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1; return
  fi
  case $out in *"$want"*) : ;; *)
    echo "FAIL $desc: output lacks '$want'"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1 ;;
  esac
}

mkdir -p "$work/home/archive/claude/-tmp-x" "$work/home/archive/codex/2026/01/05"
seq 1 30 | sed 's/^/{"n":&}/' >"$work/home/archive/claude/-tmp-x/s1.jsonl"
seq 1 10 | sed 's/^/{"n":&}/' >"$work/home/archive/codex/2026/01/05/r1.jsonl"

finding() { # finding <n> <evidence> <fix type> [measure]
  printf '## F%s — cause\n- Signal: approval_stall · rows: 3 · sessions: 2 · weeks: a..b\n- Evidence: %s\n- Cause (inferred): x\n- Fix target: %s — rule\n- Proposed change: y\n%s- Status: proposed\n\n' \
    "$1" "$2" "$3" "${4-- Measure: signal = 'approval_stall' — expect 3/week → 0/week
}"
}

{ echo '# Trace findings — 2026-01-05'; echo 'Scope: all'; echo
  finding 1 '`claude/-tmp-x/s1.jsonl:30`, `codex/2026/01/05/r1.jsonl:1`' allow-rule
  finding 2 '`claude/-tmp-x/s1.jsonl:1`' task-prompt; } >"$work/clean.md"
expect "clean file passes" 0 "2 findings, 3 citations, 0 failures" "$work/clean.md"

{ finding 1 '`claude/-tmp-x/nope.jsonl:3`' skill; } >"$work/missing.md"
expect "missing archive file fails" 1 "file not in archive" "$work/missing.md"

{ finding 1 '`codex/2026/01/05/r1.jsonl:11`' skill; } >"$work/past.md"
expect "line past the end fails" 1 "line past the end (10 lines)" "$work/past.md"

{ finding 1 '`claude/-tmp-x/s1.jsonl:2`' skill; finding 2 'none given' skill; } >"$work/nocite.md"
expect "finding with no pointer fails" 1 "F2: no evidence pointer" "$work/nocite.md"

{ finding 1 '`claude/-tmp-x/s1.jsonl:2`' settings; } >"$work/badtype.md"
expect "unknown fix-target type fails" 1 "fix target 'settings' not in" "$work/badtype.md"

{ finding 1 '`claude/-tmp-x/s1.jsonl:2`' skill ''; } >"$work/nomeasure.md"
expect "missing Measure line fails" 1 "F1: no 'Measure:' line" "$work/nomeasure.md"

echo '# Trace findings — empty' >"$work/empty.md"
expect "file with no findings fails" 1 "no '## F<n>' findings" "$work/empty.md"

expect "missing archive is a usage error" 2 "no archive at" "$work/clean.md" --home "$work/nowhere"

[ "$bad" -eq 0 ] && echo "all cite_check cases pass"
exit "$bad"
