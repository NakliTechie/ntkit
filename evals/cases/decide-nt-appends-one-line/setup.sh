#!/bin/sh
# Tally with a gitignored plan/ that already holds one decision.
set -eu
cp -R "$FIXTURES/tally/." .
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
printf '/plan\n' > .gitignore
git init -q && g add -A && g commit -qm "Tally v1"
mkdir plan
printf '# History\n\n## Decisions\n\n- 2026-01-02 Keep counters in localStorage; no server\n\n## Log\n\n## Dead ends\n' > plan/history.md
cp plan/history.md "$META/history.before"
