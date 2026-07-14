---
description: Resume a project — read plan/workplan.md + pending.md + history.md + latest day summary, present a resumption brief, and pause for direction
---

Brief the user on where to pick up in the current project. `/resume-nt` is the counterpart to `/windup-nt` — windup writes the resumption context into `plan/`, resume reads it back.

**This is a READ-ONLY command.** Don't write to plan/, don't auto-start work, don't invoke /windup-nt or /replan. Present the brief and pause for direction.

If the current directory is not inside a git repo, ask the user which project to resume — don't guess.

## Step 1: Locate context files

Look inside `plan/` for:
- `workplan.md` — the chunked execution play (primary)
- `pending.md` — open items, especially the `## Open questions` section
- `history.md` — quick scan of `## Decisions` (recent ones) for context
- The most recent `plan/YYYY-MM-DD-summary.md` — freshest "where we left off"
- The most recent `plan/YYYY-MM-DD-autopilot.md` — an unattended run's morning report (branch · final gate · **Shipped: merged or held** · Landed / Needs you / Assumed). If it's **newer than the newest summary**, it's the freshest thing that happened — read its `Shipped:` line: **HELD** (red gate / conflict) means an unmerged `autopilot/<date>` branch is waiting on you, and reviewing it outranks the workplan's top chunk; **MERGED** means a green run already shipped to the default branch — pull it and glance at what landed.

If none exist, fall back: read README, run `git log --oneline -10` and `git status`, and orient from those. Note in the brief that no `plan/` handoff is on file and suggest running `/windup-nt` at the next end-of-session to start building one.

If only some exist, work with what's there — don't error.

## Step 2: Gather quick git context

Get:
- Current branch name
- Ahead/behind status vs upstream (`git status -sb` first line, or `git rev-list --left-right --count`)
- Whether there are uncommitted changes (count of dirty files)

This goes into the brief so the user sees the physical state they're picking up in.

## Step 3: Present the resumption brief

Output in this exact shape:

```
Resuming <project-name>.

Folder: <absolute path>
Branch: <branch> · <ahead/behind status> · <clean | N uncommitted files>

Last session (<date from latest summary, or "no summary on file">):
  Shipped: <one-line bullet, or "—">
  Decisions: <one-line bullet, or "—">
  Open questions: <bullet, or "—">

Next chunk — "<title from top of workplan.md>" (<size estimate>):
  - <item 1>
  - <item 2>
  - <item 3>

Blocking (if any):
  - <open questions from pending.md that relate to this chunk; or top 2-3 open questions if relevance unclear>
```

**If an autopilot run is on file** (report newer than the newest summary), insert this block right after the `Last session` lines — for a HELD run it's the most urgent thing in the brief:

```
Autopilot ran <date> — branch autopilot/<date> · gate <GREEN | RED: what> · <MERGED to <default branch> | HELD>:
  Landed: <N> items · Needs you: <top 1–2 items> · Assumed: <N>
  <if HELD:>   Review: git diff <default branch>...autopilot/<date> → merge or discard
  <if MERGED:> Already shipped — git pull; nothing to review beyond a glance
```

If there's no `workplan.md` or it's empty but `pending.md` has items, show the top 3-5 items from `## Now` instead of a chunk, and note that running `/replan-nt` would generate a proper workplan.

## Step 4: Ask for direction (one question, open-ended)

End with a single open-ended question:

> Ready to start on **"<chunk title>"**, or want to pick a different chunk / look at something else?

When a **HELD** autopilot run is on file, ask this instead — the unmerged branch comes first:

> Review the **autopilot/<date>** branch first (merge or discard), or skip to **"<chunk title>"**?

Keep it conversational. The user might respond with "go", "skip to chunk 3", "actually let me look at file X first", or anything else.

## Step 5: After the user responds

Only after the user confirms direction, start executing. Treat the chosen chunk's items as a working list. Refer back to `plan/workplan.md` and `plan/pending.md` as you go.

If the user picks a different chunk or area, follow that. /resume-nt's job is to present and hand off — not to enforce the top chunk.
