---
description: "Drive each role through the running app in a real browser; fixes inline, commits locally."
argument-hint: "[role or flow to focus, e.g. admin | checkout]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "SendUserFile", "mcp__Claude_Browser__*", "mcp__claude-in-chrome__*"]
entry: "app boots with the shared demo seed"
exit: "every role walked in a real browser; the invariant set armed before the first click and every breach logged; the chaos leg run to its budget or declared skipped with a reason; fixes committed; verification harness + feature map created or extended; report written"
writes: "code, the committed verification harness + feature map, plan/walkthrough-<date>.md, plan/walkthrough-<date>-run/ (recording + action log)"
---

Drive the **running app through a real browser, one user role at a time**, walking each role's journeys as that user would, and **fix the logical errors you hit along the way**. This is a *live runtime* audit: the inverse of `/forward-pass-nt`, which reads the code cold and touches nothing.

**This command edits code, iteratively.** A clear logical error is fixed in place — reproduce, root-cause, fix, re-verify in the browser — then committed locally, one focused commit by path, and the walk continues. Anything that changes product behaviour, needs a design call, or is a large refactor is **deferred** to the workplan with a pointer at `/decide-nt`, never force-applied. Nothing is pushed; `/windup-nt` ships.

If the project has no browser surface (pure CLI, library, backend-only), say so and suggest `/forward-pass-nt`. If the current directory isn't a git repo, ask which project.

**Rotate the eyes.** This is a checker command; two runs of the same model misjudge the same things identically. Before starting, read only the `Reviewer:` header line of this command's most recent report in `plan/`. Repeat run → prefer a different **model family** (an agent CLI on the PATH such as `codex` or `gemini`, checked with `which`, driven through this same brief via Bash); none reachable → a different model of the current family (subagent with a model override); neither → run as-is and say so in the report. Never rotate to materially weaker eyes; log the rotation as unavailable instead. The report header carries `Reviewer: <model> · prior: <model> (<date>)` or `prior: none`, and names it if you are the family that built most of this code.

`$ARGUMENTS` (optional): a role (`admin`) or a flow (`checkout`) to scope to. If empty, cover every role and their primary journeys.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Roles | A role inventory derived from the code (RBAC, route guards, role-forked UI, seeds, docs) — always including the **anonymous visitor** and the **brand-new zero-data user**. Start from `verify/features/` when a prior run left it; drift between map and code is a finding. Missing credentials are the one thing to ask for; never invent auth. | `references/roles-and-journeys.md` |
| 2 Journeys | A per-role checklist of flows, entry points first, first-run and empty-state journeys marked so they are tested on purpose. | `references/roles-and-journeys.md` |
| 3 Boot | Harness `doctor` first when one exists. Production build on `127.0.0.1` and a known-free port; readiness waits past hydration; a session per role from the shared demo seed (`demo/seed/`); an error surface (console, page errors, rejections, 4xx/5xx) on before the first click. WebGPU flows run in real Chrome, never headless. | `references/boot.md` |
| 4 Walk and fix | Act → observe → fix now → continue, one fix at a time, each re-verified in the browser and committed. Findings get stable IDs `C/H/M/L` with evidence. A fix that grows into a refactor or a product call is deferred, not forced. Includes a cross-role authorization probe and stubbed seams for what the browser cannot drive. | `references/walk-and-fix.md` |
| 5 Chaos leg | A bounded random walk from the states the scripted journey already reached, with the Phase 3 invariants as the oracle — the space a written journey cannot cover by construction. Every breach replayed from the action log before it earns an ID; confirmed ones fixed under Phase 4's rules and pinned as regression cases. Skippable, never silently. | `references/chaos.md` |
| 6 Lever | A committed, rerunnable harness with three entry points — `doctor`, `verify <feature>`, `verify` — worktree-safe by construction, plus the feature map at `verify/features/`. This harness becomes the project's verifier for `/release-nt` and `/autopilot-nt`. | `references/harness-and-feature-map.md` |
| 7 Report | `plan/walkthrough-<date>.md`: header with counts and the `Reviewer:` line, coverage map with blind spots, issues by ID (FIXED with `path:line` and evidence, or DEFERRED with what unblocks), authz findings, chaos-leg budget and yield, verification reality, progress log. Hand back the recording alongside it. Print counts, fixed vs deferred, blind spots. Name the SHAs; `/windup-nt` pushes. | `references/report.md` |

## Impact declaration

`plan/walkthrough-<date>.md` is a **record**: append-only, never rewritten. The derived files (`pending.md`, `workplan.md`, `history.md`'s `## Decisions` and `## Dead ends`) are a projection over the records, rewritten only by `/replan-nt`, `/windup-nt` and `/scaffold-nt`. (Full contract: [`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) in the ntkit repo.) End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- workplan.md/B2#3 — status: [ ] → [x], verified by <the check that proves it>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. Do not write the item into `pending.md` or `workplan.md` yourself — a record that declares its impact and a reconcile pass that folds it are what keep the plan rebuildable from the log. An `add` line with nothing later citing this record is a **ghost**, and `plancheck` reports it.
