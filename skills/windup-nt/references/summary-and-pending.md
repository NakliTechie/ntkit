## 1. Day summary

Write `plan/<date>-summary.md` from:
- this session's conversation;
- `git log --since=midnight --oneline --all`;
- `git status` and `git diff` for uncommitted work;
- today's `plan/soc.md` entries: fold the load-bearing ones into the sections below, but leave the file in place; `/replan-nt` owns its triage and archival.

Sections, in this order:
- **Shipped** — what landed (PRs, commits, deploys), each with its commit SHA
- **Verified** — how it was checked (tests / typecheck / build / manual) and what verification is still owed
- **Decisions** — what was chosen and why
- **Tried then rolled back** — dead ends worth not repeating
- **Open questions** — surfaced today, unresolved
- **Deferred / parked** — raised today but consciously not done now (skipped, "later", out of scope, not abandoned); seeds `## Parked` in pending.md

## 2. Pending items

Write or update `plan/pending.md`. The canonical structure (shared with `/replan-nt`):

```
# Pending

## Now
- <actionable, top priority>

## Parked
- <deferred, not in scope right now but not abandoned>

## Open questions
- <question that needs answering before it can become a task>
```

Merge rules:
- **File exists with sections:** preserve them. New items go into `Now` by default, `Open questions` if phrased as a question, `Parked` if deferred this session. Remove items finished today. Move a "not now" into `Parked` rather than dropping it; leave already-parked items alone unless they came back into scope today.
- **File exists, flat (no sections):** keep it flat; add new items and remove finished ones. `/replan-nt` migrates it to sections.
- **File doesn't exist:** create it with the three sections.

Order items by priority within each section, one line each; link to a deeper `plan/` doc for more context.
