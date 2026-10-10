#!/usr/bin/env python3
"""Check a /traces-nt findings file against the tracelens archive.

Usage: cite_check.py <findings.md> [--home <tracelens data home>]
Home: --home, else $TRACELENS_HOME, else the cwd. Citations resolve under <home>/archive.

Each "## F<n>" section must have:
  - at least one evidence pointer `<claude|codex>/<path>.jsonl:<line>` that exists in the archive
    and whose line number is within the file;
  - a "Fix target:" line whose type is one of FIX_TYPES;
  - a "Measure:" line.
Every pointer anywhere in the file must resolve. Exit 0 when all hold, 1 otherwise, 2 on usage error.
"""

import os
import re
import sys

FIX_TYPES = {"claude-md", "playbook", "skill", "allow-rule", "task-prompt", "tool-bug", "none"}
POINTER = re.compile(r"`((?:claude|codex)/[^`\s]+?\.jsonl):(\d+)`")


def count_lines(path, cache={}):
    if path not in cache:
        with open(path, "rb") as f:
            cache[path] = sum(1 for _ in f)
    return cache[path]


def main(argv):
    args = argv[1:]
    home = None
    if "--home" in args:
        i = args.index("--home")
        home = args[i + 1] if i + 1 < len(args) else None
        del args[i:i + 2]
    if len(args) != 1 or home == "":
        print(__doc__.strip().splitlines()[2])
        return 2
    home = home or os.environ.get("TRACELENS_HOME") or os.getcwd()
    archive = os.path.join(os.path.expanduser(home), "archive")
    if not os.path.isdir(archive):
        print(f"no archive at {archive}: set TRACELENS_HOME or pass --home")
        return 2
    text = open(args[0], encoding="utf-8").read()

    failures, n_cites = [], 0
    for rel, line in POINTER.findall(text):
        n_cites += 1
        path = os.path.join(archive, rel)
        if not os.path.isfile(path):
            failures.append(f"{rel}:{line}: file not in archive")
        elif not 1 <= int(line) <= count_lines(path):
            failures.append(f"{rel}:{line}: line past the end ({count_lines(path)} lines)")

    sections = re.split(r"^## (F\d+)\b", text, flags=re.M)
    findings = list(zip(sections[1::2], sections[2::2]))
    for name, body in findings:
        if not POINTER.search(body):
            failures.append(f"{name}: no evidence pointer")
        m = re.search(r"^- Fix target:\s*([\w-]+)", body, re.M)
        if not m:
            failures.append(f"{name}: no 'Fix target:' line")
        elif m.group(1) not in FIX_TYPES:
            failures.append(f"{name}: fix target '{m.group(1)}' not in {sorted(FIX_TYPES)}")
        if not re.search(r"^- Measure:\s*\S", body, re.M):
            failures.append(f"{name}: no 'Measure:' line")
    if not findings:
        failures.append("no '## F<n>' findings")

    for f in failures:
        print("FAIL", f)
    print(f"{len(findings)} findings, {n_cites} citations, {len(failures)} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
