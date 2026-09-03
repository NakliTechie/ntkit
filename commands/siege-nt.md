---
description: "The adversary — round-based, cold, heterogeneous verification against the real running surface; a check must prove it can fail before a clean round is trusted; findings get fixed and re-attacked until converged. Writes plan/siege-<date>.md."
argument-hint: "[surface to attack, e.g. \"the public API\" | round budget, e.g. \"8 rounds\" | resume]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "verifying or building, on a repo with a real running instance reachable by an isolated caller — local dev server, staging, or a scratch tenant of prod; live-check-nt's trigger test decides whether the surface qualifies"
exit: "a round returns zero new findings from every cold agent AND every closed finding's canary still proves alive — OR the round/time budget is exhausted with an honest backlog"
writes: "plan/siege-<date>.md; workplan checkboxes for anything deferred to /autopilot-nt"
---

`/siege-nt` is the kit's adversary. It doesn't read source and it doesn't trust a green check. It throws independent, cold verifiers at the real running surface, round after round, and only believes a "clean" result once it has proven the checks that produced it are capable of failing. Where `/forward-pass-nt` audits code once with fresh eyes and `/live-check-nt` proves one flow works once, `/siege-nt` is the iterated version: attack, fix, re-attack, until cold agents stop finding anything and the harness itself has been shown to still bite.

It formalizes a shape two projects reached independently from opposite directions — an agent-facing API (isolated cold agents finding real defects across eighteen rounds) and a deterministic CLI gate (whose own guards twice passed against the bug they existed for, undetected until deliberately checked) — plus what a published loop framework (Harness-of-Harness: Planner → Developer → read-only QA, evidence state carried across loops) got right about structure but never addressed: proving the verifier itself isn't dead. `/siege-nt` is both halves in one command.

Use it before calling any live-facing surface — an API meant for other agents, a public app boundary, a CLI contract other tools depend on — "ready." Not for a pure library with full deterministic tests (nothing live to attack; `/forward-pass-nt` already covers it), and not for one specific flow you already suspect is broken (`/live-check-nt` is cheaper for that).

