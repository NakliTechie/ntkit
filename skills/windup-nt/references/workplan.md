## 3. Workplan

Write or update `plan/workplan.md`: regroup `plan/pending.md` into chunks the next session can pick up and execute without re-planning. A chunk groups items that are:
- **Logical** — same area, feature, module, or file
- **Convenient** — small items and quick wins batched into one sitting
- **Related** — natural dependencies or sequencing

Each chunk has:
- A short title naming what binds the items; mark a **keystone** chunk others depend on
- 2–5 items from `pending.md`, each a **tri-state checkbox**: `[ ]` open · `[x]` done · `[~]` partial
- A loose size estimate ("30 min", "half day", "1–2 hours")
- Optional: a note on prerequisites or sequencing

Item conventions:
- **Preserve in-flight chunks:** a chunk whose items are all still in pending `Now` is copied through verbatim.
- A `[~]` item states what's done, what's left, and what would un-defer it; point at `/decide-nt` when the blocker is a decision.
- A chunk from `/forward-pass-nt`, `/walkthrough-nt`, or `/ux-review-nt` carries the finding IDs (`C1`, `H2`, …) and a `[test]` marker on any item whose verification is still owed.

Items that don't yet cluster go under `## Unbatched`.
