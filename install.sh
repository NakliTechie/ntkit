#!/bin/sh
# Install ntkit into a host's skills directory. Claude reads autocomplete hints at the top level.
set -eu
claude=0
if [ "${1:-}" = --claude ]; then claude=1; shift; fi
if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo 'Usage: install.sh [--claude] SKILLS_DIRECTORY' >&2
  exit 2
fi
root=$(cd "$(dirname "$0")" && pwd)
mkdir -p -- "$1"
dest=$(cd -- "$1" && pwd -P)
stage=$(mktemp -d "$dest/.ntkit-install.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
trap 'exit 1' HUP INT TERM

for skill in "$root"/skills/*; do
  name=${skill##*/}
  cp -R "$skill" "$stage/$name"
  if [ "$claude" -eq 1 ]; then
    # Keep the original YAML scalar, including any escapes, in the Claude-specific copy.
    awk 'NR == 1 { header = 1 } NR > 1 && /^---$/ { header = 0 }
         header && /^  argument-hint: / { hint = substr($0, 3) }
         !header && hint { print hint; hint = "" }
         { print }' "$skill/SKILL.md" > "$stage/$name/SKILL.md"
  fi
  if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
    if [ -L "$dest/$name" ] || ! diff -qr "$stage/$name" "$dest/$name" >/dev/null; then
      echo "Existing skill differs: $dest/$name. Move it aside before installing." >&2
      exit 1
    fi
  fi
done

for skill in "$stage"/*; do
  target=$dest/${skill##*/}
  [ -d "$target" ] || mv "$skill" "$dest/"
done
echo "Installed ntkit skills in $dest"
