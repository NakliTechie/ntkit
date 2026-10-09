#!/bin/sh
# forward-pass-nt and harden-nt each ship security-classes.md (skills install one by one, so
# neither can point at the other). Only the opening paragraph and the closing "Applying it"
# section may differ; the class catalogue between them must stay byte-identical. No model calls.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
a=$root/skills/forward-pass-nt/references/security-classes.md
b=$root/skills/harden-nt/references/security-classes.md
body() { sed -n '/^Condensed from/,/^### Applying it/p' "$1"; }
[ -n "$(body "$a")" ] || { echo "FAIL no catalogue found in $a"; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
body "$a" >"$tmp/a"; body "$b" >"$tmp/b"
if ! diff -u "$tmp/a" "$tmp/b" >"$tmp/d"; then
  echo "FAIL security-classes catalogues differ (forward-pass-nt vs harden-nt):"; sed 's/^/     | /' "$tmp/d" | head -40; exit 1
fi
echo "security-classes: catalogues identical ($(wc -l <"$tmp/a" | tr -d ' ') lines)"
