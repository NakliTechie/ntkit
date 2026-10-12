---
description: "Walk the running app per role, fixing inline, or recheck its feature map; commits locally."
argument-hint: "[role or flow to focus, e.g. admin | checkout] | map"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent", "SendUserFile", "mcp__Claude_Browser__*", "mcp__claude-in-chrome__*"]
entry: "app boots with the shared demo seed; map mode also needs verify/features/"
exit: "every role walked in a real browser; the invariant set armed before the first click and every breach logged; the chaos leg run to its budget or declared skipped with a reason; fixes committed; verification harness + feature map created or extended; report written. Map mode: every feature file read from source and driven live, outcome clean / changed / blocked, report written"
writes: "code, the committed verification harness + feature map, plan/walkthrough-<date>.md, plan/walkthrough-<date>-run/ (recording or transcript + action log). Map mode: the harness and map only, plan/walkthrough-map-<date>.md"
---

Drive the **running app the way its users do, one user role at a time**, walking each role's journeys as that user would, and **fix the logical errors you hit along the way**. This is a live runtime audit; `/forward-pass-nt` is the cold, read-only code audit.

**This command edits code.** Fix a clear logical error in place (reproduce, root-cause, fix, re-verify on the running app), commit it locally as one focused commit by path, and continue the walk. Anything that changes product behaviour, needs a design call, or grows into a refactor is **deferred** to the report with a pointer at `/decide-nt`, never forced. Nothing is pushed; `/windup-nt` ships.

**No real-world side effects.** Stub payments, outbound email and native pickers before any walk drives them. The chaos leg never clicks an action that sends real mail, charges a real card, or writes to a shared upstream. If such a path cannot be stubbed, or Phase 4 deferred a Critical that blocks the app, skip the chaos leg and give the reason in the report.

**Pick the surface first.** Name the primary surface a user touches: **browser** (web app, Electron), **terminal** (CLI or TUI), or **service** (an HTTP or RPC API with no UI of its own). A repo with several walks the primary one and lists the rest as blind spots. For a terminal or service surface, read `references/terminal-and-service.md` as well: each phase's section there replaces the browser-only parts of that phase's Detail file. A library with no runnable surface, or a native desktop app, is out of scope: say so and suggest `/forward-pass-nt` or `/ux-review-nt`.

**Rotate the eyes.** Before starting, read only the `Reviewer:` line of this command's latest report in the main checkout's `plan/`, never its findings. If that run used your model family, prefer another family's agent CLI on PATH (`codex`, `gemini`, checked with `which`), else another model of your family; never materially weaker eyes. Neither reachable → run as-is and write `rotation: unavailable` in the `Reviewer:` line. The report header says `Reviewer: <model> · prior: <model> (<date>)` or `prior: none`, and notes when you are the family that built most of the code.

`$ARGUMENTS` (optional): a role (`admin`) or a flow (`checkout`) to scope to. If empty, cover every role and their primary journeys. `map` runs map mode instead of the walk (below).

## Map mode — `/walkthrough-nt map`

A light pass that keeps the harness and `verify/features/` honest between full walkthroughs. It reads each feature from source, drives every feature live through the harness, and corrects the map and harness only. It never edits product code: a feature that no longer behaves as the map says is either map drift (fix the map) or a product regression (report it for the next full walkthrough). It ends **clean** (nothing to change), **changed** (one local commit of proven corrections) or **blocked** (what stopped it). With no `verify/features/`, it stops and points at a full `/walkthrough-nt`. Read `references/map-mode.md` and follow it instead of the phases below.

Example: `/walkthrough-nt map` after a week of feature work, before `/release-nt`.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Roles | A role inventory derived from the code (RBAC, route guards, role-forked UI, seeds, docs), always including the **anonymous visitor** and the **brand-new zero-data user**. Start from `verify/features/` when a prior run left it; drift between map and code is a finding. Missing credentials are the one thing to ask for; never invent auth. | `references/roles-and-journeys.md` |
| 2 Journeys | A per-role checklist of flows, entry points first, first-run and empty-state journeys marked so they are tested on purpose. | `references/roles-and-journeys.md` |
| 3 Boot | Harness `doctor` first when one exists. Browser: production build on `127.0.0.1` and a known-free port; readiness waits on a condition past hydration, never a fixed sleep; a session per role from the shared demo seed (`demo/seed/`); the seven floor invariants armed before the first click. WebGPU flows run in real Chrome, never headless. Terminal and service: build once, a fresh isolated session per drive, their own floor invariants. | `references/boot.md` |
| 4 Walk and fix | Act → observe → fix now → continue, one fix at a time, each re-verified on the running app and committed. Findings get stable IDs `C/H/M/L` with evidence. A fix that grows into a refactor or a product call is deferred, not forced. Includes a cross-role authorization probe and stubbed seams for what the driver cannot reach. | `references/walk-and-fix.md` |
| 5 Chaos leg | A bounded random walk from the states the scripted journey reached, with the Phase 3 invariants as the oracle, driven from a **logged seed**. Every breach replayed from the action log before it earns an ID; confirmed ones fixed under Phase 4's rules and pinned as regression cases. Skippable, never silently. | `references/chaos.md` |
| 6 Lever | A committed, rerunnable harness with three entry points (`doctor`, `verify <feature>`, `verify`), worktree-safe, plus the feature map at `verify/features/`. This harness becomes the project's verifier for `/release-nt` and `/autopilot-nt`. | `references/harness-and-feature-map.md` |
| 7 Report | `plan/walkthrough-<date>.md`: header with counts, the armed invariant set and the `Reviewer:` line, coverage map with blind spots, issues by ID (FIXED with `path:line` and evidence, or DEFERRED with what unblocks), authz findings, chaos-leg budget and yield, verification reality, progress log. Hand back the recording or transcript alongside it. Print counts, fixed vs deferred, blind spots. Name the SHAs; `/windup-nt` pushes. | `references/report.md` |

## Impact declaration

`plan/walkthrough-<date>.md` (and map mode's `plan/walkthrough-map-<date>.md`) is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).
