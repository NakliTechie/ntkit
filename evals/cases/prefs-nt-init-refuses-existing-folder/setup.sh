#!/bin/sh
# Tally with a preferences folder already at ./prefs. init must stop: it never overwrites one.
set -eu
cp -R "$FIXTURES/tally/." .
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
printf '/prefs\n' > .gitignore
git init -q && g add -A && g commit -qm "Tally v1"
mkdir -p prefs/core
printf 'me\t~/nowhere-eval/AGENTS.md\t-\n' > prefs/targets.tsv
printf '## Mine\n\n- keep this line\n' > prefs/core/01-about.md
(cd prefs && find . -type f | sort | xargs shasum) > "$META/prefs.sums"
git rev-parse HEAD > "$META/head"
