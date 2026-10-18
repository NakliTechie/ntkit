#!/usr/bin/env python3
"""Build every installed agent's global instruction file from one preferences folder.

The folder (--dir, else $NT_PREFS_DIR, else ~/.agent-prefs) holds:
  core/*.md      shared sections, joined in filename order into every agent's file
  agents/<x>.md  extras for one agent
  targets.tsv    agent <TAB> global file <TAB> extras name or -
  inbox.md       append-only lines from any agent, copied into every file at once

For each target whose parent folder exists (the agent is installed):
  1. If the live file differs from what this script last wrote, someone edited it by hand.
     Save the edited copy to drift/ and append its added lines to inbox.md.
  2. Write header + core + extras + inbox to the live file.
`{{PREFS_DIR}}` in any source file becomes the folder's path.

Usage: prefs_sync.py [--dir D] [--dry-run | --check] [--push]
  --dry-run  print what would change; write nothing
  --check    exit 0 when every installed agent's file is current, 1 when not; write nothing
  --push     after a commit, git push (default: commit only, when the folder is a git repo)
Exit 2: no preferences folder, or no targets.tsv.
"""
import argparse
import difflib
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

INBOX_HEAD = "# Inbox — append-only, one fact per line, newest last\n"
NOW = datetime.now().astimezone()


def args():
    p = argparse.ArgumentParser(description="Build agents' global instruction files.")
    p.add_argument("--dir", default=os.environ.get("NT_PREFS_DIR", "~/.agent-prefs"))
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--check", action="store_true")
    p.add_argument("--push", action="store_true")
    return p.parse_args()


def tilde(path):
    home = str(Path.home())
    s = str(path)
    return "~" + s[len(home):] if s.startswith(home) else s


class Prefs:
    def __init__(self, root, write):
        self.root, self.write = root, write
        self.state = root / ".state"
        self.inbox = root / "inbox.md"

    def log(self, msg):
        print(f"{NOW:%Y-%m-%d %H:%M} prefs-sync: {msg}")

    def targets(self):
        rows = []
        for line in (self.root / "targets.tsv").read_text().splitlines():
            if line.strip() and not line.startswith("#"):
                agent, path, extra = line.split("\t")
                rows.append((agent, Path(path).expanduser(), extra))
        return rows

    def build(self, agent, extra):
        here = tilde(self.root)
        parts = [f"<!-- Generated for {agent} by prefs-sync from {here}. Do not edit here: edit "
                 f"{here}, or append to {here}/inbox.md. -->\n\n# Preferences for every agent\n"]
        parts += [p.read_text().strip() + "\n" for p in sorted((self.root / "core").glob("*.md"))]
        if extra != "-":
            parts.append((self.root / "agents" / f"{extra}.md").read_text().strip() + "\n")
        if self.inbox.exists():
            body = self.inbox.read_text()
            body = body[len(INBOX_HEAD):] if body.startswith(INBOX_HEAD) else body
            if body.strip():
                parts.append("## Recent additions — inbox, not yet folded into the sections above\n\n"
                             "These are newer than the sections above. Where they disagree, the inbox "
                             "wins.\n\n" + body.strip() + "\n")
        return "\n".join(parts).replace("{{PREFS_DIR}}", here)

    def capture_drift(self, agent, live, last):
        """Save a hand-edited file to drift/ and copy its added lines to the inbox."""
        saved = self.root / "drift" / f"{agent}-{NOW:%Y-%m-%d-%H%M%S}.md"
        blocks, block, removed = [], [], 0
        for line in difflib.ndiff(last.splitlines(), live.splitlines()):
            tag, text = line[:2], line[2:]
            if tag == "+ ":
                block.append(text)
                continue
            if tag == "? ":
                continue
            if block:
                blocks.append(block)
                block = []
            if tag == "- ":
                removed += 1
        if block:
            blocks.append(block)
        out = []
        for blk in blocks:
            text = [t.strip() for t in blk if t.strip()]
            if text:
                out.append(f"- {NOW:%Y-%m-%d} · {agent} (hand edit) · {text[0]}")
                out += [f"  {t}" for t in text[1:]]
        if removed:
            out.append(f"- {NOW:%Y-%m-%d} · {agent} (hand edit) · removed {removed} line(s); "
                       f"see drift/{saved.name} and decide at the next fold")
        self.log(f"{agent}: hand edit found, {len(blocks)} added block(s), {removed} removed line(s)")
        if not self.write:
            return
        saved.parent.mkdir(exist_ok=True)
        saved.write_text(live)
        if out:
            if not self.inbox.exists():
                self.inbox.write_text(INBOX_HEAD)
            with self.inbox.open("a") as f:
                f.write("\n".join(out) + "\n")

    def stale(self):
        """Names of installed agents whose file is missing, hand-edited or out of date."""
        bad = []
        for agent, target, extra in self.targets():
            if not target.parent.exists():
                continue
            if not target.exists() or target.read_text() != self.build(agent, extra):
                bad.append(agent)
        return bad

    def sync(self):
        self.state.mkdir(exist_ok=True) if self.write else None
        rows = self.targets()
        # Pass 1: capture every hand edit first, so pass 2 puts each one into every file.
        for agent, target, _ in rows:
            last_p = self.state / f"{agent}.last"
            if not target.exists():
                continue
            live = target.read_text()
            if last_p.exists():
                if live != last_p.read_text():
                    self.capture_drift(agent, live, last_p.read_text())
            elif live.strip():
                saved = self.root / "drift" / f"{agent}-before-adoption-{NOW:%Y-%m-%d}.md"
                self.log(f"{agent}: adopting existing file; original saved to drift/{saved.name}")
                if self.write:
                    saved.parent.mkdir(exist_ok=True)
                    saved.write_text(live)
        # Pass 2: write every installed agent's file.
        for agent, target, extra in rows:
            if not target.parent.exists():
                continue
            out = self.build(agent, extra)
            if target.exists() and target.read_text() == out:
                continue
            self.log(f"{agent}: writing {tilde(target)} ({len(out.encode())} bytes)")
            if self.write:
                target.write_text(out)
                (self.state / f"{agent}.last").write_text(out)


def git(root, *a):
    return subprocess.run(["git", "-C", str(root), *a], capture_output=True, text=True)


def main():
    a = args()
    root = Path(a.dir).expanduser()
    if not (root / "targets.tsv").is_file():
        print(f"prefs-sync: no preferences folder at {tilde(root)} (targets.tsv missing). "
              "Run /prefs-nt init first.", file=sys.stderr)
        return 2
    prefs = Prefs(root, write=not (a.dry_run or a.check))
    if a.check:
        bad = prefs.stale()
        for name in bad:
            print(f"prefs-sync: {name} is out of date or edited by hand")
        return 1 if bad else 0
    is_git = git(root, "rev-parse", "--git-dir").returncode == 0
    has_remote = is_git and bool(git(root, "remote").stdout.strip())
    if prefs.write and a.push and has_remote:
        git(root, "pull", "--rebase", "--autostash", "-q")
    prefs.sync()
    if prefs.write and is_git:
        git(root, "add", "-A")
        if git(root, "diff", "--cached", "--quiet").returncode:
            git(root, "commit", "-q", "-m", f"prefs-sync {NOW:%Y-%m-%d %H:%M %Z}")
            if a.push and has_remote:
                r = git(root, "push", "-q")
                prefs.log("pushed" if r.returncode == 0 else f"push failed: {r.stderr.strip()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
