#!/bin/sh
# A bare project with no plan/: an empty /research-nt call must show its usage and write nothing.
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q && printf '# Notes\n' > README.md && g add -A && g commit -qm "init"
