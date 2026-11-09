#!/bin/sh
# Exercise both install formats in a fresh destination with spaces and an unrelated skill.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
dest="$tmp/agent skills"
mkdir -p "$dest/other"
echo keep > "$dest/other/note"
"$root/install.sh" "$dest"
"$root/install.sh" "$dest"
"$root/install.sh" --claude "$tmp/claude"
for src in "$root"/skills/*; do
  name=${src##*/}
  diff -qr "$src" "$dest/$name"
  hint=$(sed -n 's/^  argument-hint: /argument-hint: /p' "$src/SKILL.md")
  grep -Fxq "$hint" "$tmp/claude/$name/SKILL.md"
  sed '/^argument-hint: /d' "$tmp/claude/$name/SKILL.md" | cmp - "$src/SKILL.md"
done
rm -r "$dest/autopilot-nt"
echo local-edit >> "$dest/windup-nt/SKILL.md"
if "$root/install.sh" "$dest"; then exit 1; fi
grep -Fxq local-edit "$dest/windup-nt/SKILL.md"
test ! -e "$dest/autopilot-nt"
grep -Fxq keep "$dest/other/note"
