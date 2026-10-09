## Phase 5 — Rank, propose the ideal journey, and report

### Rank

- **Stable IDs** `C/H/M/L` (the `/forward-pass-nt` scheme), ranked by how badly each blocks a newcomer reaching first value. The Phase 4 objective audit is its own track, labelled score or checklist.
- **Each finding:** the step or screen · what a cold user experiences · why it trips them · a concrete fix · tagged **quick win** (a label, a default, a dead button) or **structural** (reorder onboarding, regroup nav → `/decide-nt`). Flail findings are marked as such and carry the beat index they replay from.
- **The counter-proposal:** a re-ordered ideal first-run sequence and a re-grouped IA, concrete and step by step.

### Write `plan/ux-review-YYYY-MM-DD.md`

Per ATTEST, in this order:

1. **Header**: date, scope, surface (Phase 0), the cold-start state used, the newcomer persona walked, the **armed invariant set**, and the `Reviewer:` line.
2. **The newcomer journey**: the Phase 2 narrative, friction flagged inline, timestamps into the recording.
3. **Findings**: ranked `C/H/M/L`, each tied to a beat, with fix and tag, marked scripted walk or flail.
4. **The flail**: budget spent (interactions and minutes), yield, or the skip reason.
5. **IA map + proposed re-grouping**: current tree vs the task-grouped version.
6. **Ideal first-run sequence**.
7. **Objective audit**: Lighthouse scores and top failing audits, the native a11y result, or the CLI/TUI checklist, labelled score or checklist.
8. **Coverage / blind spots**: what couldn't be reached cold.
9. **`## Workplan`**: the ranked findings as a fix-workplan, the same shape as `/forward-pass-nt`'s. Themed batches, the keystone first and marked `## Batch A — <theme>  (keystone)`; each item `- [ ] **H2** <fix> (<location>). <one-line why>.`, where the location is the beat and screen, or `path:line` when known. Structural items end `→ /decide-nt`; bugs and invariant breaches end `→ /walkthrough-nt`. `/release-nt` and `/autopilot-nt` read the open `[ ]` items.

Create or check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives): a broken `plan` symlink is a stop; if missing, create it in `$NT_PLAN_STORE` and symlink it in when that is set, else `mkdir plan`; then `git check-ignore -q plan`, else add `/plan` (no trailing slash) to `.gitignore`. If today's report exists, suffix `-2`.

### Hand back the recording

Send each recording from `plan/ux-review-<date>-run/` with `SendUserFile`, one per viewport. Name a file over 25 MB by its path instead. Without `SendUserFile` (a subagent, a non-interactive run), print the absolute path of the run directory and name each video file. Say whether each is a real recording, an asciicast, or a screenshot contact sheet.

### Media lifecycle

The recordings and screenshots are working evidence, not the record; the report is the record. Keep them while findings are open: the fixer replays beats from them. Once the fixes land and the gates pass, delete the run directory's media by name (`*.webm`, `*.mp4`, `*.cast`, `*.png`, `*.jpg`), report each deletion with its size, and keep the report, the beat logs and the JSON. Video stays out of a synced plan store (`*.webm` and `*.mp4` ignored there), since a run's media runs to 40–110 MB.

**Print to chat:** the worst friction beats, the ranked findings, the flail's yield, the audit results, and the headline of the ideal sequence. Point structural items at `/decide-nt` and bugs and invariant breaches at `/walkthrough-nt`; `/replan-nt` folds the report into `pending.md`/`workplan.md`.
