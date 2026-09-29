#!/bin/sh
# plancheck against small plan/ folders: clean, orphan, ghost, a quoted tag that matches,
# a quoted tag that does not (misquote), a soc quote, and standing.md read as derived.
# No model calls. Contract: MEMORY.md §4, §5, §7.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
PC=$(cd "$(dirname "$0")/.." && pwd)/skills/replan-nt/bin/plancheck.py
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
bad=0
expect() { # expect <description> <exit code> <substring> <plan dir> [plancheck args...]
  desc=$1; want_rc=$2; want=$3; dir=$4; shift 4
  set +e; out=$(python3 "$PC" "$dir" "$@" 2>&1); rc=$?; set -e
  if [ "$rc" -ne "$want_rc" ]; then
    echo "FAIL $desc: exit $rc, wanted $want_rc"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1; return
  fi
  case $out in *"$want"*) : ;; *)
    echo "FAIL $desc: output lacks '$want'"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1 ;;
  esac
}
base() { # base <dir>: records every case shares
  mkdir -p "$1/plan/_archive"
  cat >"$1/plan/2026-09-10-summary.md" <<'EOF'
# Summary 2026-09-10
**Shipped:** the trigram index landed behind a *feature flag*.
**Decisions:** keep SQLite; the Postgres move is parked until usage passes 10k rows.

## Impact
- pending.md/Now — add: flip the trigram flag on for everyone
EOF
  cat >"$1/plan/soc.md" <<'EOF'
# soc
- 2026-09-11 09:15 — maybe preload the session on login
  it would hide the cold start
- 2026-09-11 10:02 — unrelated thought about colours
EOF
}

# 1. clean: plain tag, quoted tag with markup and case differences, soc quote, hand.
c="$work/clean"; base "$c"
cat >"$c/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Revisit Postgres at 10k rows  [from: 2026-09-10-summary "the Postgres move is parked until usage passes 10k rows"]
- Trigram index is live  [from: 2026-09-10-summary "The trigram index landed behind a feature flag"]
- Preload the session  [from: soc:2026-09-11T09:15 "hide the cold start"]
- Ask legal about retention  [from: hand "anything"]
EOF
expect "clean folder passes" 0 "Replay: clean" "$c"
expect "clean folder counts quoted tags" 0 "(3 quoted)" "$c"

# 2. misquote: the words are not in the named record.
m="$work/misquote"; base "$m"
cat >"$m/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Move to Postgres now  [from: 2026-09-10-summary "we decided to move to Postgres now"]
EOF
expect "misquote is a hard finding" 1 "misquote" "$m"
expect "misquote names the record" 1 "is not in 2026-09-10-summary" "$m"

# 3. a soc quote checks only that entry, not the whole stream.
s="$work/soc"; base "$s"
cat >"$s/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Colours  [from: soc:2026-09-11T09:15 "unrelated thought about colours"]
EOF
expect "soc quote from another entry is a misquote" 1 "misquote" "$s"

# 4. orphan still works with a quoted tag.
o="$work/orphan"; base "$o"
cat >"$o/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Ghost task  [from: 2026-09-01-summary "does not exist"]
EOF
expect "quoted tag naming no record is an orphan" 1 "1 orphan(s)" "$o"

# 5. ghost: an add impact nobody cites.
g="$work/ghost"; base "$g"
printf '# Pending\n## Now\n- Something else  [from: hand]\n' >"$g/plan/pending.md"
expect "uncited add impact is a ghost" 1 "1 ghost(s)" "$g"

# 6. standing.md is a derived file: its items are checked like pending.md's.
t="$work/standing"; base "$t"
printf '# Pending\n## Now\n- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]\n' >"$t/plan/pending.md"
cat >"$t/plan/standing.md" <<'EOF'
# Standing questions
## What is waiting on Chirag?
- The Postgres decision at 10k rows  [from: 2026-09-10-summary "parked until usage passes 10k rows"]
## What did we ship last?
- A trigram index  [from: 2026-09-09-summary "trigram"]
EOF
expect "standing.md items are provenance-checked" 1 "standing.md:" "$t"
expect "standing.md orphan is reported" 1 "1 orphan(s)" "$t"

# 7. --json carries the misquote kind.
expect "json output names misquote" 1 '"kind": "misquote"' "$m" --json

[ "$bad" -eq 0 ] && echo ok
