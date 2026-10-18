#!/bin/sh
# Tally with no preferences folder at ./prefs. The prompt asks for a sync there, so the
# skill must stop and point at init, without creating the folder or touching the project.
set -eu
cp -R "$FIXTURES/tally/." .
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q && g add -A && g commit -qm "Tally v1"
git rev-parse HEAD > "$META/head"
