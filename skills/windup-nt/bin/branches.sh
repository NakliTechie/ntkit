#!/bin/sh
# Classify a repo's branches for /windup-nt's branch sweep. Changes nothing.
# Prints one tab-separated line per branch, oldest last commit first:
#   <class> <ref> <tip-sha> <detail>
# Classes:
#   merged    the default branch holds its work: the branch is an ancestor, or merging it
#             changes no file (a squash or rebase merge). Safe to delete; the SHA restores it.
#   hold      merged, but something still points at it: a long-lived name, its remote holds
#             unmerged commits, a local branch of the same name holds unmerged work, or
#             plan/pending.md or plan/workplan.md names it.
#   unmerged  the default branch lacks its work: +N commits, the last commit's date and subject.
# Never listed: the default branch, the current branch, branches checked out in a worktree
# (the worktree sweep owns them), and branches that share no history with the default
# branch (gh-pages and the like).
# Reads refs as they stand: `git fetch --prune` first for a current view of the remote.
# Usage: branches.sh [repo-dir]
set -eu
cd "${1:-.}"
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo: $(pwd)" >&2; exit 2; }

default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
default=${default#origin/}
if [ -z "$default" ]; then
  for b in main master; do
    if git show-ref --verify --quiet "refs/heads/$b"; then default=$b; break; fi
  done
fi
[ -n "$default" ] || { echo "no default branch: no origin/HEAD, main or master" >&2; exit 2; }
current=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
in_worktree=$(git worktree list --porcelain | sed -n 's#^branch refs/heads/##p')
default_tree=$(git rev-parse "$default^{tree}")

merged_how() {  # <ref> → prints ancestor | content; fails when the default branch lacks its work
  if git merge-base --is-ancestor "$1" "$default"; then echo ancestor; return 0; fi
  t=$(git merge-tree --write-tree "$default" "$1" 2>/dev/null | head -1)
  [ "$t" = "$default_tree" ] && { echo "content (squash or rebase merge)"; return 0; }
  return 1
}
named_in_plan() {  # <name> → prints the plan file that names it
  for f in plan/pending.md plan/workplan.md; do
    if [ -f "$f" ] && grep -qwF -- "$1" "$f"; then echo "$f"; return 0; fi
  done
  return 1
}
long_lived() {
  case $1 in
    develop|dev|staging|production|prod|release|release/*|gh-pages) return 0 ;;
  esac
  return 1
}
skip() {  # <ref> <name>
  [ "$2" = "$default" ] || [ "$2" = "$current" ] && return 0
  git merge-base "$default" "$1" >/dev/null 2>&1 || return 0
  return 1
}
line() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$(git rev-parse --short=12 "$2")" "$3"; }
unmerged() {
  line unmerged "$1" "+$(git rev-list --count "$default..$1") commits, last $(git log -1 --format='%cs: %s' "$1")"
}

for b in $(git for-each-ref --sort=committerdate --format='%(refname:short)' refs/heads/); do
  skip "refs/heads/$b" "$b" && continue
  printf '%s\n' "$in_worktree" | grep -qxF -- "$b" && continue
  how=$(merged_how "refs/heads/$b") || { unmerged "$b"; continue; }
  up=$(git rev-parse --abbrev-ref "$b@{upstream}" 2>/dev/null || true)
  if long_lived "$b"; then line hold "$b" "long-lived branch name"
  elif [ -n "$up" ] && ! merged_how "$up" >/dev/null; then line hold "$b" "its remote $up holds unmerged commits"
  elif f=$(named_in_plan "$b"); then line hold "$b" "named in $f"
  else line merged "$b" "$how"
  fi
done

git remote | grep -qx origin || exit 0
for r in $(git for-each-ref --sort=committerdate --format='%(refname:short)' refs/remotes/origin/); do
  name=${r#origin/}
  [ "$r" = origin ] || [ "$name" = HEAD ] && continue
  skip "$r" "$name" && continue
  how=$(merged_how "$r") || { unmerged "$r"; continue; }
  if long_lived "$name"; then line hold "$r" "long-lived branch name"
  elif git show-ref --verify --quiet "refs/heads/$name" && ! merged_how "refs/heads/$name" >/dev/null
  then line hold "$r" "local $name holds unmerged work"
  elif f=$(named_in_plan "$name"); then line hold "$r" "named in $f"
  else line merged "$r" "$how"
  fi
done
