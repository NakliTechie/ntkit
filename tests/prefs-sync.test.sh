#!/bin/sh
# prefs-nt's prefs_sync.py: builds installed agents' files, skips absent agents, saves originals,
# carries a hand edit from one agent to every other through the inbox, and --check tells the truth.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
skill="$root/skills/prefs-nt"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"; mkdir -p "$HOME"
fail() { echo "FAIL: $*"; exit 1; }
sync() { python3 "$skill/bin/prefs_sync.py" --dir "$HOME/prefs" "$@"; }

# No folder: exit 2, nothing created.
rc=0; sync >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || fail "missing folder: expected exit 2, got $rc"
[ ! -e "$HOME/prefs" ] || fail "missing folder: the script created it"

# A folder from the template; Claude and Codex installed, Gemini not.
cp -R "$skill/references/template" "$HOME/prefs"
printf 'Prefer tabs.\n' > "$HOME/prefs/core/01-about.md"
mkdir -p "$HOME/.claude" "$HOME/.codex"
printf 'old claude rules\n' > "$HOME/.claude/CLAUDE.md"

rc=0; sync --check >/dev/null || rc=$?
[ "$rc" -eq 1 ] || fail "before sync: --check should exit 1, got $rc"
sync >/dev/null
grep -q 'Prefer tabs.' "$HOME/.claude/CLAUDE.md" || fail "core text missing from CLAUDE.md"
grep -q 'Prefer tabs.' "$HOME/.codex/AGENTS.md" || fail "core text missing from AGENTS.md"
grep -q 'Claude Code only' "$HOME/.claude/CLAUDE.md" || fail "claude extras missing"
! grep -q 'Claude Code only' "$HOME/.codex/AGENTS.md" || fail "claude extras leaked into codex"
! grep -q '{{PREFS_DIR}}' "$HOME/.claude/CLAUDE.md" || fail "placeholder not replaced"
grep -q '~/prefs/inbox.md' "$HOME/.claude/CLAUDE.md" || fail "writeback path not ~/prefs/inbox.md"
[ ! -e "$HOME/.gemini" ] || fail "wrote a file for an agent that is not installed"
grep -q 'old claude rules' "$HOME"/prefs/drift/claude-before-adoption-*.md || fail "original not saved"
sync --check >/dev/null || fail "after sync: --check should exit 0"

# A hand edit in Codex's file reaches Claude's file through the inbox.
printf '\n- Use pnpm, not npm.\n' >> "$HOME/.codex/AGENTS.md"
rc=0; sync --check >/dev/null || rc=$?
[ "$rc" -eq 1 ] || fail "hand edit: --check should exit 1, got $rc"
sync >/dev/null
grep -q 'codex (hand edit) · - Use pnpm, not npm.' "$HOME/prefs/inbox.md" || fail "edit not in inbox"
grep -q 'Use pnpm, not npm.' "$HOME/.claude/CLAUDE.md" || fail "edit did not reach CLAUDE.md"
ls "$HOME"/prefs/drift/codex-2*.md >/dev/null 2>&1 || fail "edited copy not saved to drift/"
sync --check >/dev/null || fail "after second sync: --check should exit 0"

# --dry-run writes nothing.
printf 'Prefer spaces.\n' > "$HOME/prefs/core/01-about.md"
before=$(cat "$HOME/.claude/CLAUDE.md")
sync --dry-run >/dev/null
[ "$before" = "$(cat "$HOME/.claude/CLAUDE.md")" ] || fail "--dry-run changed a file"

# In a git repo, sync commits; without --push it never pushes.
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
git -C "$HOME/prefs" init -q
git -C "$HOME/prefs" commit -q --allow-empty -m init
sync >/dev/null 2>&1 || true
[ "$(git -C "$HOME/prefs" rev-list --count HEAD)" -eq 1 ] && fail "sync did not commit"
echo PASS
