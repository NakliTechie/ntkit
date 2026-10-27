#!/bin/sh
# ntkit is public: shipped files must not name anyone's local paths or private setup.
# Fails on a home-directory path (/Users/<name>, /home/<name>) and on a personal folder
# layout under the home directory (a capitalised top-level folder such as a code or projects
# folder). Standard OS locations (Library, Applications, dot-folders) are generic and allowed. Owners can add
# their own private words through NTKIT_PRIVATE_TERMS (an extended regex, e.g. a username);
# the public test never names them. Binary files are skipped; copyright lines are allowed.
set -eu
command -v git >/dev/null || { echo "git not found"; exit 77; }
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git checkout"; exit 77; }
git ls-files -z | python3 -c '
import os, re, sys
files = [f for f in sys.stdin.read().split("\0") if f]
skip = re.compile(r"\.(png|jpe?g|gif|mp4|webm|mov|svg|ico|pdf|woff2?|ttf|mp3|wav|m4a)$")
home = re.compile(r"(?<![\w$}/])/(Users|home)/[A-Za-z]")
layout = re.compile(r"~/(?!Library/|Applications/|Desktop/|Downloads/|Documents/)[A-Z][A-Za-z]+/")
extra = os.environ.get("NTKIT_PRIVATE_TERMS")
extra = re.compile(extra) if extra else None
allow = re.compile(r"MIT ©|Copyright \(c\)|Never use absolute paths \(starting with `/Users/\.\.\.`\)")
hits = []
for f in files:
    if skip.search(f) or not os.path.isfile(f):
        continue
    try:
        lines = open(f, encoding="utf-8").read().splitlines()
    except UnicodeDecodeError:
        continue
    for n, line in enumerate(lines, 1):
        if allow.search(line):
            continue
        if home.search(line) or layout.search(line) or (extra and extra.search(line)):
            hits.append(f"{f}:{n}: {line.strip()[:160]}")
if hits:
    print("local paths or private terms in shipped files:")
    print("\n".join(hits))
    sys.exit(1)
print("ok")
'
