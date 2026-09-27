#!/bin/sh
# The vendored brag in package-nt is an unedited copy: every file matches VENDORED.sha256,
# nothing unlisted sits beside it, and no music track is committed (ende.app's license
# forbids redistributing the files as-is; see VENDORED.md).
set -eu
root=$(cd "$(dirname "$0")/.." && pwd); d=$root/skills/package-nt/references/brag
fail() { echo "FAIL: $*"; exit 1; }
[ -f "$d/VENDORED.sha256" ] || fail "no VENDORED.sha256"
(cd "$d" && shasum -a 256 -c VENDORED.sha256 --quiet) || fail "a vendored file differs from its recorded hash"
listed=$(cut -c67- "$d/VENDORED.sha256" | sort)
present=$(cd "$d" && find . -type f ! -name 'VENDORED*' ! -path './assets/music/.gitignore' ! -name '*.mp3' ! -name '.DS_Store' | sed 's#^\./##' | sort)
[ "$listed" = "$present" ] || fail "files present but not in VENDORED.sha256: $(printf '%s\n' "$present" | grep -vxF "$listed" | head -3)"
cmp -s "$d/slim.md" "$d/brag.md" && fail "slim.md and brag.md are the same file"
n=$(cd "$root" && git ls-files skills/package-nt/references/brag | grep -c '\.mp3$' || true)
[ "$n" -eq 0 ] || fail "$n music track(s) committed under references/brag"
echo ok
