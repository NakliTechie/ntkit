#!/usr/bin/env python3
"""failures — list a session's failed tool calls by shape and merge them into plan/failures.md.

The next session reads plan/failures.md before acting, so it does not repeat a command that an
earlier session already saw fail. One line per failure shape (tool, command word, error):

  - Bash `git push` → error: failed to push some refs to <url> · seen 3 · last 2026-11-10 · fix: pull --rebase first  [at: session:<id>]

Left out, because they say nothing about the environment:
  - permission prompts the person declined, and calls the person rejected;
  - a bare non-zero exit with no error text (grep finding nothing exits 1).

Reads a Claude Code session transcript (JSONL). Another host's transcript is not parsed: write its
lines by hand in the same shape. The `fix:` field is left as `?` for the agent to fill from the
conversation; an existing fix is never overwritten. The script never deletes a line.

Usage: failures.py <transcript.jsonl | session-id> [--ledger plan/failures.md] [--write]
  A session id is looked up as <id>.jsonl under NT_TRANSCRIPTS (default ~/.claude/projects).
  Without --write it prints what it would merge and changes nothing.
Exit 0 ran · 2 could not run. Standard library only.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

REJECTED = re.compile(r"^(permission to use|the user doesn't want|user rejected|the user rejected|"
                      r"request interrupted|this command requires approval)", re.I)
EXIT = re.compile(r"^exit code \d+\s*$", re.I)
ERRORISH = re.compile(r"error|not found|does not exist|no such|denied|failed|failure|refused|invalid|cannot|can't|"
                      r"unknown|unmatched|fatal|exception|traceback|usage:|not supported|timed out|"
                      r"timeout|not allowed|missing|unrecognized|bad |forbidden|\b4\d\d\b|\b5\d\d\b", re.I)
LINE = re.compile(r"^- (?P<tool>\S+) `(?P<cmd>[^`]*)` → (?P<err>.*?) · seen (?P<n>\d+) · "
                  r"last (?P<last>\S+) · fix: (?P<fix>.*?)(?:  \[at: (?P<at>[^\]]*)\])?\s*$")
HEADER = ("# Failures and quirks\n\n"
          "One line per failure shape that a session hit. Read before acting; fill `fix:` when you learn it.\n"
          "Written by /windup-nt (`failures.py --write`); a person may add or edit lines.\n\n")
KEEP_SESSIONS = 3


def norm(text: str) -> str:
    """Fold the parts of an error that change between runs, so one cause gives one shape."""
    t = re.sub(r"https?://[^\s'\"`<>)]+", "<url>", text)
    t = re.sub(r"(?<![\w<])(?:~|/)[^\s:'\"`,)]+", "<path>", t)
    t = re.sub(r"\b[0-9a-f]{7,64}\b", "<id>", t)
    t = re.sub(r"\d+", "N", t)
    t = t.replace("`", "'")
    return re.sub(r"\s+", " ", t).strip()[:140]


def command_word(cmd: str) -> str:
    """The program a shell command ran, with its subcommand: `git push`, `npm run`, `python3 x.py`."""
    parts = re.split(r"\s*(?:&&|\|\||;|\|)\s*", re.sub(r"\$\(|`", " ", cmd.strip()))
    for part in parts:
        words = part.split()
        while words and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]):   # leading var=value
            words = words[1:]
        while words and words[0] in ("do", "then", "else", "time", "nohup", "sudo", "!"):
            words = words[1:]
        if not words or words[0] in ("cd", "set", "export", "source", ".", "sleep", "echo", "true",
                                     "for", "if", "while", "until", "done", "fi", "esac", "case"):
            continue
        w = [os.path.basename(words[0])]
        if len(words) > 1 and re.match(r"^[a-z][\w.-]*$", words[1]):
            w.append(os.path.basename(words[1]))
        return " ".join(w).replace("`", "'")[:60]
    return "sh"


def error_line(text: str) -> str | None:
    """The line that carries the error, or None when there is none worth keeping."""
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    if not lines:
        return None
    if REJECTED.match(lines[0]):
        return None
    if EXIT.match(lines[0]):
        lines = lines[1:]
    hits = [l for l in lines if ERRORISH.search(l)]
    if not hits:
        return None
    return norm(hits[-1])


def result_text(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(x.get("text", "") for x in content if isinstance(x, dict))
    return ""


def read_transcript(path: Path) -> tuple[str, list[dict]]:
    calls: dict[str, tuple[str, str]] = {}
    found: list[dict] = []
    session = path.stem
    for raw in path.open(errors="replace"):
        try:
            o = json.loads(raw)
        except ValueError:
            continue
        session = o.get("sessionId") or session
        content = (o.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for it in content:
            if not isinstance(it, dict):
                continue
            if it.get("type") == "tool_use":
                inp = it.get("input") or {}
                name = it.get("name", "?")
                cmd = command_word(inp["command"]) if name == "Bash" and "command" in inp else ""
                calls[it.get("id", "")] = (name, cmd)
            elif it.get("type") == "tool_result" and it.get("is_error"):
                err = error_line(result_text(it.get("content")))
                if err is None:
                    continue
                tool, cmd = calls.get(it.get("tool_use_id", ""), ("?", ""))
                found.append({"tool": tool, "cmd": cmd, "err": err,
                              "date": (o.get("timestamp") or "")[:10] or "?"})
    return session, found


def resolve(arg: str) -> Path | None:
    p = Path(arg).expanduser()
    if p.is_file():
        return p
    base = Path(os.environ.get("NT_TRANSCRIPTS", "~/.claude/projects")).expanduser()
    if "/" not in arg:
        for c in [base / f"{arg}.jsonl", *base.glob(f"*/{arg}.jsonl")]:
            if c.is_file():
                return c
    return None


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="failures", description=__doc__.splitlines()[0])
    ap.add_argument("transcript")
    ap.add_argument("--ledger", default="plan/failures.md")
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args(argv)
    path = resolve(a.transcript)
    if path is None:
        print(f"failures: no transcript {a.transcript}", file=sys.stderr)
        return 2
    session, found = read_transcript(path)

    shapes: dict[tuple[str, str, str], dict] = {}
    for f in found:
        k = (f["tool"], f["cmd"], f["err"])
        s = shapes.setdefault(k, {"n": 0, "last": f["date"]})
        s["n"] += 1
        s["last"] = max(s["last"], f["date"])

    ledger = Path(a.ledger)
    text = ledger.read_text(errors="replace") if ledger.exists() else HEADER
    out, known, seen_here = [], set(), f"session:{session}"
    new_known = 0
    for line in text.splitlines():
        m = LINE.match(line)
        if m:
            k = (m["tool"], m["cmd"], m["err"])
            known.add(k)
            if k in shapes:
                new_known += 1
                ats = [x.strip() for x in (m["at"] or "").split(",") if x.strip()]
                if seen_here not in ats:   # merging the same session twice counts it once
                    n = int(m["n"]) + shapes[k]["n"]
                    ats = (ats + [seen_here])[-KEEP_SESSIONS:]
                    last = max(m["last"], shapes[k]["last"])
                    line = (f"- {m['tool']} `{m['cmd']}` → {m['err']} · seen {n} · last {last} · "
                            f"fix: {m['fix']}  [at: {', '.join(ats)}]")
        out.append(line)
    fresh = [k for k in shapes if k not in known]
    for k in fresh:
        s = shapes[k]
        out.append(f"- {k[0]} `{k[1]}` → {k[2]} · seen {s['n']} · last {s['last']} · fix: ?  [at: {seen_here}]")

    print(f"{len(found)} failed call(s) in {path.name}, {len(shapes)} shape(s): "
          f"{len(fresh)} new, {new_known} already in {ledger}")
    for k in fresh:
        print(f"  new  {k[0]} `{k[1]}` → {k[2]}")
    for k in shapes:
        if k in known:
            print(f"  seen {k[0]} `{k[1]}` → {k[2]}  (an earlier session hit this too)")
    if a.write and shapes:
        ledger.parent.mkdir(parents=True, exist_ok=True)
        ledger.write_text("\n".join(out).rstrip("\n") + "\n")
        print(f"wrote {ledger}")
    elif not a.write and shapes:
        print("dry run: add --write to merge")
    return 0


if __name__ == "__main__":
    sys.exit(main())
