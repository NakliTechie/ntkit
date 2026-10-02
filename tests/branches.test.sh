#!/bin/sh
# windup-nt/bin/branches.sh puts each kind of branch in its class. The remote is a bare
# repo in a temp dir; no network.
set -eu
command -v git >/dev/null || { echo "git not found"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/windup-nt/bin/branches.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
g() { git -c user.name=t -c user.email=t@example.invalid -c init.defaultBranch=main "$@"; }
c() { echo "$1" >"$1.txt"; g add "$1.txt"; g commit -qm "$1"; }

cd "$t" && g init -q --bare origin.git && g init -q work && cd work
c base && g remote add origin ../origin.git && g push -q -u origin main 2>/dev/null
g remote set-head origin main >/dev/null
g checkout -qb merged-ff && c a && g checkout -q main && g merge -q --no-ff merged-ff -m "merge a"
g checkout -qb squashed && c b1 && c b2 && g checkout -q main
g merge -q --squash squashed >/dev/null && g commit -qm "squash b"
g checkout -qb open && c open && g checkout -q main
g checkout -q --orphan gh-pages && g rm -rqf . && c site && g checkout -q main
g branch develop
g branch wt && g worktree add -q ../wt wt 2>/dev/null
g branch live && mkdir plan && echo "- [ ] review the live branch" >plan/pending.md
g checkout -qb ahead && c ah && g checkout -q main && g merge -q --no-ff ahead -m "merge ahead"
g push -q -u origin ahead 2>/dev/null && g push -q origin main merged-ff:remote-merged 2>/dev/null
(cd .. && g clone -q origin.git other 2>/dev/null && cd other && g checkout -q ahead \
  && c extra && g push -q origin ahead 2>/dev/null)
g fetch -q origin

out=$(sh "$script")
bad=0
expect() {  # <class> <ref> [detail substring]
  row=$(printf '%s\n' "$out" | awk -F '\t' -v r="$2" '$2 == r')
  case $row in
    "$1	$2	"*"${3:-}"*) ;;
    *) echo "FAIL: expected '$1 $2${3:+ ($3)}', got '${row:-nothing}'"; bad=1 ;;
  esac
}
absent() {
  printf '%s\n' "$out" | awk -F '\t' -v r="$1" '$2 == r { f = 1 } END { exit !f }' \
    && { echo "FAIL: $1 is listed"; bad=1; }
  return 0
}
expect merged merged-ff ancestor
expect merged squashed content
expect unmerged open "+1 commits"
expect hold develop long-lived
expect hold live plan/pending.md
expect hold ahead "origin/ahead holds unmerged"
expect unmerged origin/ahead
expect merged origin/remote-merged ancestor
for r in main gh-pages wt origin/main origin; do absent "$r"; done
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" -eq 8 ] || { echo "FAIL: expected 8 lines:"; echo "$out"; bad=1; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "FAIL: the script changed the tree"; bad=1; }
[ "$bad" -eq 0 ] && echo ok
