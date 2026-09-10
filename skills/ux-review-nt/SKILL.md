---
description: "Cold first-run UX walk — browser, CLI, TUI, or native app; ranked report, read-only."
argument-hint: "[area to focus, e.g. first-run | settings | nav] [surface: web|cli|tui|native — auto-detected if omitted]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task", "SendUserFile", "mcp__computer-use__*", "mcp__Claude_Code_iOS_Simulator__*", "mcp__Claude_Browser__*", "mcp__claude-in-chrome__*", "mcp__plugin_chrome-devtools-mcp_chrome-devtools__*"]
entry: "app boots; state wipeable to cold-start"
exit: "first-run + IA report written, with the invariant set armed before the first beat and the flail run to its budget or declared skipped; app unmodified (read-only run)"
writes: "plan/ux-review-<date>.md, plan/ux-review-<date>-run/ (recording + beat log)"
---

Review the app **as a cold first-time user** — the person who wasn't there when each feature was bolted on. Features get added in build-order, which makes sense to whoever built it; to a newcomer the nav, setup, settings, and first-run flow are an accretion, not a journey. This command walks the genuine newcomer path and reports where that accretion trips them.

**READ-ONLY.** It ranks findings and proposes an ideal first-run sequence + information architecture — it never edits the app. This holds for everything it finds, including a crash: an invariant breach is *reported with an ID*, never fixed here. Structural changes (reorder onboarding, regroup nav) are *product* calls → `/decide-nt`; a friction point that's actually a *bug* → hand to `/walkthrough-nt`.

On the **browser surface**, it's the third walkthrough sibling: `/walkthrough-nt` finds bugs and fixes them, `/guide-nt` captures screenshots and documents — both **seed data so screens aren't empty**. `/ux-review-nt` does the **opposite**: it wipes all state, because the whole point is to experience exactly what a newcomer experiences — the empty state, the first-run asks, the "what is this and what do I do" moment. On **CLI, TUI, and native (macOS/iOS)** surfaces `/walkthrough-nt` and `/guide-nt` don't reach yet, so this command runs the cold walk alone there — same wipe-first posture, no seeded state, on whichever surface the app actually presents.

**Stronger with different eyes — rotate them across runs.** This is a checker command — its whole value is that it doesn't share the maker's blind spots, and two runs of the same model misjudge the same things identically. Fresh context is the floor; a different **model family** is the stronger posture. Before starting, find this command's most recent prior report in `plan/` and read its `Reviewer:` header line — **that line only, never the prior findings**, which would contaminate the cold-newcomer posture this command exists to manufacture — then pick this run's eyes:

- **First run** (no prior report): proceed as the current agent.
- **Repeat run:** prefer a reviewer from a **different family** than the prior run — an agent CLI on the PATH (`codex`, `gemini`, …; check with `which`) driven through this same brief via Bash. None reachable → use a **different model** of the current family (subagent with a model override). Even that unavailable → run as-is and say so in the report, never silently.
- **Never rotate below the floor:** fresh-but-weak eyes find less than strong eyes looking twice. If every alternative is materially weaker than the current agent, keep the current agent and log the rotation as unavailable.

Whichever ran, the report header carries one line — `Reviewer: <model> · prior: <model> (<date>)` or `prior: none` — that line is the whole log; the next run reads it to rotate. If you are the family that built most of this code, say that there too — the reader should know which grade of eyes graded it.

Rotating the *eyes* is one axis; rotating the *actions* is the other, and it is what Phase 3 exists for. A scripted journey written by someone who knows where they're going is one draw from one distribution — the flail is the second draw, and the two compose.

If the current directory isn't a git repo, ask which project — don't guess. If the project has no interactive surface at all (pure library, backend-only with no CLI/API console), say so and suggest `/forward-pass-nt` instead.

`$ARGUMENTS` (optional): an area to focus — `first-run`, `settings`, `nav` — and/or a surface override — `web`, `cli`, `tui`, `native`. If the surface is empty, detect it (Phase 0); if genuinely ambiguous, ask once rather than picking silently. If the focus is empty, walk the whole cold journey from arrival to first value.

Example: `/ux-review-nt first-run web`

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 0 Surface | Exactly one surface chosen — `web`, `cli`, `tui`, or `native` — from an explicit override or repo signals, named in the report header. Ambiguous → ask once. | `references/surface.md` |
| 1 Cold start | A genuine newcomer manufactured per surface (wiped storage / isolated `$HOME` / erased simulator), production build, canonical entry. The named invariant set armed and the recording started **before the first interaction**. | `references/cold-start.md` |
| 2 Journey | A numbered step narrative from arrival to first value, each beat carrying what's on screen, the obvious next action or the guess, and its timestamp into the recording — then scored against the eight newcomer-friction lenses. | `references/walk.md` |
| 3 Flail | A bounded misclick-and-recover walk from the states Phase 2 reached (~30 interactions), plus a wrong-artifact probe at every ingest point, budgeted and declared. Finding class is **recoverability** — dead ends, lost work, traps, errors that don't say what to do — not crashes. Skippable, never silently. | `references/flail.md` |
| 4 IA + audit | The real nav tree with its grouping logic, depth and orphans; plus the surface's objective layer — a Lighthouse score (web), a real a11y audit (iOS), or a labelled checklist (CLI/TUI/macOS). Never a checklist dressed as a score. | `references/audit.md` |
| 5 Report | `plan/ux-review-<date>.md`: header with surface, invariants and the `Reviewer:` line, the journey, findings ranked `C/H/M/L` with quick-win/structural tags, the flail's yield, IA map + re-grouping, the ideal first-run sequence, the objective audit, blind spots. Recording handed back with `SendUserFile`. | `references/report.md` |

## Impact declaration

`plan/ux-review-<date>.md` is a **record**: append-only, never rewritten. The derived files (`pending.md`, `workplan.md`, `history.md`'s `## Decisions` and `## Dead ends`) are a projection over the records, rewritten only by `/replan-nt`, `/windup-nt` and `/scaffold-nt`. (Full contract: [`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) in the ntkit repo.) End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- workplan.md/B2#3 — status: [ ] → [x], verified by <the check that proves it>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. Do not write the item into `pending.md` or `workplan.md` yourself — a record that declares its impact and a reconcile pass that folds it are what keep the plan rebuildable from the log. An `add` line with nothing later citing this record is a **ghost**, and `plancheck` reports it.
