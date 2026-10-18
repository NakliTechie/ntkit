#!/usr/bin/env python3
"""Build every installed agent's global instruction file from one preferences folder.

The folder (--dir, else $NT_PREFS_DIR, else ~/.agent-prefs) holds:
  core/*.md      shared sections, joined in filename order into every agent's file
  agents/<x>.md  extras for agent <x>, used whenever the file exists
  targets.tsv    agent <TAB> global file [<TAB> shadow file]
                 A shadow file, when it exists and is not empty, makes the agent ignore the global
                 file (Codex's AGENTS.override.md); --check then fails for that agent.
                 Paths start with ~ or $VAR; CODEX_HOME defaults to ~/.codex.
  inbox.md       append-only lines from any agent, copied into every file at once

For each target whose parent folder exists (the agent is installed):
  1. If the live file differs from what this script last wrote, someone edited it by hand.
     Save the edited copy to drift/ and append its added lines to inbox.md.
  2. Write header + core + extras + inbox to the live file, atomically. A file that changed
     after step 1 read it is left alone this run and captured on the next.
`{{PREFS_DIR}}` in any source file becomes the folder's path.

Usage: prefs_sync.py [--dir D] [--dry-run | --check] [--push]
  --dry-run  print what would change; write nothing
  --check    exit 0 when every installed agent's file is current and not shadowed; write nothing
  --push     push the folder's git repo (default: commit only)
Git runs only when the folder is the root of its own repo, and stages only that folder.
Exit 0 ok · 1 check failed, or git failed · 2 bad folder or targets.tsv · 3 another sync is running.
"""
import argparse
import difflib
import fcntl
import os
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

INBOX_HEAD = "# Inbox — append-only, one fact per line, newest last\n"
NOW = datetime.now().astimezone()
ENV_DEFAULTS = {"CODEX_HOME": "~/.codex"}


def args():
    p = argparse.ArgumentParser(description="Build agents' global instruction files.")
    p.add_argument("--dir", default=os.environ.get("NT_PREFS_DIR", "~/.agent-prefs"))
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--check", action="store_true")
    p.add_argument("--push", action="store_true")
    return p.parse_args()


def tilde(path):
    s = str(path)
    for home in (str(Path.home().resolve()), str(Path.home())):
        if s == home or s.startswith(home + "/"):
            return "~" + s[len(home):]
    return s


def expand(raw):
    env = dict(os.environ)
    for k, v in ENV_DEFAULTS.items():
        env.setdefault(k, os.path.expanduser(v))
    text = raw
    for k in sorted(env, key=len, reverse=True):
        text = text.replace("${%s}" % k, env[k]).replace("$" + k, env[k])
    path = Path(text).expanduser()
    if not path.is_absolute():
        raise ValueError(f"target path is not absolute after expansion: {raw}")
    return path


def unique(path):
    """A path that does not exist yet: path, else path-2, path-3, ..."""
    n, cand = 1, path
    while cand.exists():
        n += 1
        cand = path.with_name(f"{path.stem}-{n}{path.suffix}")
    return cand


