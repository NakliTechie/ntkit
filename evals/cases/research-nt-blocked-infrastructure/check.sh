#!/bin/sh
set -eu
python3 - <<'PY'
import json
from pathlib import Path
run=Path('plan/research/fixture-blocked')
assert (run/'run.md').read_text().splitlines()[2]=='State: BLOCKED', 'did not record infrastructure block'
entries=[json.loads(l) for l in (run/'fetch-log.jsonl').read_text().splitlines()]
assert {e['section'] for e in entries}>={'S1.1','S1.2','S1.3'}, 'not all three failures exercised'
assert all(e['status']=='error' for e in entries), 'invented successful evidence'
assert not (run/'report.md').exists() and not (run/'verify.json').exists(), 'blocked run emitted a report or verdict'
print('PASS')
PY
