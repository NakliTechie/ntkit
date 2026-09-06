---
description: "Map an agent-facing surface's paths and harden each with independent multi-model agents; fixes code."
argument-hint: "[surface, e.g. \"the public API\" | budget, e.g. \"6 rounds\" | resume]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "a surface whose contract can be stated — an agent-facing API, an MCP server, a CLI other tools depend on, a public app boundary. Paths that only exist at runtime need a real reachable instance (live-check-nt's trigger test decides); paths that don't, don't"
exit: "every path in the map is hardened — carries a check that has been shown to go red against the defect it guards — OR the budget is exhausted with an honest uncovered list"
writes: "plan/harden-<date>.md; workplan checkboxes for anything deferred to /autopilot-nt"
---

`/harden-nt` makes a surface harder than it was, and produces the evidence. It works from a **path map** — what the surface claims to support — and drives that map with independent agents from **different model families**, two ways at once: **constructively**, showing a claimed path holds, and **adversarially**, finding the paths the map forgot. Nothing counts as covered until the check guarding it has been **proven able to fail** — a check that stays green with or without the defect is not a check, and catching that is why this command exists.

Use it before calling an agent surface ready: an API other agents call, an MCP server, a CLI contract other tools depend on, a public app boundary. `/forward-pass-nt` audits code once and `/live-check-nt` proves one flow once; this is the iterated version over the whole path space. For a single flow you already suspect is broken, `/live-check-nt` is cheaper.

`$ARGUMENTS` (optional): the surface (a URL, an API base, "the CLI"), and/or a budget (default: **6 rounds or 4 hours, whichever ends first**). `resume` continues the most recent open `plan/harden-*.md`.

If the current directory isn't a git repo, ask which project.

## Phase 0 — The launch contract

State back, then go — a veto window, not a questionnaire, same as `/autopilot-nt` Phase 0:
- **The surface**, and which of its paths need a live instance versus which can be exercised statically.
- **The roster — heterogeneous by default.** Independent agents per round (default 3), drawn from **different model families** wherever more than one is configured. Homogeneous-but-isolated (same stack, separate context and tenant, no shared memory) is the fallback — name it as a downgrade when you take it.
- **Isolation contract** — each agent gets its own tenant, branch or key where the surface supports it, and **never** the maker's diff, reasoning, or repo access. Black-box, driving the surface as an outside caller would.
- **Budget and stop conditions.**
- **Stop-lines** — `/autopilot-nt` Phase 4 defaults: no agent may publish, send, spend, or touch real customer data. A surface with real side effects gets a **scratch tenant**, never a production identity. Name the tenant before round 1.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Path map | Written before any testing, from contract, docs and entry points: happy paths · boundaries · state transitions · concurrency and idempotency · cross-tenant and authorization. Each path is **uncovered → exercised → hardened**; only Phase 4 grants the last. | `references/path-map.md` |
| 2 Liveness | One trivial known-true probe against the target before round 1 and after any suspiciously clean round. Not optional: a harness pointed at a stale server once reported every real fix as refuted for two full rounds. | `references/rounds.md` |
| 3 Rounds | Typed, never mixed. **Constructive** (map slice + contract: demonstrate the path holds) moves paths to exercised. **Adversarial** (contract only, no hints: find what it mishandles) adds paths to the map; run at least one, and again whenever constructive rounds go quiet. **Verify** (one path's claim, not the fix) confirms with a control pair. Findings are one reproducible sentence against the surface. | `references/rounds.md` |
| 4 Harden | Per failing path: smallest fix → leave a check → **prove the check goes red** with the defect reintroduced before trusting green → one commit → log path, SHA, and proof. Two honest attempts, then park. | `references/harden.md` |
| 5 Carry forward | One running map across rounds: uncovered (oldest first) · exercised (honest middle, not done) · hardened. A path that breaks again is reopened with its history, never filed as new. | `references/path-map.md` |
| 6 Verdict | **Covered** when every path is hardened, every check still goes red on its defect, and the last adversarial round added nothing — stated as "this map, as of this run". Otherwise **stopped** (budget, or three rounds hardening nothing) with the uncovered list. | `references/report.md` |
| 7 Report | `plan/harden-<date>.md` in ATTEST form with the fixed summary block: rounds and families, map counts, verdict, hardened / added / reopened / uncovered lists, Needs you. End by naming whether the surface is ready for `/live-check-nt` or `/release-nt`; the uncovered list feeds `/autopilot-nt`. | `references/report.md` |
