---
description: Multi-project status — scan your projects for plan/ folders, report active / idle / stale with top chunk and pending counts
argument-hint: "[scan root, default ~/code]"
---

Show a cross-project status snapshot. Use at the start of a day or when deciding what to work on next.

**Scan root:** use `$ARGUMENTS` if given, otherwise `~/code`. Edit that default to match where you keep your repos (e.g. `~/projects`, `~/src`, `~/dev`). Call the resolved value `$ROOT` below.

## Step 1: Enumerate projects

Find every `plan/` folder up to 3 levels deep under `$ROOT`:

```bash
find "$ROOT" -maxdepth 3 -type d -name plan 2>/dev/null
```

Parent of each result = project root.

Also find git repos under the same tree for the "no plan/" bucket:

```bash
find "$ROOT" -maxdepth 3 -type d -name .git 2>/dev/null
```

Subtract: git repos whose parent isn't in the plan-roots list → "No plan/" bucket.

## Step 2: Gather per-project data

For each project with plan/, gather:

- **Latest summary date** — newest filename matching `plan/YYYY-MM-DD-summary.md`. Parse date from filename. If none → "no windup yet".
- **Top chunk title** — first `## ` heading inside `plan/workplan.md` (skip the `# Workplan` h1 if present). Truncate to ~40 chars with `…`. If file missing/empty → `—`.
- **Pending counts** — count `- ` items under `## Now` and `## Open questions` in `plan/pending.md`. If file missing → `0 / 0`.
- **Git dirty** — `git -C <root> status --porcelain 2>/dev/null | wc -l`. If non-zero, flag.

Many small reads is fine — plan/ files are short. Use Bash + Read efficiently.

## Step 3: Classify by age

Compute days between today and the latest summary date:

- **Active** — ≤ 3 days
- **Idle** — 4–14 days
- **Stale** — > 14 days
- **No windup yet** — has `plan/` but no dated summary file
- **No plan/** — git repo, no plan/ folder at all

## Step 4: Render

Output in this shape, sorted newest-first within each bucket, project names left-aligned for scanability:

```
=== Standup — <today's date> ===

Active (windup ≤ 3 days):
  <project>    — <N>d ago · "<chunk>" (<X> Now / <Y> Q)  [<N> dirty]
  ...

Idle (4–14 days):
  <project>    — <N>d ago · "<chunk>"
  ...

Stale (> 14 days):
  <project>    — <N>d ago · top Now: "<first item>"
  ...

No windup yet:
  <project> · <chunk if any>
  ...

No plan/ folder:
  <project>, <project>, ...
```

Skip empty buckets (don't print a header with nothing under it). Keep it dense — single line per project.

## Step 5: Wait

After rendering, don't editorialize, don't recommend, don't auto-resume. The user is choosing what to work on. They'll say "let's do <project>" or `/resume-nt` in whichever project — then act on that.
