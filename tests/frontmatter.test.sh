#!/bin/sh
# Every skill's frontmatter must parse as YAML and carry the AUTHORING.md §1 keys. A broken
# header loads silently: the harness falls back to the body's first line as the description.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
python3 -c 'import yaml' 2>/dev/null || { echo "PyYAML not installed"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
python3 - "$root" <<'PY'
import pathlib, re, sys, yaml
bad = []
for f in sorted(pathlib.Path(sys.argv[1], "skills").glob("*/SKILL.md")):
    m = re.match(r"^---\n(.*?)\n---\n", f.read_text(encoding="utf-8"), re.S)
    if not m:
        bad.append(f"{f.parent.name}: no frontmatter block"); continue
    try:
        meta = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        bad.append(f"{f.parent.name}: YAML error: {str(e).splitlines()[0]}"); continue
    for k in ("description", "entry", "exit", "writes"):
        if not isinstance(meta.get(k), str) or not meta[k].strip():
            bad.append(f"{f.parent.name}: '{k}' missing or not a string")
print("\n".join(bad) or "ok")
sys.exit(1 if bad else 0)
PY
