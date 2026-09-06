## 3. Workplan

Write or update `plan/workplan.md`. The workplan reorganizes `plan/pending.md` into chunks the next session can pick up and execute without re-thinking the strategy. Each chunk groups items that are:
- **Logical** — same area, feature, module, or file
- **Convenient** — small items and quick wins batched so they ship in one sitting
- **Related** — natural dependencies or sequencing flow

For each chunk include:
- A short title (what binds the items together); mark a **keystone** chunk others depend on
- 2–5 items pulled from `pending.md`, each a **tri-state checkbox**: `[ ]` open · `[x]` done · `[~]` partial
- A rough size estimate (e.g., "30 min", "half day", "1–2 hours") — keep it loose
- Optional: a note on prerequisites or sequencing

Item conventions:
- A `[~]` partial / deferred item states what's done, what's left, and what would un-defer it — point at `/decide-nt` when the blocker is a decision.
- If a chunk came from a `/forward-pass-nt`, `/walkthrough-nt`, `/ux-review-nt`, or `/maintain-nt`, carry the finding IDs (`C1`, `H2`, …) and a `[test]` marker on any item whose verification is still owed.

Items that don't yet cluster into a chunk go under a `## Unbatched` section — that flags they need more thought before they're actionable.

Order chunks so the next session can pick the top one and start. `pending.md` is the flat source of truth; `workplan.md` is the curated play.
