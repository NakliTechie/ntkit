---
description: Capture a future-work idea into the backlog — append a dated one-liner to plan/ideas.md (or the repo's IDEAS.md if it has one), without derailing the current task. The /decide-nt pattern, for ideas instead of decisions.
argument-hint: <the idea, e.g. "add a dark-mode toggle">
entry: "any state"
exit: "idea appended to the backlog"
writes: "plan/ideas.md (or IDEAS.md)"
---

Park an idea without losing your place. `/idea-nt` is `/decide-nt`'s sibling: where decide records a load-bearing *decision* into history, idea drops a *future-work* idea into the backlog — friction-free, no follow-up questions, so a passing thought doesn't derail what you're doing.

## Step 1: Get the idea text

If `$ARGUMENTS` is non-empty, that's the idea — use it verbatim. If empty, ask *"What's the idea?"* and use the next message.

## Step 2: Locate the backlog

Current directory should be inside a git repo. If not, ask which project — don't guess.
- If the repo has a committed **`IDEAS.md`** (the naklios backlog convention), use it.
- Otherwise use **`plan/ideas.md`** (local). Create it with a `# Ideas` header if missing; verify `plan/` is gitignored, and add it if not.

## Step 3: Append

Insert at the **top** of the list (newest first):

```
- YYYY-MM-DD <idea>
```

Use today's date. If the idea implies a quick "why" or "how", add it as a short trailing clause — but keep it to one line. Preserve existing entries below.

## Step 4: Confirm

Short echo, nothing more:

```
Captured in <plan/ideas.md | IDEAS.md>:
  - <YYYY-MM-DD> <idea>
```

Don't commit or push — a local `plan/ideas.md` stays local; a committed `IDEAS.md` ships via `/windup-nt`. When an idea graduates into real work, it becomes a `/scaffold-nt` or a `pending.md` item.