def save_new(path, text):
    """Create a new file, never overwriting one that exists."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path = unique(path)
    with open(path, "x") as f:
        f.write(text)
    return path


def atomic_write(path, text, expected=None):
    """Replace a file's content in one step. A symlink stays a link: its target is replaced.
    With `expected`, give up (return False) when the file no longer holds it. The re-read sits
    just before the replace, so only an edit inside that last moment can still be overwritten."""
    real = path.resolve() if path.is_symlink() else path
    fd, tmp = tempfile.mkstemp(dir=str(real.parent), prefix=f".{real.name}.")
    with os.fdopen(fd, "w") as f:
        f.write(text)
    if real.exists():
        os.chmod(tmp, real.stat().st_mode & 0o777)
    now = real.read_text() if real.exists() else None
    if expected is not None and now != expected:
        os.unlink(tmp)
        return False
    os.replace(tmp, real)
    return True


class Prefs:
    def __init__(self, root, write):
        self.root, self.write = root, write
        self.state = root / ".state"
        inbox_p = root / "inbox.md"
        self.inbox_p = inbox_p
        self.inbox = inbox_p.read_text() if inbox_p.exists() else INBOX_HEAD
        self.new_entries = []

    def log(self, msg):
        print(f"{NOW:%Y-%m-%d %H:%M} prefs-sync: {msg}")

    def targets(self):
        rows = []
        for line in (self.root / "targets.tsv").read_text().splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            cols = line.split("\t")
            agent, path = cols[0], expand(cols[1])
            col3 = cols[2].strip() if len(cols) > 2 else "-"
            if col3 not in ("", "-") and not col3.startswith(("~", "$", "/")):
                raise ValueError(f"targets.tsv row '{agent}': column 3 is a shadow-file path, not an "
                                 f"extras name ('{col3}'). Extras now come from agents/{agent}.md; "
                                 "put - in column 3")
            shadow = expand(col3) if col3 not in ("", "-") else None
            rows.append((agent, path, shadow))
        return rows

    def build(self, agent):
        here = tilde(self.root)
        parts = [f"<!-- Generated for {agent} by prefs-sync from {here}. Do not edit here: edit "
                 f"{here}, or append to {here}/inbox.md. -->\n\n# Preferences for every agent\n"]
        parts += [p.read_text().strip() + "\n" for p in sorted((self.root / "core").glob("*.md"))]
        extra = self.root / "agents" / f"{agent}.md"
        if extra.is_file():
            parts.append(extra.read_text().strip() + "\n")
        body = self.inbox[len(INBOX_HEAD):] if self.inbox.startswith(INBOX_HEAD) else self.inbox
        if body.strip():
            parts.append("## Recent additions — inbox, not yet folded into the sections above\n\n"
                         "These are newer than the sections above. Where they disagree, the inbox "
                         "wins.\n\n" + body.strip("\n") + "\n")
        return "\n".join(parts).replace("{{PREFS_DIR}}", here)

    def capture_drift(self, agent, live, last):
        """Save a hand-edited file to drift/ and add its added blocks, formatting kept, to the inbox."""
        blocks, block, removed = [], [], 0
        for line in difflib.ndiff(last.splitlines(), live.splitlines()):
            tag, text = line[:2], line[2:]
            if tag == "? ":
                continue
            if tag == "+ ":
                block.append(text)
                continue
            if block:
                blocks.append(block)
                block = []
            if tag == "- ":
                removed += 1
        if block:
            blocks.append(block)
        name = f"{agent}-{NOW:%Y-%m-%d-%H%M%S}.md"
        saved = self.root / "drift" / name
        if self.write:
            saved = save_new(saved, live)
        out = []
        for blk in blocks:
            while blk and not blk[0].strip():
                blk = blk[1:]
            while blk and not blk[-1].strip():
                blk = blk[:-1]
            if blk:
                out.append(f"- {NOW:%Y-%m-%d} · {agent} (hand edit):")
                out += [("    " + t) if t.strip() else "" for t in blk]
        if removed:
            out.append(f"- {NOW:%Y-%m-%d} · {agent} (hand edit) · removed {removed} line(s); "
                       f"see drift/{saved.name} and decide at the next fold")
        self.log(f"{agent}: hand edit found, {len(blocks)} added block(s), {removed} removed line(s)")
        if out:
            self.inbox = self.inbox.rstrip("\n") + "\n" + "\n".join(out) + "\n"
            self.new_entries += out

    def shadowed(self, shadow):
        return shadow is not None and shadow.is_file() and shadow.read_text().strip() != ""

    def stale(self):
        """Installed agents whose file is missing, edited, out of date, or shadowed."""
        bad = []
        for agent, target, shadow in self.targets():
            if not target.parent.exists():
                continue
            if not target.exists() or target.read_text() != self.build(agent):
                bad.append(f"{agent} is out of date or edited by hand")
            if self.shadowed(shadow):
                bad.append(f"{agent} ignores its file because {tilde(shadow)} is not empty")
        return bad

    def sync(self):
        if self.write:
            self.state.mkdir(exist_ok=True)
        rows = self.targets()
        seen = {}
        # Pass 1: capture every hand edit first, so pass 2 puts each one into every file.
        for agent, target, shadow in rows:
            if not target.exists():
                continue
            live = target.read_text()
            seen[agent] = live
            last_p = self.state / f"{agent}.last"
            if last_p.exists():
                if live != last_p.read_text():
                    self.capture_drift(agent, live, last_p.read_text())
            elif live.strip():
                name = f"{agent}-before-adoption-{NOW:%Y-%m-%d}.md"
                saved = save_new(self.root / "drift" / name, live) if self.write else Path(name)
                self.log(f"{agent}: adopting existing file; original saved to drift/{saved.name}")
        if self.write and self.new_entries:
            # Append, never rewrite: another agent may have added a line since we read the inbox.
            if not self.inbox_p.exists():
                self.inbox_p.write_text(INBOX_HEAD)
            with self.inbox_p.open("a") as f:
                if not self.inbox_p.read_text().endswith("\n"):
                    f.write("\n")
                f.write("\n".join(self.new_entries) + "\n")
        # Pass 2: write every installed agent's file.
        for agent, target, shadow in rows:
            if not target.parent.exists():
                continue
            if self.shadowed(shadow):
                self.log(f"{agent}: WARNING {tilde(shadow)} is not empty, so {agent} ignores "
                         f"{tilde(target)}")
            out = self.build(agent)
            now = target.read_text() if target.exists() else None
            if now != seen.get(agent):
                self.log(f"{agent}: file changed during this sync; left alone until the next run")
                continue
            if now != out:
                self.log(f"{agent}: writing {tilde(target)} ({len(out.encode())} bytes)")
                if self.write and not atomic_write(target, out, expected=now):
                    self.log(f"{agent}: file changed during this sync; left alone until the next run")
                    continue
            if self.write:
                (self.state / f"{agent}.last").write_text(out)


def git(root, *a):
    return subprocess.run(["git", "-C", str(root), *a], capture_output=True, text=True)


def upstream(root):
    return git(root, "rev-parse", "--abbrev-ref", "@{u}").returncode == 0


def push_remote(root):
    """Git's own choice of remote for a first push: pushDefault, else the only remote, else origin."""
    configured = git(root, "config", "--get", "remote.pushDefault").stdout.strip()
    remotes = git(root, "remote").stdout.split()
    if configured:
        return configured
    return remotes[0] if len(remotes) == 1 else "origin"


