#!/bin/sh
# A project with a runnable CLI but no verify/features/: map mode has no map to check
# and must stop, pointing at a full /walkthrough-nt.
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q && mkdir plan && printf '# pending\n' > plan/pending.md
printf '#!/bin/sh\necho hello\n' > hello.sh && chmod +x hello.sh && printf '# hello\nRun ./hello.sh\n' > README.md
g add -A && g commit -qm "init"