`$ARGUMENTS` (optional): the surface to attack (a URL, an API base, "the CLI"), and/or a round budget (default: **6 rounds or 4 hours, whichever ends first** — same shape as `/autopilot-nt`'s budget discipline). `resume` continues the most recent open `plan/siege-*.md` instead of starting a new run.

If the current directory isn't a git repo, ask which project — don't guess. If no real running instance is reachable (Phase 0/1), refuse: don't attack a mockup and call it verified.

## Phase 0 — The launch contract

State back, then go — a veto window, not a questionnaire, same as `/autopilot-nt` Phase 0:
- **The surface and the trigger** — what's being attacked and why it needs a live check at all. Apply `/live-check-nt`'s Phase-0 test (heavy runtime path, real-device API, cross-tenant behavior, timing/idempotency) and name which fired.
- **The cold-agent roster** — how many independent verifiers per round (default 3), and whether they're **heterogeneous** (different harness/model/CLI, where more than one is configured) or homogeneous-but-isolated (same stack, separate context/tenant, no shared memory). Heterogeneous is the available upgrade — three different stacks catch what one stack in three hats does not; use it when the setup allows, name it as a default to override otherwise.
- **Isolation contract** — each cold agent gets its own tenant/branch/API key where the surface supports it, and **never** the maker's diff, reasoning, or repo access. Black-box only, driving the surface exactly as an outside caller would.
- **Round budget and stop conditions** (Phase 5).
- **Stop-lines** — same defaults as `/autopilot-nt` Phase 4: no cold agent may publish, send, spend, or touch real customer data. If the live surface has real side effects (creates resources, sends messages, moves anything), the cold agents run against a **scratch/sandboxed tenant** — never a production identity. State which tenant before round 1.

## Phase 1 — Prove the target is alive

Before round 1, and again any time a round returns suspiciously clean: run one trivial, known-true probe against the target and confirm it answers correctly (a health check, a known record, a marker string). Not optional. The single costliest failure this pattern has hit was a harness silently pointed at a stale or dead target — a kill command that matched nothing left a prior server running, two full rounds ran against it, and every real fix in those rounds came back reported as refuted. A siege round is worthless if the target under attack isn't the target you think it is.

## Phase 2 — Round: explore or verify

Every round is typed, and the type changes the brief — exploration and verification rounds surface genuinely different, non-overlapping findings when kept separate:

- **Explore round** (default for an open or growing backlog): brief each cold agent with the surface's contract/docs and nothing else — "find a case this surface does not handle correctly, and state it as one sentence." No hints toward known weak spots; the value is a genuinely outside attempt.
- **Verify round** (a specific prior finding, marked fixed): brief the cold agent with only the finding's one-sentence claim and how to reach the surface — not the fix, not the diff. It confirms the fix with a **control**: the exact input that used to fail, alongside a known-good input, side by side. A single passing run doesn't isolate a fix; the pair does.

Each cold agent returns findings as **one sentence each**, addressed to the surface, not the code — "`POST /v1/domains` stores `parent_domain_id` unvalidated" is a finding; "the validation logic looks wrong" is not. A finding without a reproducible input is not a finding — ask for one before recording it.

## Phase 3 — Fix, verify, close — the canary is mandatory

For each confirmed finding, in order:
1. **Fix it** — the smallest change against the surface's actual contract, same discipline as `/autopilot-nt` Phase 2 step 2.
2. **Prove the check can fail — before believing it can pass.** Before marking a finding closed, deliberately reintroduce the defect (revert the fix, or hand-craft the bad input again) and confirm the specific check goes red. Only then run it against the real fix and confirm green. A check that stays green through both is not a check — this is where a guard silently matching the wrong field, or a passing suite hiding a broken behavior, gets caught. Find the real cause and rewrite the check; don't just note the anomaly and move on.
3. **Commit it** — one focused commit per finding, by path.
4. **Log it** in `plan/siege-<date>.md`, under the round it closed in: the finding sentence, the fix commit SHA, and the canary proof (what red looked like, what green looks like now).

A finding a fix attempt cannot close after two honest tries is parked, not forced — same discipline as `/autopilot-nt` Phase 3.

## Phase 4 — Carry state forward, round to round

The siege report is one running document across rounds, not restarted each time — two states, kept separate, the same split Harness-of-Harness formalizes as artifact vs. evidence:
- **Backlog** — open findings, one line each, oldest first.
- **Closed** — findings with their canary proof, per Phase 3.

A finding a later round's cold agent breaks again is **reopened**, not filed as new — it carries its closed record forward, so the next fix attempt starts from the earlier failure's full history instead of rediscovering it. Round N's cold agents always attack the **current** live surface, warm-started from every prior round's fixes — never a fresh copy, never round 1's state.

## Phase 5 — Converge or stop

A round **converges** (siege is done) when every cold agent in an explore round returns zero new findings **and** the closed list's canaries are still all green (re-run them; a canary the fix later broke is a reopened finding, back to Phase 3). Converged → the surface is siege-clean as of this run; write it plainly, not as a permanent guarantee.

Otherwise, siege **stops** without converging when the round or time budget (Phase 0) runs out, or when three consecutive rounds close zero findings while the backlog stays nonempty (diminishing returns — the remainder needs a human decision or a different attack surface, not more rounds). Report the honest backlog either way.

## Phase 6 — The report

Write `plan/siege-YYYY-MM-DD.md` in ATTEST form: target + trigger + tenant (Phase 0), the liveness canary result (Phase 1), each round typed and dated with its findings and closures, the running Backlog / Closed lists (Phase 4), and the verdict:

```
Siege on <surface> — <N> rounds, <M> cold agents/round (<roster>).
Verdict: CONVERGED (zero new findings, all canaries green) | STOPPED (<budget|diminishing returns>) — <K> open

Closed this run (canary-proven):
  - <finding> — fixed <SHA> — canary: red on <bad input>, green on <fix>

Reopened:
  - <finding> — broke again in round <N> — see prior canary proof

Backlog:
  - <finding> — <why not closed: needs a human call | parked after two attempts>

Needs you: <anything a stop-line parked, or a design call Phase 3 couldn't make alone>
```

End by naming whether the surface is trustworthy enough for `/live-check-nt` (one more, final deployed-artifact replay) or `/release-nt`, and that an unconverged run's backlog feeds `/autopilot-nt` the same way any other fix-workplan does.
