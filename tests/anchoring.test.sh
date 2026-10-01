#!/bin/sh
# Every script a skill ships must be run by an anchored path ($SKILL/..., ~/.claude/skills/...,
# or an absolute path), never repo-relative and never via $(dirname "$0"). A skill runs inside
# someone else's repo; a relative path runs whatever that repo put there. AUTHORING.md §11.
# Scans skills/**/*.md for executions of the kit's own scripts. No model calls.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
python3 - "$root" <<'EOF'
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
skills = root / "skills"
scripts = sorted({p.name for p in skills.rglob("*")
                  if p.is_file() and p.suffix in {".py", ".sh", ".mjs", ".js"}})
names = "|".join(re.escape(s) for s in scripts)
token = re.compile(r"""(?P<path>[^\s`"'()\[\]]*(?:%s))\b""" % names)
interp = re.compile(r"""(?<![\w-])(?:python3?|bash|sh|node|zsh)\s+["']?$""")
run_word = re.compile(r"""(?:^|\s)[Rr]un\s+`$""")
bad = []

def anchored(path):
    return ("$SKILL" in path or "skill-dir>" in path
            or path.startswith(("~/.claude/skills/", "/")))

for md in sorted(skills.rglob("*.md")):
    fenced = False
    for n, line in enumerate(md.read_text(encoding="utf-8").splitlines(), 1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if re.search(r"""dirname\s+["']?\$0""", line):
            bad.append(f"{md.relative_to(root)}:{n}: $(dirname \"$0\") names the shell, not the skill")
        for m in token.finditer(line):
            path, before = m.group("path"), line[:m.start()]
            by_interp = interp.search(before)
            executed = (by_interp or run_word.search(before)
                        or (fenced and before.strip() in ("", "$")))
            # A bare name run as `check.py` is a PATH lookup; `python3 check.py` reads the cwd.
            relative = "/" in path or by_interp
            if executed and relative and not anchored(path):
                bad.append(f"{md.relative_to(root)}:{n}: unanchored script path {m.group('path')}")

for b in bad:
    print(b)
print(f"anchoring: {len(scripts)} shipped scripts, {len(bad)} unanchored calls")
sys.exit(1 if bad else 0)
EOF
