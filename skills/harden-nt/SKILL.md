---
description: "Map an agent-facing surface's paths and harden each with independent multi-model agents; fixes code."
argument-hint: "[surface, e.g. \"the public API\" | budget, e.g. \"6 rounds\" | resume]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent"]
entry: "a surface whose contract can be stated — an agent-facing API, an MCP server, a CLI other tools depend on, a public app boundary. Paths that only exist at runtime need a real reachable instance (live-check-nt's trigger test decides); paths that don't, don't"
exit: "every path in the map is hardened — carries a check that has been shown to go red against the defect it guards — OR the budget is exhausted with an honest uncovered list"
writes: "plan/harden-<date>.md; verify/neuter-matrix.md rows; status flips on existing workplan items it completes"
---

`/harden-nt` makes a surface harder than it was, and produces the evidence. It works from a **path map** — what the surface claims to support — and drives that map with independent agents from **different model families**, two ways at once: **constructively**, showing a claimed path holds, and **adversarially**, finding the paths the map forgot. Nothing counts as covered until the check guarding it has been **proven able to fail**.

`$ARGUMENTS` (optional): the surface (a URL, an API base, "the CLI"), and/or a budget (default: **6 rounds or 4 hours, whichever ends first**). `resume` continues the most recent open `plan/harden-*.md`.

Not in a git repo → ask which project; this command commits fixes.

## Phase 0 — The launch contract

State back, then go: a veto window, not a questionnaire, same as `/autopilot-nt` Phase 0.
- **The surface**, and which of its paths need a live instance versus which can be exercised statically.
- **The roster — heterogeneous by default.** Independent agents per round (default 3), drawn from **different model families** wherever more than one is configured. Homogeneous-but-isolated (same stack, separate context and tenant, no shared memory) is the fallback; name it as a downgrade when you take it.
- **Isolation contract** — each agent gets its own tenant, branch or key where the surface supports it, and **never** the maker's diff, reasoning, or repo access. Black-box, driving the surface as an outside caller would. A Verify round always goes to a fresh agent, never back to the one that raised the finding.
- **Budget and stop conditions.**
- **Stop-lines** — `/autopilot-nt` Phase 4 defaults: no agent may publish, send, spend, or touch real customer data. A surface with real side effects gets a **scratch tenant**, never a production identity. Name the tenant before round 1.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Path map | Written before any testing, from contract, docs and entry points, not from what you think is risky: happy paths · boundaries · state transitions · concurrency and idempotency · cross-tenant and authorization. Each path is **uncovered → exercised → hardened**; only Phase 4 grants the last. | — |
| 2 Liveness | One trivial known-true probe against the target before round 1 and after any suspiciously clean round. Not optional: a kill command once matched nothing, the stale server kept answering, and two full rounds reported every real fix as refuted. | `references/rounds.md` |
| 3 Rounds | Typed, never mixed. **Constructive** (map slice + contract: demonstrate the path holds) moves paths to exercised. **Adversarial** (contract only, no hints: find what it mishandles) adds paths to the map; run at least one, and again whenever constructive rounds go quiet. **Verify** (one path's claim, not the fix) confirms with a control pair, then attacks the fix with at least three variants of the same defect. Findings are one reproducible sentence against the surface. | `references/rounds.md` |
| 4 Harden | Per failing path: smallest fix → leave a check → **prove the check goes red** with the defect reintroduced before trusting green → one commit → log path, SHA, and proof → one row in `verify/neuter-matrix.md`. Two honest attempts, then park. | `references/harden.md` |
| 5 Carry forward | One running map across rounds, never restarted: uncovered (oldest first) · exercised (honest middle, not done) · hardened. Every round runs against the current surface, warm-started from all prior fixes. A path that breaks again is reopened with its history, never filed as new. | — |
| 6 Verdict | **Covered** when every path is hardened, every check still goes red on its defect, and the last adversarial round added nothing — stated as "this map, as of this run". Otherwise **stopped** (budget, or three rounds hardening nothing) with the uncovered list. | `references/report.md` |
| 7 Report | `plan/harden-<date>.md` in ATTEST form with the fixed summary block: rounds and families, map counts, verdict, hardened / added / reopened / uncovered lists, Needs you. End by naming whether the surface is ready for `/live-check-nt` or `/release-nt`; the uncovered list feeds `/autopilot-nt`. | `references/report.md` |

## Impact declaration

`plan/harden-<date>.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).

Anything this run defers to `/autopilot-nt` is an `add` impact line here, not an item written straight into `workplan.md`.
