#!/bin/sh
# A repo with one skill whose SKILL.md has no references/ folder: meta mode has no fence to edit.
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q
mkdir -p skills/notes-nt
printf -- '---\ndescription: "Append a note."\n---\n\nAppend one line to notes.md.\n' > skills/notes-nt/SKILL.md
printf '# Skills\n' > README.md
g add -A && g commit -qm "init"
