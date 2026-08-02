# SUBSTANCE — Tangible Progress, Anti-Ceremony, Honest Credit

The purpose of any project is working, deployable software delivered accretively in the
shortest time compatible with correctness, performance, reliability, and innovation.
**Process exists to serve that outcome; it must never become the product.**

Where [`STATES.md`](STATES.md) names the session state machine and [`ATTEST.md`](ATTEST.md)
governs how the agent reports, this file governs **what counts as delivered work and how it
earns credit** — binding human-directed sessions and `/autopilot-nt` agent-swarm runs alike.

---

## 1. No process theater

Certificates, ledgers, dashboards, meta-reports, and process documents are **not progress**.
A process artifact earns its place **only when it is a hard gate for a named feature or
capability** — the committed verifier a `/walkthrough-nt` leaves behind and the release
evidence a `/release-nt` gate requires qualify; self-referential paperwork does not.
Choosing process artifacts because they are easy and low-risk is **reward hacking**, and is
treated as such.

(ntkit already leans this way on purpose: `plan/` is gitignored scaffolding, never shipped;
the `/walkthrough-nt` harness is committed to the repo *because* it is a real gate, not
decoration.)

## 2. Feature-first ratio

The overwhelming majority of open work items must deliver **runnable behavior** — code,
schemas, and contracts an end user or a consuming agent can actually exercise. Process/ops
items are **capped** (guideline: at most ~5% of open items in `pending.md` / `workplan.md`),
and **each must name the feature work it gates**. A process item that gates nothing does not
get created.

## 3. Honesty is absolute

Never fake a test, present a fixture or mock as live proof, weaken an assertion to make it
pass, hard-code a success path, or close work that is not done. **A false close is reopened
with an incident note on the record.** This is the state machine's "done is the verifier's
word" applied to the work itself, and the same discipline `ATTEST.md` enforces on every claim.

## 4. Refusal is not delivery

A correctly typed refusal is far better than a fabricated result — and far less valuable than
the real capability. Implementing **only** the refusal or guard path earns **partial credit
at most**; it never closes a feature work item. Full credit requires the positive capability
implemented for real, tested, and verified. **Mark refusal-only states explicitly** — a
`refusal-only` label plus a follow-up item — so they read as unfinished, never as shipped.

## 5. Encoded into the work, not bolted on

These rules bind human-directed sessions and agent-swarm runs equally, and must be **encoded
into the acceptance criteria of the work items themselves**: a `workplan.md` chunk item names
the runnable behavior that proves it done, and the `/walkthrough-nt` + `/autopilot-nt` +
`/release-nt` gate is where **"done is the gate's word"** is enforced — never the agent's
self-report. Checking the §2 ratio and hunting hard-coded success paths are a natural part of
a `/forward-pass-nt` or `/replan-nt` pass, so the discipline stays checkable, not aspirational.

---
*Delivery rigor — the third pillar beside `STATES.md` (the machine) and `ATTEST.md` (the
report). Substance over ceremony; credit only for what runs.*
