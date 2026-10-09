#!/bin/sh
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
PYTHONDONTWRITEBYTECODE=1 ROOT="$root" python3 - <<'PY'
import importlib.util, json, os, tempfile
from pathlib import Path
s = importlib.util.spec_from_file_location('bench', Path(os.environ['ROOT']) / 'evals/research-bench.py')
b = importlib.util.module_from_spec(s); s.loader.exec_module(b)
with tempfile.TemporaryDirectory() as temp:
    d = Path(temp); prompts = d / 'prompts.json'; source = d / 'source'; out = d / 'blind'
    rows = [{'sample_id': sid, 'prompt': 'question', 'rubrics': [
        {'criterion': 'correct', 'weight': 3}, {'criterion': 'wrong', 'weight': -2}]} for sid in sorted(b.IDS)]
    prompts.write_text(json.dumps(rows))
    for row in rows:
        p = source / row['sample_id']; p.mkdir(parents=True)
        for arm in ('A', 'B'):
            (p / f'{arm}.md').write_text('Report body.')
            (p / f'{arm}.metrics.json').write_text(json.dumps({'agent_runs': 2, 'wall_seconds': 4,
                'words': 2, 'claims': {'supported': 9, 'partial': 1, 'unsupported': 0}}))
    b.prepare(prompts, source, out)
    manifest = json.loads((out / 'manifest.json').read_text())
    for pair in manifest['pairs']:
        judgments = {str(i): [True, arm == 'A'] for i, arm in enumerate(pair['order'], 1)}
        (out / 'judge' / pair['id'] / 'verdicts.json').write_text(json.dumps(judgments))
    result = b.score(out)
    assert result['ship'] and result['B_wins'] == 5
    assert result['mean_rubric']['A'] == 1/3 and result['mean_rubric']['B'] == 1
    try: b.prepare(prompts, source, out)
    except ValueError: pass
    else: raise AssertionError('reblinding allowed')
    pair = manifest['pairs'][0]; verdict = out / 'judge' / pair['id'] / 'verdicts.json'
    original = verdict.read_text()
    verdict.write_text('{"1": [true], "2": [true, false]}')
    try: b.score(out)
    except ValueError: pass
    else: raise AssertionError('incomplete scoring allowed')
    verdict.write_text(original)
    manifest['pairs'][0]['metrics']['B']['claims'] = {'supported': 0, 'partial': 10, 'unsupported': 0}
    (out / 'manifest.json').write_text(json.dumps(manifest))
    assert not b.score(out)['ship'], 'support regression must block shipping'
    (out / 'judge' / pair['id'] / '1.md').write_text('Substituted report.')
    try: b.score(out)
    except ValueError: pass
    else: raise AssertionError('changed report accepted')
print('research benchmark: all cases pass')
PY
