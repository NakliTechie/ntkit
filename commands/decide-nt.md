---
description: Record a load-bearing decision into plan/history.md Decisions section — one-line surgical capture mid-session
argument-hint: <short rationale, e.g., "Chose JWT for stateless validation">
entry: "any state"
exit: "dated one-line decision appended"
writes: "plan/history.md"
---

Record a decision in the current project's `plan/history.md`.

## Step 1: Get the decision text

If `$ARGUMENTS` is non-empty, that's the decision text. Use it verbatim.

If `$ARGUMENTS` is empty, ask the user: *"What did you decide?"* and use their next message as the decision text.

## Step 2: Locate plan/history.md

Current directory should be inside a git repo. If not, ask the user which project — don't guess.

If `plan/` folder doesn't exist, create it. Verify `plan/` (or `/plan/`) is in `.gitignore`; add it if missing.

If `plan/history.md` doesn't exist, create it with the canonical structure:

```
# History

## Decisions

## Log

## Dead ends
```

## Step 3: Append the decision

Insert at the **top** of the `## Decisions` section (newest first), in this format:

```
- YYYY-MM-DD <decision text>
```

Use today's date. Preserve any existing Decisions entries below.

## Step 4: Confirm

Short echo, nothing more:

```
Recorded in plan/history.md:
  - <YYYY-MM-DD> <decision text>
```

Don't commit, don't push, don't run /windup-nt — plan/ is gitignored, so the decision lives locally. /replan-nt will carry it forward; /windup-nt may surface it in the day summary if relevant.
