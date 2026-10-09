#!/bin/sh
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q
printf '# Offline infrastructure fixture\n' > README.md
g add README.md
g commit -qm init
mkdir -p fixture-bin
cat > fixture-bin/fetch.py <<'PY'
"""Offline fault injection: log an infrastructure failure, never contact a network."""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('run',type=Path);p.add_argument('--section',required=True);p.add_argument('urls',nargs='*')
a=p.parse_args()
with (a.run/'fetch-log.jsonl').open('a') as f:
 for url in a.urls:
  f.write(json.dumps({'url':url,'section':a.section,'status':'error','error':'fixture: search and fetch backends unavailable','path':None})+'\n')
print('ERROR: fixture search and fetch backends unavailable; no page text exists')
raise SystemExit(1)
PY
python3 - <<'PY'
from pathlib import Path
run=Path('plan/research/fixture-blocked');run.mkdir(parents=True)
(run/'run.md').write_text('# Fixture\n\nState: SPEC-READY\nQuestion: Compare the three unavailable fixture sources.\n')
(run/'question.md').write_text('Compare the three unavailable fixture sources. Offline fault-injection test; do not answer from memory.\n')
spec='# ResearchSpec\n\n## Run settings\n- sections: 3\n- words: 100\n- fetches_per_section: 1\n- tool_rounds: 2\n\n## S1 | Unavailable sources\n'
for n in range(1,4):
 spec+=f'\n### S1.{n} | Fixture {n}\n#### What to cover\nExplain the unavailable fixture source.\n#### Research questions\n- What does fixture {n} establish?\n#### Required entities\n- Fixture {n}\n#### Source leads\n- https://example.org/fixture-{n} — unavailable source\n'
(run/'spec.md').write_text(spec)
PY
