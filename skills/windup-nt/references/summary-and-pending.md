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
