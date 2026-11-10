#!/bin/sh
# plancheck against small plan/ folders: clean, orphan, ghost, a quoted tag that matches,
# a quoted tag that does not (misquote), a soc quote, standing.md read as derived, wrapped
# tags, --since on items, partial ghosts, plan/research/ records and _archive/ copies.
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
reject() { # reject <description> <substring> <plan dir> [plancheck args...]: output must lack it
  desc=$1; unwanted=$2; dir=$3; shift 3
  set +e; out=$(python3 "$PC" "$dir" "$@" 2>&1); set -e
  case $out in *"$unwanted"*)
    echo "FAIL $desc: output has '$unwanted'"; printf '%s\n' "$out" | sed 's/^/     | /'; bad=1 ;;
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
## What is waiting on the owner?
- The Postgres decision at 10k rows  [from: 2026-09-10-summary "parked until usage passes 10k rows"]
## What did we ship last?
- A trigram index  [from: 2026-09-09-summary "trigram"]
EOF
expect "standing.md items are provenance-checked" 1 "standing.md:" "$t"
expect "standing.md orphan is reported" 1 "1 orphan(s)" "$t"

# 7. --json carries the misquote kind.
expect "json output names misquote" 1 '"kind": "misquote"' "$m" --json

# 8. a tag on a wrapped continuation line belongs to its item (no false ghost).
w="$work/wrapped"; base "$w"
cat >"$w/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone, once the index has run a week
  without a rebuild.  [from: 2026-09-10-summary]
EOF
expect "tag on a continuation line is read" 0 "Replay: clean" "$w"

# 9. --since drops items dated before it, as well as records (no false orphan).
n="$work/since"; base "$n"
printf '# Summary 2026-08-01\n\n## Impact\n- none\n' >"$n/plan/2026-08-01-summary.md"
cat >"$n/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- An August item  [from: 2026-08-01-summary]
EOF
expect "--since skips an item whose record is out of range" 0 "Replay: clean" "$n" --since 2026-09-01

# 10. each add line needs its own citing item: one citation does not cover three adds.
p="$work/partial"; base "$p"
cat >"$p/plan/2026-09-12-summary.md" <<'EOF'
# Summary 2026-09-12

## Impact
- pending.md/Now — add: first follow-up
- pending.md/Now — add: second follow-up
- pending.md/Now — add: third follow-up
EOF
cat >"$p/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- First follow-up  [from: 2026-09-12-summary]
EOF
expect "two uncited adds of three are two ghosts" 1 "2 ghost(s)" "$p"
# An unquoted citation cannot say which add it answers: one finding names every candidate line.
expect "an unquoted citation leaves all three adds as candidates" 1 "2026-09-12-summary.md:4,5,6" "$p"

# 14. a quoted citation answers the add whose text holds its words; the other adds are the ghosts.
q="$work/quoted-impact"; base "$q"
cp "$p/plan/2026-09-12-summary.md" "$q/plan/"
cat >"$q/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Third follow-up  [from: 2026-09-12-summary "third follow-up"]
EOF
expect "a quoted citation leaves exactly the other adds as ghosts" 1 "2 ghost(s)" "$q"
expect "the first uncited add is a ghost" 1 "2026-09-12-summary.md:4 " "$q"
expect "the second uncited add is a ghost" 1 "2026-09-12-summary.md:5 " "$q"
reject "the quoted add is not a ghost" "2026-09-12-summary.md:6" "$q"

# 15. quoted and unquoted together: the quote is matched first, the count covers the rest.
x="$work/mixed-impact"; base "$x"
cp "$p/plan/2026-09-12-summary.md" "$x/plan/"
cat >"$x/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Second follow-up  [from: 2026-09-12-summary "second follow-up"]
- Some follow-up  [from: 2026-09-12-summary]
EOF
expect "one add missing of two candidates is one ghost" 1 "1 ghost(s)" "$x"
expect "the ghost names both unquoted candidates" 1 "2026-09-12-summary.md:4,6" "$x"

# 16. an add line that names another source with its own [from:] tag is that source's to cite,
# not this record's: its item cites [from: hand], and no ghost is reported.
h="$work/handtag"; base "$h"
printf '# Summary 2026-09-13\n\n## Impact\n- pending.md/Now — add: write the release notes  [from: hand]\n' >"$h/plan/2026-09-13-summary.md"
cat >"$h/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- [ ] Write the release notes  [from: hand]
EOF
expect "an add tagged with another source is not this record's ghost" 0 "Replay: clean" "$h"

