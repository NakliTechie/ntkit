#!/bin/sh
# prefs-nt's prefs_sync.py: builds installed agents' files, keeps every original, carries a hand
# edit (formatting intact) to every agent, and fails loudly on git trouble. One block per behaviour;
# the blocks after the first sync are regressions from the Codex review of 2026-10-18.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
command -v git >/dev/null || { echo "git not found"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
skill="$root/skills/prefs-nt"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"; mkdir -p "$HOME"; unset CODEX_HOME NT_PREFS_DIR || true
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
fail() { echo "FAIL: $*"; exit 1; }
run() { python3 "$skill/bin/prefs_sync.py" "$@"; }
sync() { run --dir "$HOME/prefs" "$@"; }
rcof() { rc=0; "$@" >"$tmp/out" 2>&1 || rc=$?; echo "$rc"; }
C="$HOME/.claude/CLAUDE.md"; X="$HOME/.codex/AGENTS.md"

# No folder: exit 2, nothing created.
[ "$(rcof sync)" -eq 2 ] || fail "missing folder: expected exit 2"
[ ! -e "$HOME/prefs" ] || fail "missing folder: the script created it"

# First sync from the template: Claude and Codex installed, Gemini not.
cp -R "$skill/references/template" "$HOME/prefs"
printf 'Prefer tabs.\n' > "$HOME/prefs/core/01-about.md"
mkdir -p "$HOME/.claude" "$HOME/.codex"
printf 'old claude rules\n' > "$C"
[ "$(rcof sync --check)" -eq 1 ] || fail "before sync: --check should exit 1"
sync >/dev/null
grep -q 'Prefer tabs.' "$C" && grep -q 'Prefer tabs.' "$X" || fail "core text missing"
grep -q 'Claude Code only' "$C" || fail "claude extras missing"
! grep -q 'Claude Code only' "$X" || fail "claude extras leaked into codex"
! grep -q '{{PREFS_DIR}}' "$C" || fail "placeholder not replaced"
grep -q '~/prefs/inbox.md' "$C" || fail "writeback path is not ~/prefs/inbox.md"
[ ! -e "$HOME/.gemini" ] || fail "wrote a file for an agent that is not installed"
grep -q 'old claude rules' "$HOME"/prefs/drift/claude-before-adoption-*.md || fail "original not saved"
sync --check >/dev/null || fail "after sync: --check should exit 0"

# Lost state: a second adoption never overwrites the first backup, and current files get a baseline.
rm -rf "$HOME/prefs/.state"; sync >/dev/null
[ "$(ls "$HOME"/prefs/drift/claude-before-adoption-* | wc -l)" -eq 2 ] || fail "adoption backup overwritten"
grep -lq 'old claude rules' "$HOME"/prefs/drift/claude-before-adoption-*.md || fail "first backup lost"
[ -f "$HOME/prefs/.state/codex.last" ] || fail "current file got no baseline"

# A hand edit in Codex reaches Claude with its indentation; dry-run previews that before writing.
printf '\n- Use pnpm, not npm.\n  - nested rule\n\n      code line\n' >> "$X"
before=$(cat "$C")
sync --dry-run > "$tmp/dry"
grep -q 'claude: writing' "$tmp/dry" || fail "dry-run did not preview the edit reaching claude"
[ "$before" = "$(cat "$C")" ] || fail "--dry-run changed a file"
[ "$(rcof sync --check)" -eq 1 ] || fail "hand edit: --check should exit 1"
sync >/dev/null
grep -q 'codex (hand edit):' "$HOME/prefs/inbox.md" || fail "edit not in inbox"
grep -q '^      - nested rule$' "$HOME/prefs/inbox.md" || fail "nested indentation lost"
grep -q '^          code line$' "$C" || fail "code indentation lost on the way to claude"
ls "$HOME"/prefs/drift/codex-2*.md >/dev/null 2>&1 || fail "edited copy not saved to drift/"
sync --check >/dev/null || fail "after edit sync: --check should exit 0"

# agents/<agent>.md is used as soon as it exists; no targets.tsv change needed.
printf '## Codex only\n\n- codex marker\n' > "$HOME/prefs/agents/codex.md"
sync >/dev/null
grep -q 'codex marker' "$X" || fail "agents/codex.md not used"
! grep -q 'codex marker' "$C" || fail "codex extras leaked into claude"

# A non-empty AGENTS.override.md shadows Codex's file: --check fails and names it.
printf 'override\n' > "$HOME/.codex/AGENTS.override.md"
[ "$(rcof sync --check)" -eq 1 ] && grep -q 'ignores' "$tmp/out" || fail "shadow file not reported"
rm "$HOME/.codex/AGENTS.override.md"

# CODEX_HOME moves Codex's file.
mkdir -p "$HOME/cx"; CODEX_HOME="$HOME/cx" sync >/dev/null
grep -q 'Prefer tabs.' "$HOME/cx/AGENTS.md" || fail "CODEX_HOME not honoured"

# A relative --dir still writes an absolute writeback path.
(cd "$HOME" && run --dir prefs >/dev/null)
grep -q '~/prefs/inbox.md' "$C" || fail "relative --dir leaked into the writeback path"

# A symlinked agent file stays a link; its target gets the new content.
mkdir -p "$HOME/dotfiles"; mv "$C" "$HOME/dotfiles/CLAUDE.md"; ln -s "$HOME/dotfiles/CLAUDE.md" "$C"
cp "$HOME/prefs/.state/claude.last" "$HOME/dotfiles/CLAUDE.md"
printf 'Prefer both.\n' > "$HOME/prefs/core/01-about.md"; sync >/dev/null
[ -L "$C" ] || fail "symlink replaced by a regular file"
grep -q 'Prefer both.' "$HOME/dotfiles/CLAUDE.md" || fail "symlink target not updated"

# The old three-column format (an extras name in column 3) fails with a message naming the fix.
cp "$HOME/prefs/targets.tsv" "$tmp/targets.keep"
printf 'claude\t~/.claude/CLAUDE.md\tclaude\n' > "$HOME/prefs/targets.tsv"
[ "$(rcof sync)" -eq 2 ] && grep -q 'agents/claude.md' "$tmp/out" || fail "old format not explained"
cp "$tmp/targets.keep" "$HOME/prefs/targets.tsv"

# A second sync while one holds the lock exits 3.
python3 - "$skill/bin/prefs_sync.py" "$HOME/prefs" <<'EOF' || fail "concurrent sync was not refused"
import fcntl, subprocess, sys
lock = open(sys.argv[2] + "/.state/lock", "w"); fcntl.flock(lock, fcntl.LOCK_EX)
sys.exit(0 if subprocess.run([sys.executable, sys.argv[1], "--dir", sys.argv[2]]).returncode == 3 else 1)
EOF

# Git: commits in its own repo; never touches an enclosing repo.
git -C "$HOME/prefs" init -q; git -C "$HOME/prefs" commit -q --allow-empty -m init
printf 'Prefer spaces.\n' > "$HOME/prefs/core/01-about.md"; sync >/dev/null
[ "$(git -C "$HOME/prefs" rev-list --count HEAD)" -eq 2 ] || fail "sync did not commit"
mkdir -p "$HOME/outer"; git -C "$HOME/outer" init -q; git -C "$HOME/outer" commit -q --allow-empty -m init
cp -R "$HOME/prefs" "$HOME/outer/p"; rm -rf "$HOME/outer/p/.git"; printf 'x\n' > "$HOME/outer/unrelated"
run --dir "$HOME/outer/p" >/dev/null
[ "$(git -C "$HOME/outer" rev-list --count HEAD)" -eq 1 ] || fail "committed in an enclosing repo"
[ -z "$(git -C "$HOME/outer" diff --cached --name-only)" ] || fail "staged files in an enclosing repo"

# Git failures exit 1: push to a missing remote; a failed pull writes nothing.
git -C "$HOME/prefs" remote add origin "$HOME/missing.git"
[ "$(rcof sync --push)" -eq 1 ] || fail "failed push did not exit 1"
git init -q --bare "$HOME/bare.git"; git -C "$HOME/prefs" remote set-url origin "$HOME/bare.git"
sync --push >/dev/null || fail "first push to an empty remote failed"
git -C "$HOME/bare.git" rev-parse -q --verify HEAD >/dev/null || fail "push did not reach the remote"
git -C "$HOME/prefs" commit -q --allow-empty -m local-only
sync --push >/dev/null || fail "retry push failed"
[ "$(git -C "$HOME/bare.git" rev-parse HEAD)" = "$(git -C "$HOME/prefs" rev-parse HEAD)" ] || fail "an unpushed commit was not retried"
mv "$HOME/bare.git" "$HOME/gone.git"; printf 'Prefer neither.\n' > "$HOME/prefs/core/01-about.md"
before=$(cat "$C")
[ "$(rcof sync --push)" -eq 1 ] || fail "failed pull did not exit 1"
[ "$before" = "$(cat "$C")" ] || fail "files were written after a failed pull"

# A first push with no upstream uses Git's pushDefault remote, not a hard-coded origin.
git -C "$HOME/prefs" remote remove origin
git init -q --bare "$HOME/backup.git"; git -C "$HOME/prefs" remote add backup "$HOME/backup.git"
git init -q --bare "$HOME/other.git"; git -C "$HOME/prefs" remote add other "$HOME/other.git"
git -C "$HOME/prefs" config remote.pushDefault backup
sync --push >/dev/null || fail "push to pushDefault failed"
git -C "$HOME/backup.git" rev-parse -q --verify HEAD >/dev/null || fail "pushDefault remote not used"
echo PASS
