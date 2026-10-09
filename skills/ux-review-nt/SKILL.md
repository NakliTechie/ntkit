---
description: "Cold first-run UX walk — browser, CLI, TUI, or native app; ranked report, read-only."
argument-hint: "[area to focus, e.g. first-run | settings | nav] [surface: web|cli|tui|native — auto-detected if omitted]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Agent", "SendUserFile", "mcp__computer-use__*", "mcp__Claude_Code_iOS_Simulator__*", "mcp__Claude_Browser__*", "mcp__claude-in-chrome__*", "mcp__plugin_chrome-devtools-mcp_chrome-devtools__*"]
entry: "app boots; state wipeable to cold-start"
exit: "first-run + IA report written, with the invariant set armed before the first beat and the flail run to its budget or declared skipped; app unmodified (read-only run)"
writes: "plan/ux-review-<date>.md, plan/ux-review-<date>-run/ (recording + beat log)"
---

Review the app **as a cold first-time user**, the person who wasn't there when each feature was bolted on, and report where the build-order accretion of nav, setup, settings and first-run trips them.

`$SKILL` is this skill's base directory, printed when the skill loads; sibling kit skills sit beside it (`$SKILL/../<skill>/`).

**READ-ONLY.** It ranks findings and proposes an ideal first-run sequence and information architecture; it never edits the app. That holds for a crash too: an invariant breach is reported with an ID, never fixed here. Structural changes (reorder onboarding, regroup nav) are product calls → `/decide-nt`; a friction point that is a bug → `/walkthrough-nt`. A build that writes into the repo runs in a scratch directory outside it.

**No real-world side effects.** The flail never clicks an action that sends real mail, charges a card, or writes upstream. If a newcomer's misclick could trigger one, skip the flail, give the reason in the report, and log that exposure as a finding.

Unlike `/walkthrough-nt` and `/guide-nt`, this command wipes state and never seeds, and it runs alone on CLI, TUI and native surfaces.

**Rotate the eyes.** Before starting, read only the `Reviewer:` line of this command's latest report in the main checkout's `plan/`, never its findings. If that run used your model family, prefer another family's agent CLI on PATH (`codex`, `gemini`, checked with `which`), else another model of your family; never materially weaker eyes. Neither reachable → run as-is and write `rotation: unavailable` in the `Reviewer:` line. The report header says `Reviewer: <model> · prior: <model> (<date>)` or `prior: none`, and notes when you are the family that built most of the code.

Prior findings would contaminate the newcomer posture this command manufactures; do not read them at any phase.

If the project has no interactive surface (pure library, backend-only with no CLI or API console), say so and suggest `/forward-pass-nt`.

`$ARGUMENTS` (optional): an area to focus (`first-run`, `settings`, `nav`) and/or a surface override (`web`, `cli`, `tui`, `native`). An empty surface is detected in Phase 0. An empty focus walks the whole cold journey from arrival to first value.

Example: `/ux-review-nt first-run web`

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 0 Surface | Exactly one surface, named in the report header: an `$ARGUMENTS` override, else repo signals (`.xcodeproj`/`Info.plist`/Android manifest → `native`; TTY framework, no browser entry → `tui`; `bin` entry, no server → `cli`; serves HTTP → `web`). Ambiguous → ask once, naming the candidates. | this row |
| 1 Cold start | A genuine newcomer manufactured per surface (wiped storage / isolated `$HOME` / erased simulator), production build, canonical entry. The named invariant set armed and the recording started **before the first interaction**. | `references/cold-start.md` |
| 2 Journey | A numbered step narrative from arrival to first value, each beat carrying what's on screen, the obvious next action or the guess, and its timestamp into the recording, then scored against the eight newcomer-friction lenses. | `references/walk.md` |
| 3 Flail | A bounded misclick-and-recover walk from the states Phase 2 reached (~30 interactions), plus a durability-after-refresh check and a wrong-artifact probe at every ingest point, budgeted and declared. Finding class is **recoverability** (dead ends, lost work, traps, errors that don't say what to do), not crashes. Skippable, never silently. | `references/flail.md` |
| 4 IA + audit | The real nav tree with its grouping logic, depth and orphans; plus the surface's objective layer: a Lighthouse score (web), a real a11y audit (iOS), or a labelled checklist (CLI/TUI/macOS). Never a checklist dressed as a score. | `references/audit.md` |
| 5 Report | `plan/ux-review-<date>.md`: header with surface, invariants and the `Reviewer:` line, the journey, findings ranked `C/H/M/L` with quick-win/structural tags, the flail's yield, IA map + re-grouping, the ideal first-run sequence, the objective audit, blind spots, and a `## Workplan` of `[ ]` batches, keystone first. Recording handed back with `SendUserFile`. | `references/report.md` |

## Impact declaration

`plan/ux-review-<date>.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).
