---
description: "Harden an agent surface — map the paths it claims to support, then work the map with independent agents from different model families: constructive rounds prove a path holds, adversarial rounds find paths the map missed. Every failure is fixed and left behind a check proven able to fail. Writes plan/harden-<date>.md."
argument-hint: "[surface, e.g. \"the public API\" | budget, e.g. \"6 rounds\" | resume]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "a surface whose contract can be stated — an agent-facing API, an MCP server, a CLI other tools depend on, a public app boundary. Paths that only exist at runtime need a real reachable instance (live-check-nt's trigger test decides); paths that don't, don't"
exit: "every path in the map is hardened — carries a check that has been shown to go red against the defect it guards — OR the budget is exhausted with an honest uncovered list"
writes: "plan/harden-<date>.md; workplan checkboxes for anything deferred to /autopilot-nt"
---

`/harden-nt` makes a surface harder than it was, and produces the evidence. It works from a **path map** — what the surface claims to support — and drives that map with independent agents from **different model families**, two ways at once: **constructively**, showing a claimed path holds, and **adversarially**, finding the paths the map forgot. Both are discovery; the constructive half proves what is there, the adversarial half grows the map. Nothing counts as covered until the check guarding it has been **proven able to fail** — a check that stays green with or without the defect is not a check, and catching that is why this command exists.

Use it before calling an agent surface ready: an API other agents call, an MCP server, a CLI contract other tools depend on, a public app boundary. Where `/forward-pass-nt` audits code once and `/live-check-nt` proves one flow once, this is the iterated version over the whole path space. For a single flow you already suspect is broken, `/live-check-nt` is cheaper.

`$ARGUMENTS` (optional): the surface (a URL, an API base, "the CLI"), and/or a budget (default: **6 rounds or 4 hours, whichever ends first** — the same shape as `/autopilot-nt`). `resume` continues the most recent open `plan/harden-*.md`.

If the current directory isn't a git repo, ask which project — don't guess.

## Phase 0 — The launch contract

State back, then go — a veto window, not a questionnaire, same as `/autopilot-nt` Phase 0:
- **The surface**, and which of its paths need a live instance versus which can be exercised statically.
- **The roster — heterogeneous by default.** Independent agents per round (default 3), drawn from **different model families** wherever more than one is configured. Different families fail differently; three hats on one model is one perspective wearing three hats. Homogeneous-but-isolated (same stack, separate context and tenant, no shared memory) is the fallback — name it as a downgrade when you take it.
- **Isolation contract** — each agent gets its own tenant, branch or key where the surface supports it, and **never** the maker's diff, reasoning, or repo access. Black-box, driving the surface exactly as an outside caller would.
- **Budget and stop conditions** (Phase 5).
- **Stop-lines** — `/autopilot-nt` Phase 4 defaults: no agent may publish, send, spend, or touch real customer data. If the surface has real side effects, agents run against a **scratch tenant**, never a production identity. Name the tenant before round 1.

## Phase 1 — Build the path map

Before any round, write down what the surface claims to support. This is the artifact the whole command produces, and it exists before any testing does. Draw it from the contract, the docs, and the code's entry points — not from what you think is risky:

- **Happy paths** — the operations the surface is for, one line each.
- **Boundaries** — empty, absent, oversized, malformed, wrong type, wrong permission.
- **State transitions** — what must happen before what; what a second call does.
- **Concurrency and idempotency** — same call twice, two callers at once, retry after partial failure.
- **Cross-tenant and authorization** — what one caller must not be able to reach.

Each path gets a state: **uncovered** → **exercised** → **hardened**. Only the last one means anything, and only Phase 4 can grant it.

The map is a human artifact and will be incomplete. That is what the adversarial rounds are for.

## Phase 2 — Prove the target is alive

Before round 1, and again any time a round returns suspiciously clean: run one trivial, known-true probe and confirm it answers correctly — a health check, a known record, a marker string. Not optional. The costliest failure this pattern has hit was a harness silently pointed at a stale target: a kill command matched nothing, a prior server kept running, two full rounds ran against it, and every real fix in those rounds came back reported as refuted. A round is worthless if the target isn't the target you think it is.

## Phase 3 — Rounds: constructive, adversarial, verify

Every round is typed, and the type changes the brief. Keep them separate — mixed briefs return mushy findings.

- **Constructive round** (the default while the map has uncovered paths). Hand each agent a slice of the map and the surface's contract: *"demonstrate that this path behaves as specified, and show your input and output."* A path that holds moves to **exercised**. A path that does not is a finding, stated as one sentence against the surface.
- **Adversarial round** (run at least one, and again whenever constructive rounds stop finding anything). Brief each agent with the contract and nothing else: *"find a case this surface does not handle correctly."* No hints toward known weak spots. Every finding here **adds a path to the map** — that is the point of the round, and the map is what you keep.
- **Verify round** (a specific path, marked hardened). Brief the agent with only the path's one-sentence claim and how to reach the surface — not the fix, not the diff. Confirm with a **control**: the exact input that used to fail alongside a known-good input, side by side. A single passing run doesn't isolate a fix; the pair does.

Findings are one sentence each, addressed to the surface rather than the code — "`POST /v1/domains` stores `parent_domain_id` unvalidated" is a finding; "the validation logic looks wrong" is not. A finding without a reproducible input is not a finding; ask for one before recording it.

## Phase 4 — Harden: fix, then prove the check bites

For each failing path, in order:
1. **Fix it** — the smallest change against the surface's actual contract, same discipline as `/autopilot-nt` Phase 2.
2. **Leave a check behind.** The fix is half the work; the path is not hardened until something will catch its return.
3. **Prove the check can fail — before believing it can pass.** Deliberately reintroduce the defect (revert the fix, or hand-craft the bad input again) and confirm that specific check goes red. Only then run it against the real fix and confirm green. A check green through both is not a check — find the real cause and rewrite it; don't note the anomaly and move on.
4. **Commit it** — one focused commit per path.
5. **Log it** in `plan/harden-<date>.md`: the path, the fix SHA, and the proof (what red looked like, what green looks like now). The path moves to **hardened**.

A path two honest fix attempts cannot close is parked, not forced — `/autopilot-nt` Phase 3 discipline.

## Phase 5 — Carry the map forward

One running document across rounds, never restarted. The map is the state:
- **Uncovered** — in the map, not yet exercised. Oldest first.
- **Exercised** — demonstrated to hold, but carrying no proven check. Honest middle state; don't let it pass for done.
- **Hardened** — fixed or confirmed, with a check proven able to fail.

A path a later round breaks again is **reopened**, not filed as new — it carries its prior record forward, so the next attempt starts from the earlier failure's history. Every round runs against the **current** surface, warm-started from all prior fixes.

## Phase 6 — Covered or stopped

**Covered** when every path is hardened, every hardened path's check still goes red on re-run against its defect, and the last adversarial round added no new paths. Write it as what it is — *this map, fully hardened, as of this run* — not a permanent guarantee about a surface.

Otherwise **stopped**: the budget ran out, or three consecutive rounds hardened nothing while paths remain uncovered. Report the uncovered list either way.

## Phase 7 — The report

Write `plan/harden-YYYY-MM-DD.md` in ATTEST form: surface and tenant (Phase 0), the liveness probe (Phase 2), each round typed and dated, the map with every path's state (Phase 5), and the verdict:

```
Harden on <surface> — <N> rounds, <M> agents/round (<families>).
Map: <T> paths — <H> hardened, <E> exercised, <U> uncovered
Verdict: COVERED (map fully hardened, last adversarial round added nothing) | STOPPED (<budget|diminishing returns>)

Hardened this run:
  - <path> — fixed <SHA> — check red on <defect>, green on <fix>

Added by adversarial rounds:
  - <path> — found round <N> — <state>

Reopened:
  - <path> — broke again in round <N> — see prior proof

Uncovered:
  - <path> — <needs a human call | parked after two attempts>

Needs you: <anything a stop-line parked, or a design call Phase 4 couldn't make alone>
```

End by naming whether the surface is ready for `/live-check-nt` (one final deployed-artifact replay) or `/release-nt`, and note that an uncovered list feeds `/autopilot-nt` like any other fix-workplan.