# 11. /research-nt reports under plan/research/ are records: a flat file by its stem,
# a run folder by its folder name.
r="$work/research"; base "$r"
mkdir -p "$r/plan/research/2026-09-12-cache-study"
printf '# Cache study\nThe LRU wins below 4 GB.\n' >"$r/plan/research/2026-09-12-cache-study/report.md"
printf '# Notes\nRead the flare server.\n' >"$r/plan/research/2026-09-13-flare-notes.md"
cat >"$r/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]
- Keep the LRU  [from: 2026-09-12-cache-study "The LRU wins below 4 GB"]
- Read flare  [from: 2026-09-13-flare-notes]
EOF
expect "research reports resolve" 0 "Replay: clean" "$r"

# 12. an archived copy of a record never replaces the live one.
a="$work/archived"; base "$a"
printf '# Summary 2026-09-10 (older draft)\n\n## Impact\n- none\n' >"$a/plan/_archive/2026-09-10-summary.md"
cat >"$a/plan/pending.md" <<'EOF'
# Pending
## Now
- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary "flip the trigram flag"]
EOF
expect "the live record wins over its archived copy" 0 "Replay: clean" "$a"

# 13. an archived record's add lines are not ghosts: the reconcile pass applied them when it
# folded the record, and the items may since be finished and removed.
g="$work/folded"; base "$g"
printf '# Forward pass 2026-08-01\n\n## Impact\n- pending.md/Now — add: fix the parser\n' >"$g/plan/_archive/forward-pass-2026-08-01.md"
printf '# Pending\n## Now\n- [ ] Flip the trigram flag on for everyone  [from: 2026-09-10-summary]\n' >"$g/plan/pending.md"
expect "an archived record's finished adds are not ghosts" 0 "Replay: clean" "$g"

# 14. [at:] pointers: a file and line range, a commit and a session transcript resolve; a missing
# file, a line past the end, an unknown commit and a path outside the repo are dangling (exit 1);
# a transcript absent on this machine is reported as unreachable, not as a failure.
pt="$work/pointers"; base "$pt"; mkdir -p "$pt/src" "$work/tx/proj"
printf 'a\nb\nc\n' >"$pt/src/db.py"; echo '{}' >"$work/tx/proj/sess-1.jsonl"
git -C "$pt" init -q; git -C "$pt" -c user.email=t@t -c user.name=t add src/db.py
git -C "$pt" -c user.email=t@t -c user.name=t commit -qm init; sha=$(git -C "$pt" rev-parse --short HEAD)
printf '# Pending\n## Now\n- [ ] Flip the flag  [from: 2026-09-10-summary] [at: src/db.py:2-3, %s] [at: session:sess-1]\n- Format note  [at: <path>:<line>]\n' "$sha" >"$pt/plan/pending.md"
export NT_TRANSCRIPTS="$work/tx"
expect "pointers that resolve pass" 0 "3 pointers" "$pt"
printf '# Pending\n## Now\n- [ ] A  [at: src/gone.py]\n- [ ] B  [at: src/db.py:9]\n- [ ] C  [at: deadbee]\n- [ ] D  [at: ../outside.txt]\n' >"$pt/plan/pending.md"
expect "a missing file is dangling" 1 "no file src/gone.py" "$pt"
expect "a line past the end is dangling" 1 "has 3 lines, not 9" "$pt"
expect "an unknown commit is dangling" 1 "no commit deadbee" "$pt"
expect "a path outside the repo is dangling" 1 "outside the repo" "$pt"
expect "the summary counts dangling pointers" 1 "4 dangling pointer(s)" "$pt"
printf '# Pending\n## Now\n- [ ] A  [from: 2026-09-10-summary] [at: session:sess-elsewhere]\n' >"$pt/plan/pending.md"
expect "a transcript on another machine is unreachable, not a failure" 0 "unreachable here" "$pt"
# a plan/ that is a symlink into a plan store still resolves paths against the repo
st="$work/store"; mv "$pt/plan" "$st"; ln -s "$st" "$pt/plan"
printf '# Pending\n## Now\n- [ ] A  [from: 2026-09-10-summary] [at: src/db.py:1]\n' >"$st/pending.md"
expect "pointers resolve through a symlinked plan/" 0 "1 pointers" "$pt"
unset NT_TRANSCRIPTS

[ "$bad" -eq 0 ] && echo ok
