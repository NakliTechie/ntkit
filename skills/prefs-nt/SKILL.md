---
description: "One preferences folder you own; builds every coding agent's global instruction file from it."
argument-hint: "[init | sync | fold | schedule | unschedule] [dir=<path>] [--push]   e.g. init dir=~/Code/prefs"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob"]
entry: "init: no preferences folder yet. sync, fold, schedule: a preferences folder holding targets.tsv"
exit: "`python3 ~/.claude/skills/prefs-nt/bin/prefs_sync.py --dir <folder> --check` exits 0"
writes: "nothing in plan/; the preferences folder, and each installed agent's global file listed in its targets.tsv"
---

Every new coding agent asks the same things again: who you are, how you write, how you work. This
command keeps the answers in one folder of plain markdown files that you own. It builds each installed
agent's global instruction file from them: Claude Code, Codex, Gemini CLI, opencode, goose and amp.
Agents write back through an append-only inbox, so a preference one agent learns reaches the others at
the next sync. Project facts stay in each repo's `plan/` folder; this folder holds what is true in every
repo.

## Inputs (defaults announced at the start of the run)

| Input | Default | Effect |
|---|---|---|
| mode (`$ARGUMENTS`) | `sync` | `init`, `sync`, `fold`, `schedule` or `unschedule`; see the phases below |
| `dir=<path>` | `$NT_PREFS_DIR`, else `~/.agent-prefs` | The preferences folder; pass it to the script as `--dir`. Set `NT_PREFS_DIR` in your shell profile to keep the folder in a backed-up repo |
| `--push` (sync and schedule) | off | Push the folder's git repo after a commit. Pushing is outward-facing, so it is granted per run |

## The folder

| Path | Holds |
|---|---|
| `core/*.md` | Shared sections, joined in filename order into every agent's file |
| `agents/<name>.md` | Extras for one agent only (its tool names, its memory habits) |
| `targets.tsv` | `agent <TAB> global file <TAB> extras name or -`. Add a row to add an agent |
| `inbox.md` | Append-only lines from any agent. Copied into every file at once; folded into `core/` later |
| `drift/` | Copies of generated files that someone edited by hand, saved before the overwrite |

A generated file is never edited in place. When an agent or a person edits one, the next sync saves the
edited copy to `drift/` and moves the added lines into `inbox.md`, so nothing is lost.

## Phases

| Mode | Outcome | Read |
|---|---|---|
| `init` | The folder exists, the agents' current global files are saved in `drift/`, and `core/` holds a draft built from them. Agent files are not yet overwritten | `references/init.md` |
| `sync` | Every installed agent's global file matches the folder; hand edits are in the inbox | none: run `python3 ~/.claude/skills/prefs-nt/bin/prefs_sync.py --dir <folder>` (add `--push` only when granted) and report its output |
| `fold` | Inbox lines live in the right `core/` or `agents/` file, contradictions are listed for the owner, and a sync has run | `references/fold.md` |
| `schedule` | A recurring job runs sync every 15 minutes | `references/schedule.md` |
| `unschedule` | That job is removed | `references/schedule.md` |

## Guards and stop-lines

- `sync`, `fold` or `schedule` with no `targets.tsv` in the folder: stop and say "no preferences folder
  at <path>; run `/prefs-nt init` first". The script exits 2 in the same case.
- `init` when the folder already holds `targets.tsv`: stop. Never overwrite an existing folder.
- `init` never overwrites an agent's global file. The first `sync` does, after the owner has read the
  draft. Its first run saves every existing file to `drift/<agent>-before-adoption-<date>.md`.
- `fold` never resolves a contradiction. It keeps both rules, marks the new one, and lists it.
- Never write a secret (key, token, password) into the folder. Name where the secret lives instead.
- Push only with `--push`. Never force-push.

## Example

```
/prefs-nt init        # draft core/ from the files your agents already have
/prefs-nt sync        # after reading the draft: write every agent's file
/prefs-nt schedule    # keep them in step every 15 minutes
/prefs-nt fold        # weekly, or when the inbox grows: sort new lines into core/
```

## What stays

`schedule` leaves a launchd agent (macOS) or a crontab line (Linux) that runs after this command
ends. `/prefs-nt unschedule` removes it. The folder and the generated files stay; to stop using this,
run `unschedule`, then restore each agent's file from `drift/<agent>-before-adoption-<date>.md`.
