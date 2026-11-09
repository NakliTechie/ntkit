#!/bin/sh
# Skill text carries rules, not credits (AUTHORING §10). Fails on a source credit inside skills/:
# "idea from", "adapted from", "pattern from", an arXiv id, or "(ideas only)". Credits go in
# CREDITS.md. The vendored brag tool keeps its own notices and is skipped.
set -eu
command -v git >/dev/null || { echo "git not found"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git checkout"; exit 77; }
hits=$(git ls-files -co --exclude-standard 'skills/*.md' | grep -v '/brag/' \
  | xargs grep -n -i -E 'ideas? from|adapted from|pattern from|arxiv[:.]|\(ideas? only\)' || true)
if [ -n "$hits" ]; then
  echo "FAIL credits inside skill text (move them to CREDITS.md):"; printf '%s\n' "$hits" | sed 's/^/     | /' | head -40
  exit 1
fi
echo "lean: no credits in skill text"
