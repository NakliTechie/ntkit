#!/usr/bin/env python3
"""Check that every `path:line` pointer in a forward-pass report resolves.

Usage: cite-check.py REPORT [--root DIR]

Run from the audited project's root (or pass --root). Fails when a pointer names
a file that does not exist or a line past the end of the file, and when a finding
entry (`**H3** [Security] ...`) cites no `path:line` at all. It checks that the
place exists, not what the code there does.

Exit 0: every pointer resolves. Exit 1: failures, one per line. Exit 2: usage.
Stdlib only. traces-nt's cite_check.py imports resolve() and line_count() from here, so both
skills hold a pointer to one rule.
"""

import argparse
import os
import re
import sys

POINTER = re.compile(
    r"(?<![\w/.@:~-])"           # not the tail of a longer token, URL, or host:port
    r"(~?[\w@.\-/]*[A-Za-z][\w@.\-/]*)"  # the path: needs at least one letter
    r":(\d+)(?:[-–](\d+))?"  # :line or :start-end
)
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")  # [shown](target): check the target only
FINDING = re.compile(
    r"^\s*(?:[-*]\s+)?(?:\[[ x~]\]\s+)?\*\*(?:C|H|M|L|S|SB|T|AR|W)\d+\*\*\s*\["
)
CODE_EXT = {
    "c", "cc", "cfg", "cjs", "cpp", "cs", "css", "dart", "env", "ex", "exs", "go",
    "gradle", "h", "hpp", "html", "ini", "java", "js", "json", "jsx", "kt", "lock",
    "lua", "md", "mjs", "php", "py", "rb", "rs", "scala", "sh", "sql", "svelte",
    "swift", "tf", "toml", "ts", "tsx", "txt", "vue", "xml", "yaml", "yml", "zig",
}
BARE_NAME = re.compile(r"\.\w.*|[A-Z][A-Za-z]*file|LICENSE|README|CODEOWNERS|NOTICE|VERSION")


def looks_like_path(token, exists):
    """A token is checked when it has a slash, exists, ends in a known extension, or is a
    dotfile or a known extensionless file name (Dockerfile, Makefile, LICENSE)."""
    if "/" in token or exists or BARE_NAME.fullmatch(token):
        return True
    _, ext = os.path.splitext(token)
    return ext[1:].lower() in CODE_EXT


def line_count(path, cache):
    if path not in cache:
        with open(path, "rb") as fh:
            cache[path] = sum(1 for _ in fh)
    return cache[path]


def resolve(root, rel, start, end, cache, contained=False):
    """Check that rel:start[-end] names lines that exist in a file under root.

    Returns (problem, total): problem is None when it resolves, else "outside" (contained
    is set and the path leaves root), "missing" (no such file) or "range" (a line before 1
    or past the end); total is the file's line count when known.
    """
    full = os.path.join(root, os.path.expanduser(rel))
    if contained:
        top = os.path.realpath(root)    # realpath, so a symlink inside cannot point outside
        if os.path.commonpath([top, os.path.realpath(full)]) != top:
            return "outside", None
    if not os.path.isfile(full):
        return "missing", None
    total = line_count(full, cache)
    if start < 1 or (end or start) > total:
        return "range", total
    return None, total


def check(report, root):
    failures, checked, counts = [], 0, {}
    with open(report, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    for n, text in enumerate(lines, 1):
        found = 0
        plain = LINK.sub(lambda m: m.group(1) if POINTER.search(m.group(1)) else m.group(0), text)
        for word in plain.split():
            if "://" in word:
                continue
            for m in POINTER.finditer(word):
                token, start, end = m.group(1), int(m.group(2)), m.group(3)
                token = token.rstrip(".")
                exists = os.path.isfile(os.path.join(root, os.path.expanduser(token)))
                if not looks_like_path(token, exists):
                    continue
                found += 1
                checked += 1
                pointer = f"{token}:{m.group(2)}" + (f"-{end}" if end else "")
                problem, total = resolve(root, token, start, int(end) if end else None, counts)
                if problem == "missing":
                    failures.append(f"{report}:{n}: {pointer} - no such file")
                elif problem == "range":
                    failures.append(f"{report}:{n}: {pointer} - file has {total} lines")
        if found == 0 and FINDING.match(text):
            failures.append(f"{report}:{n}: finding cites no path:line")
    return checked, failures


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("report")
    ap.add_argument("--root", default=".", help="project root the pointers are relative to")
    args = ap.parse_args()
    if not os.path.isfile(args.report):
        print(f"cite-check: no report at {args.report}", file=sys.stderr)
        return 2
    checked, failures = check(args.report, args.root)
    for f in failures:
        print(f)
    print(f"cite-check: {checked} pointers, {len(failures)} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
