## Phase 5 — Rank, propose the ideal journey, and report

### Rank

- **Rank with stable IDs** by how badly each blocks a newcomer reaching first value, using the shared severity scheme — `C/H/M/L` (Critical / High / Medium / Low), same as `/forward-pass-nt` and `/walkthrough-nt` so the IDs read the same downstream. Add the objective-audit track from Phase 4 (a real score on native/iOS and web, a checklist on CLI/TUI — label it accordingly, don't blur the two).
- **Each finding:** the specific step/screen · what a cold user experiences · *why* it trips them · a concrete fix · tagged **quick win** (trivial: a label, a default, a dead button) or **structural** (reorder onboarding, regroup nav — a design call → `/decide-nt`). Findings from the flail are marked as such, and each carries the beat index it replays from.
- **Invariant breaches are findings, not fixes.** An `INV-*` breach from Phase 1 gets an ID and a severity like anything else, and routes to `/walkthrough-nt` — this command never edits the app.
- **The counter-proposal — the constructive heart.** Don't stop at "this is confusing." Give the **re-ordered ideal first-run sequence** and a **re-grouped IA** — "here's the journey a newcomer *should* have." Concrete, step-by-step, so the user can decide and act on it.

### Write `plan/ux-review-YYYY-MM-DD.md`

In this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.
1. **Header** — date, scope, the surface (Phase 0), the cold-start state used, the newcomer persona walked, the **invariant set armed**, and the `Reviewer:` line (this run's model · prior run's model + date, per the rotation rule).
2. **The newcomer journey** — the numbered step narrative from Phase 2, friction flagged inline, timestamps into the recording.
3. **Findings** — ranked `C/H/M/L`, each tied to a beat, with fix + quick-win/structural tag, and marked scripted-walk vs flail.
4. **The flail** — budget spent (interactions and minutes), what it yielded, or the reason it was skipped. Recoverability findings live here.
5. **IA map + proposed re-grouping** — current tree vs the task-grouped version.
6. **Ideal first-run sequence** — the re-ordered counter-proposal.
7. **Objective audit** — Lighthouse scores + top failing audits (web) or the native a11y-audit result, or the CLI/TUI checklist, whichever surface this run used — labeled as a score or a checklist, never blurred.
8. **Coverage / blind spots** — what couldn't be reached cold (e.g., flows gated behind real credentials).

Create `plan/` if missing and ensure it's gitignored; if today's report exists, suffix `-2`. **Don't edit the app** — this is read-only.

### Hand back the recording

`plan/ux-review-<date>-run/` holds the recording and the beat log. **Send the recording with `SendUserFile`.** For a UX review this is not a nicety — the deliverable is a newcomer struggling, and watching thirty seconds of someone stuck on the credential modal lands what a paragraph describing it does not. Say plainly whether it is a real recording, an asciicast, or a screenshot contact sheet.

**Print to chat:** the journey's worst friction beats, the ranked findings, the flail's yield, the objective-audit results, and the headline of the ideal-sequence proposal (keep the full proposal in the file).

End by pointing structural recommendations at `/decide-nt`, any genuine bugs and every invariant breach at `/walkthrough-nt`, and noting that `/replan-nt` folds this report into `pending.md`/`workplan.md`.
