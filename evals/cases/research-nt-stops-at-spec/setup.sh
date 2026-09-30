#!/bin/sh
# A bare project: a first /research-nt call without --go must plan, then stop for approval.
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q && printf '# Notes\n' > README.md && g add -A && g commit -qm "init"
