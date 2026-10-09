#!/bin/sh
# cite-check against a small project and forward-pass reports: clean pointers, a missing
# file, a line past the end, a range past the end, a finding with no pointer, and the things
# it must ignore (URLs, host:port, times, markdown link text). No model calls.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
CC=$(cd "$(dirname "$0")/.." && pwd)/skills/forward-pass-nt/bin/cite-check.py
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
bad=0
expect() { # expect <description> <exit code> <substring> <report>
  desc=$1; want_rc=$2; want=$3; report=$4
  set +e; out=$(cd "$work/app" && python3 "$CC" "$report" 2>&1); rc=$?; set -e
  if [ "$rc" -ne "$want_rc" ]; then
    echo "FAIL $desc: exit $rc, wanted $want_rc"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1; return
  fi
  case $out in *"$want"*) : ;; *)
    echo "FAIL $desc: output lacks '$want'"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1 ;;
  esac
}

mkdir -p "$work/app/src/api" "$work/app/plan"
seq 1 50 | sed 's/^/line /' >"$work/app/src/api/orders.ts"
printf 'all: build\n' >"$work/app/Makefile"
printf '# Workplan\n- [x] totals\n' >"$work/app/plan/workplan.md"

# 1. clean: plain, backticked, linked, ranged, Makefile, plan file; ignorables around them.
cat >"$work/app/plan/clean.md" <<'EOF'
# Forward pass 2026-10-01
Reviewer: claude-opus-5-5 · prior: none
Commit: 41a6b57
Run at 09:15 against localhost:3000 and api.example.com:443 and 127.0.0.1:8080.
- **H1** [Security] src/api/orders.ts:42 — `applyDiscount()` trusts `qty` · ingress: src/api/orders.ts:3
- **M2** [Bug] `src/api/orders.ts:10-20` — off by one
- **S1** [Stray] [orders.ts:50](src/api/orders.ts:50) — dead branch
- **L1** [Bug] Makefile:1 — no clean target
- **SB1** [Stub] claimed in plan/workplan.md:2, but src/api/orders.ts:7 returns []
See https://github.com/google/mantis/blob/main/x.py:12 for the source.
- [ ] **H1** Validate qty (src/api/orders.ts:42). Reject negatives.
EOF
expect "clean report passes" 0 "0 failures" plan/clean.md
expect "clean report counts pointers" 0 "8 pointers" plan/clean.md

# 2. a missing file.
cat >"$work/app/plan/missing.md" <<'EOF'
- **H1** [Security] src/api/order.ts:42 — misspelt path
EOF
expect "missing file fails" 1 "src/api/order.ts:42 - no such file" plan/missing.md

# 3. a line past the end, and a range whose end is past the end.
cat >"$work/app/plan/range.md" <<'EOF'
- **H1** [Bug] src/api/orders.ts:51 — one past the end
- **M1** [Bug] src/api/orders.ts:40-60 — range runs off the end
EOF
expect "line past end fails" 1 "src/api/orders.ts:51 - file has 50 lines" plan/range.md
expect "range past end fails" 1 "src/api/orders.ts:40-60 - file has 50 lines" plan/range.md

# 4. a finding entry with no pointer.
cat >"$work/app/plan/nopointer.md" <<'EOF'
- **C1** [Security] the auth check looks wrong somewhere
EOF
expect "finding without pointer fails" 1 "finding cites no path:line" plan/nopointer.md

# 5. usage: no report.
expect "missing report is a usage error" 2 "no report" plan/absent.md

[ "$bad" -eq 0 ] && echo "cite-check: all cases pass"
exit "$bad"
