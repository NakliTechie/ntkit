#!/bin/sh
set -eu
python3 - <<'PY'
import hashlib,json
from pathlib import Path
run=Path('plan/research/fixture-budget')
assert hashlib.sha256((run/'sections/S1.1.md').read_bytes()).hexdigest()==(run/'preserved-sha256').read_text(), 'passing unit changed'
assert (run/'sections/S1.2.md').read_text().startswith('### S1.2 | Beta'), 'failing unit not repaired'
assert (run/'run.md').read_text().splitlines()[2]=='State: VERIFIED', 'no verified final state'
v=json.loads((run/'verify.json').read_text())
assert v['verified'] is True and not v['without'], 'bypassed verification'
assert all(g['pass'] is True for g in v['gates'].values()), 'gate failed'
print('PASS')
PY
