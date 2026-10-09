#!/bin/sh
# Tally as a committed static site with a demo seed and a gitignored plan/.
set -eu
cp -R "$FIXTURES/tally/." .
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
printf '/plan\n' > .gitignore
git init -q && g add -A && g commit -qm "Tally v1"
