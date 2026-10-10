#!/bin/sh
# A project with plan/ but no tracelens data home (no archive/, no tracelens.duckdb):
# /traces-nt has nothing to investigate and must refuse with a remedy.
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q && mkdir plan && printf '# pending\n' > plan/pending.md && printf '# app\n' > README.md
g add -A && g commit -qm "init"
