#!/bin/sh
# Tally with its demo seed and a gitignored plan/. The prompt asks for hosted mode but names
# no hostname, so no zone has been named.
set -eu
cp -R "$FIXTURES/tally/." .
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
printf '/plan\n' > .gitignore
git init -q && g add -A && g commit -qm "Tally v1"
git rev-parse HEAD > "$META/head"
