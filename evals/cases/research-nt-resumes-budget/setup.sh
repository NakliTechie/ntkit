#!/bin/sh
set -eu
g() { git -c user.name=eval -c user.email=eval@example.invalid "$@"; }
git init -q
printf '# Research fixture\n' > README.md
g add README.md
g commit -qm init
python3 - <<'PY'
import hashlib,json
from pathlib import Path
run=Path('plan/research/fixture-budget'); (run/'sections').mkdir(parents=True)
(run/'run.md').write_text('# Fixture\n\nState: BUDGET\nQuestion: Summarize Alpha and Beta from the stored fixture pages only.\n')
(run/'question.md').write_text('Summarize Alpha and Beta from the stored fixture pages only. This is an offline fixture: use the already fetched text and do not access the network.\n')
spec='# ResearchSpec\n\n## Run settings\n- sections: 2\n- words: 100\n- fetches_per_section: 1\n- tool_rounds: 5\n\n## S1 | Fixture sources\n'
entries=[]
for n,name in [(1,'Alpha'),(2,'Beta')]:
 sid=f'S1.{n}';url=f'https://example.org/{name.lower()}'
 spec+=f'\n### {sid} | {name}\n#### What to cover\nState the fixture value.\n#### Research questions\n- What value does {name} have?\n#### Required entities\n- {name}\n#### Source leads\n- {url} — stored fixture text\n'
 page=run/f'page-{n}.txt';page.write_text(f'{name} has fixture value {n}.\n')
 entries.append({'url':url,'final_url':url,'section':sid,'status':'ok','http_status':200,
 'path':str(page.resolve()),'text_sha256':hashlib.sha256(page.read_bytes()).hexdigest()})
 heading=f'### {sid} | {name}' if n==1 else 'BROKEN HEADING'
 (run/'sections'/f'{sid}.md').write_text(f'{heading}\n\n{name} has fixture value {n}. ([Fixture source]({url}))\n')
(run/'spec.md').write_text(spec)
(run/'fetch-log.jsonl').write_text(''.join(json.dumps(e)+'\n' for e in entries))
(run/'preserved-sha256').write_text(hashlib.sha256((run/'sections/S1.1.md').read_bytes()).hexdigest())
PY
