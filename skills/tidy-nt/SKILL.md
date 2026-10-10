---
description: "Mid-session cleanup of what this session created: files, temp dirs, servers. Lists first, deletes by name."
argument-hint: "[list | apply | log <path> <purpose>]"
allowed-tools: ["Bash", "Glob", "Read", "Write"]
entry: "any state; run mid-session, after a long run, or before /windup-nt"
exit: "this session's artifacts listed with size and file count; confirmed ones moved to the Trash by name; free space reported"
writes: "the session ledger only; deletes only items this session created"
---

Clear out what **this session** made. `/reclaim-nt` sweeps a whole project for old weights and archives; this command knows only the current session's output. It never touches another project's files, a running app's profile, or a shared cache that predates the session.

`$ARGUMENTS`: empty or `list` → inventory and propose. `apply` → delete the confirmed items. `log <path> <purpose>` → append one ledger line and stop.

## The ledger

A JSONL file at `<scratchpad>/ledger.jsonl` (the session scratchpad directory; if none, `${TMPDIR:-/tmp}/ntkit-ledger-<project>.jsonl`). One line per artifact: `{"path": "...", "bytes": N, "files": N, "purpose": "...", "keep_until": "..."}`. Any step that creates something over 50 MB or 1,000 files appends a line when it creates it: a downloaded model, a copied profile, a build directory, a temp test-data directory, a worktree, a started server. The ledger is the primary signal. The checks below find what it missed.

## Step 1 — Inventory

Collect candidates from four signals and merge them by path:

1. **Ledger lines** with a path that still exists.
2. **Files newer than the session start** in known roots: the scratchpad, `/private/tmp/claude-501/<project>/`, the project's git-ignored directories (`git status --ignored --short`), and tool output folders the session ran (`snapshots/`, `renders/`, `.artifacts/`, `tmp/`).
3. **Processes started this session**: preview servers, dev servers, background tasks, launchd agents (`pgrep -fl`, `/tasks`).
4. **Work folders touched by background agents.** Re-list every folder a subagent wrote to after they finish. A stale worker can recreate a deleted file.

For each candidate record `path`, `bytes`, **file count** (`find <dir> -type f | wc -l`), birth date (`stat -f %SB`), and source signal. Count files as well as bytes: 600,000 small files hide under a byte threshold.

## Step 2 — Classify

- **Mine, disposable** — regenerable output (contact sheets, worker packets, caches this session wrote, rejected samples). Propose deletion.
- **Mine, keep** — a deliverable, source, or input needed to re-run (the final render, narration audio, fonts the project loads). Keep and say why.
- **Not mine** — birth date before the session start, another project's path, a shared cache another tool owns, anything under a running app's profile. Report with name and size. Never propose deletion.
- **Flood** — over 20,000 files in one directory. Flag it first, whatever its size, and name the script that wrote it when `git log` shows one.

## Step 3 — Propose, then delete by name

Print one table: path · size · files · class · why. Then wait for the user to confirm `apply`. On `apply`:

- Delete each confirmed item **by its exact path**. Use `rm` for files this session wrote, `rm -r` for a directory named in the table. Never loop "delete all" over a directory, an origin, a port, a cache folder or an HF folder.
- Stop a server by its PID from the process list, never by name pattern.
- Deleting another project's files, a model checkpoint, or anything git-tracked needs the user's explicit say-so for that item.

## Step 4 — Report

```
Tidied <project>.
Removed: <N> items, <MB> MB, <files> files — <name · size> for each
Kept: <name · size · why>, …
Not mine, left alone: <name · size · birth date>, …
Stopped: <server/PID> …
Free space: <df -h / Avail>
```

Mark the ledger lines for removed items `removed`. Do not write to `plan/`, do not commit, do not push. If the session made nothing worth removing, say so in one line.