def own_repo(root):
    r = git(root, "rev-parse", "--show-toplevel")
    return r.returncode == 0 and Path(r.stdout.strip()).resolve() == root


def main():
    a = args()
    root = Path(a.dir).expanduser().resolve()
    if not (root / "targets.tsv").is_file():
        print(f"prefs-sync: no preferences folder at {tilde(root)} (targets.tsv missing). "
              "Run /prefs-nt init first.", file=sys.stderr)
        return 2
    write = not (a.dry_run or a.check)
    try:
        prefs = Prefs(root, write)
        prefs.targets()
    except ValueError as e:
        print(f"prefs-sync: {e}", file=sys.stderr)
        return 2
    if a.check:
        bad = prefs.stale()
        for line in bad:
            print(f"prefs-sync: {line}")
        return 1 if bad else 0
    lock = None
    if write:
        (root / ".state").mkdir(exist_ok=True)
        lock = open(root / ".state" / "lock", "w")
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            prefs.log("another sync is running; exiting")
            return 3
    repo = own_repo(root)
    remote = repo and bool(git(root, "remote").stdout.strip())
    if write and not repo and git(root, "rev-parse", "--git-dir").returncode == 0:
        prefs.log("the folder sits inside another repo; skipping git (give it its own repo)")
    if write and repo:
        if git(root, "diff", "--name-only", "--diff-filter=U").stdout.strip():
            prefs.log("unresolved merge conflicts in the folder; fix them first")
            return 1
        if a.push and remote and upstream(root):
            r = git(root, "pull", "--rebase", "--autostash", "-q")
            if r.returncode:
                prefs.log(f"git pull failed; nothing written: {r.stderr.strip()}")
                return 1
        prefs = Prefs(root, write)  # re-read the inbox the pull may have changed
    prefs.sync()
    if not (write and repo):
        return 0
    r = git(root, "add", "-A", "--", ".")
    if r.returncode:
        prefs.log(f"git add failed: {r.stderr.strip()}")
        return 1
    if git(root, "diff", "--cached", "--quiet").returncode:
        r = git(root, "commit", "-q", "-m", f"prefs-sync {NOW:%Y-%m-%d %H:%M %Z}")
        if r.returncode:
            prefs.log(f"git commit failed: {r.stderr.strip() or r.stdout.strip()}")
            return 1
    if a.push and remote:
        if upstream(root):
            r = git(root, "push", "-q")
        else:
            r = git(root, "push", "-q", "-u", push_remote(root), "HEAD")
        if r.returncode:
            prefs.log(f"git push failed: {r.stderr.strip()}")
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
