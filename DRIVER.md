# DRIVER.md — Agent-Ready by Design (v0.1)

The fourth doctrine. ATTEST governs how work is *reported*, SUBSTANCE what counts as *delivered*, STATES when work *advances* — DRIVER governs how the things we build feel to the agent that drives them. Hard rule ⑥ (two doors, one core) guarantees agents get **parity** access to every product; DRIVER says the agent door must also be **ergonomic**: legible, typed, bounded, crash-safe. It binds the *products* ntkit builds, not the commands themselves (those follow AUTHORING.md).

Distilled from one full application (vise, 2026-09-01) and convergent with independent practice (vgpu's agent-first diagnostics, GitNexus, verification-skill harnesses). v0.1 — expected to accrete with each build that runs the pass.

## The invocation

Run this pass **once the first spec draft exists and before code** — at scaffold time there is nothing to reshape; after the build it is a retrofit. Run it again before public release. The prompt, verbatim:

> OK, now I want you to think deeply about how to make this entire system as agent-intuitive, agent-ergonomic, and agent-accretive as you can possibly imagine. Put yourself in the driver's seat and imagine that YOU are the one using this system and driving it. What would most enable you to do an awesome job understanding the situation accurately and optimally controlling everything to drive the best and most accurate results possible, with the least expenditure of resources?
>
> Then make all the requisite changes to the various design documents and plans accordingly. Don't just think of the project as an assemblage of various parts or components: really try to profoundly and deeply conceptualize it as a synthetic SYSTEM that is maximally coherent, cohesive, modular, and interconnected, forming a tower of linked abstractions that are maximally legible to you as an agent. Really ruminate and meditate on all of this incredibly deeply before responding or taking any actions.

The output of the pass is the project's **agent contract** — a §0-style section in its spec that subsequent design decisions answer to.

## The ten principles

Ground them in the driver's real failure modes: an agent is context-poor, liable to be killed mid-turn, prone to circling on long campaigns, and prone to rationalizing its own failures. Design for that user.

1. **One perception act.** A single entry point (`status`, a brief, an index) renders the whole situation in one bounded read. The agent's first move is never exploration.
2. **Machine-decidable, not merely machine-readable.** Structured output everywhere; every outcome carries a typed class and a named remedy. The agent branches on codes and closed vocabularies, never on prose.
3. **One verdict per distinct next action.** Exit codes / result classes map 1:1 to what the agent should do next. Conflating two forces the agent to investigate what the tool already knows.
4. **Bounded output, always.** Output grows with divergence and signal, never with repo, history, or collection size. Green is one line. No dumps.
5. **Every failure names its remedy.** The error message is the documentation, delivered at the moment of need — what happened · what it means · the exact next command.
6. **Crash-safe and idempotent.** Agents die mid-turn. Every write atomic; interrupted work leaves old state or new state, never a hybrid; everything safe to re-run.
7. **The tool holds the memory.** Agent context is ephemeral; the tool keeps the trajectory (journal, log, lockfile) and renders it on demand. The anti-circling device lives in the product, not in the agent's head.
8. **Accretive by mechanism, not intention.** Progress locks in structurally — ratchets, escaped-defect-becomes-coverage, append-only records — so the system gets better with use even when no one remembers to improve it.
9. **A tower, not a toolbox.** Layers of linked abstractions, each consuming only the layer below, each independently legible; the agent enters at the altitude its task needs.
10. **The evaluator stays outside the loop — fail closed.** Whatever judges the agent (gates, verifiers, locks) must be unwritable by it, and when judgment itself is compromised the verdict is indeterminate, never green. A judge that can be ejected is not a judge.

## Self-check for a project's agent contract

- [ ] Named single perception act
- [ ] Closed vocabularies for verdicts and remedies; structured output mode
- [ ] Output-size bound stated (what it grows with)
- [ ] Crash-safety story stated
- [ ] Where the trajectory lives, and what renders it
- [ ] At least one accretion mechanism
- [ ] The layer tower drawn, one line per layer
- [ ] The evaluator boundary named, with its fail-closed behavior
