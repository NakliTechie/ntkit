## 1. Day summary

Write `plan/$(date +%Y-%m-%d)-summary.md` with what happened today. Gather context from:
- This session's conversation
- `git log --since=midnight --oneline --all` for commits made today
- `git status` and `git diff` for any uncommitted work
- `plan/soc.md` — today's stream-of-consciousness entries (from `/soc-nt`): fold the load-bearing ones into the summary's sections, but leave the file in place — `/replan-nt` owns its triage and archival

Cover, in this order:
- **Shipped** — what landed (PRs, commits, deploys), each with its commit SHA
- **Verified** — how it was checked (tests / typecheck / build / manual) and what verification is still owed (e.g. "needs runtime test")
- **Decisions** — what was chosen and why (especially anything non-obvious)
- **Tried then rolled back** — dead ends worth remembering so we don't repeat them
- **Open questions** — anything that surfaced today but isn't resolved
- **Deferred / parked** — anything raised today but consciously *not* done now (skipped, "later", out of current scope, not abandoned) → seeds `## Parked` in pending.md, so a "not now" said out loud doesn't evaporate

Keep it tight — bullet points, not prose. The future-self reading this wants signal, not a transcript.

## 2. Pending items

Write or update `plan/pending.md`. The canonical structure (shared with /replan-nt) is:

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
- **File exists with sections:** preserve them. New items surfaced today go into `Now` by default, `Open questions` if phrased as a question, or **`Parked` if it was deferred this session** — raised but chosen against for now (skipped, "later", out of current scope, not abandoned). Remove items finished today from wherever they sit. Actively move a "not now" into `Parked` rather than dropping it; leave already-parked items alone unless they came back into scope today.
- **File exists, flat (no sections):** keep it flat — don't restructure mid-windup. Just add new items and remove finished ones. (User can run `/replan-nt` when ready to migrate to the structured form.)
- **File doesn't exist:** create it with the three sections (canonical from day one).

Order items by priority within each section. Each item is one line — link to a deeper plan/ doc if there's more context. `pending.md` is the source of truth for what's open; execution order is the workplan's job (next step).
