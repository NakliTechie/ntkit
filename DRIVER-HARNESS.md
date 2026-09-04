# DRIVER-HARNESS.md — Building and Attacking an Agent Surface (v0.1)

DRIVER's operational companion. `DRIVER.md` says *what* an agent surface must be; `/spar-nt`
says *how* to attack one that's already live. This doc is the connective tissue: the loop that
sequences the two passes, and the one piece neither owns portably — the **cold-runner harness**
that makes the attack rounds real instead of imagined.

Distilled from one full retrofit run end to end (Pulse, `feat/agent-contract-driver-pass`,
2026-09-02/03): a §0 agent contract built across seven phases, then eighteen rounds of isolated
cold agents that turned every behavioural fix on the branch into a sentence an outside agent
wrote first. v0.1 — expected to accrete with each build that runs the loop.

---

## The loop

Four passes, in order. Each has a home; this doc supplies only pass 2 and the glue.

1. **BUILD the surface — `DRIVER.md`.** Run its verbatim invocation once the first spec draft
   exists (before code) or as a retrofit against what exists. Output: the project's §0 agent
   contract — the tower, the single perception act, closed remedy vocabulary, idempotency on
   every spend, the trajectory store, parity ratchets, evaluator-outside-the-loop. Do not attack
   a surface that has no contract; there is nothing to hold the findings against.

2. **STAND UP the cold-runner fleet — this doc, §"The harness".** The infrastructure `/spar-nt`
   assumes but does not ship: heterogeneous isolated verifiers, per-runner tenants, a liveness
   canary, a mission-brief template.

3. **ATTACK and iterate — `/spar-nt`.** Round-based, cold, heterogeneous. Explore rounds grow the
   backlog; verify rounds close it with a canary. Converges when a full explore round finds
   nothing and every closed finding's canary still bites.

4. **CLOSE the structural gap — this doc, §"What the fast suite cannot see".** The one class of
   defect the cold agents find in minutes and no in-memory unit test can. A small live-backed
   smoke, run against the thing production actually uses.

The build is a one-shot design pass; the attack is an iterated verification pass; they are
**different questions** and neither substitutes for the other. "Make it agent-drivable" is
DRIVER. "Prove it is" is spar. This doc keeps them from being confused for one another.

---

## The harness — the portable, missing piece

Everything below is stack-agnostic. Ship it once per project as a `spar/` or scratchpad
launcher; the round scripts are throwaway but the contract is not.

### 1. Heterogeneous runners, not one model in three hats

Default three verifiers per round, and make them **different stacks** where more than one is
configured — e.g. Codex CLI over REST, opencode over REST, Claude over the MCP face. Three
stacks catch what one stack in three contexts does not: each has different default guesses about
where docs live, what a 404 means, how to authenticate. Homogeneous-but-isolated (same CLI,
separate context and tenant, no shared memory) is the fallback when only one stack exists — name
it as the downgrade, don't pretend it's the same thing.

### 2. The isolation contract — non-negotiable

Each runner gets its **own tenant, its own credential, and no repository access** — never the
maker's diff, reasoning, or source. It drives the surface exactly as an outside caller would,
black-box, from the published docs and nothing else. The moment a runner can see the fix, it
stops being a verifier and starts confirming your priors. This is the whole value: a test
asserts what you already thought of; a cold agent finds what you did not.

### 3. Prove the target is alive — before every round

The single costliest failure this pattern has hit: a restart command that matched nothing left
a stale server running, two full rounds attacked code hours behind the branch, and every real
fix came back reported as refuted. Rules, learned the expensive way:

- **Kill by what holds the port, not by a command-line pattern.** Process command lines lie
  (`tsx src/server.ts` on disk reads `.../tsx/dist/cli.mjs src/server.ts` in `ps`; `pkill -f`
  misses it). Kill the PID that owns the port.
- **Run a canary before the round returns.** One trivial known-true probe (a health check, a
  known record, a marker string the current build emits) confirms the target under attack is the
  target you think it is. Not optional. When a verification round refutes *everything*, suspect
  the harness before the work.

### 4. Round typing — explore vs verify are different questions

- **Explore round** (default, open backlog): brief each runner with the surface's contract/docs
  and nothing else — *"find a case this surface does not handle correctly, and state it in one
  sentence."* No hints toward known weak spots.
- **Verify round** (a specific fix, marked closed): brief with only the finding's one sentence
  and how to reach the surface — not the fix. Confirm with a **control**: the exact input that
  used to fail, side by side with a known-good input. A single passing run doesn't isolate a
  fix; the pair does.

The lesson that earned this split its own line: a round that verified nine claims *and* then
asked "find the nearest case each fix does NOT cover" produced five further defects — two of
them the sharpest of the run. "What is broken" and "what does this not cover" find different
things. Ask both.

### 5. Findings are one sentence, addressed to the surface, with a reproducible input

`POST /v1/domains stores parent_domain_id unvalidated` is a finding. `the validation looks
wrong` is not. No reproducible input → not yet a finding; ask for one before recording it. Each
finding closes as: smallest fix against the real contract → **canary** (reintroduce the defect,
watch the check go red, then green on the fix — a check that stays green through both is not a
check) → one focused commit → logged under the round it closed in.

### 6. The mission-brief template

Everything a cold runner gets. Fill the four blanks; hand over nothing else.

```
You are an autonomous agent with API access to <PRODUCT>, a <one line: what it does>.
Base URL: <URL>.  Credential: <the one key, and how to send it>.
You have NO documentation beyond what the service itself publishes, and NO source access.

Mission: <one concrete goal that exercises the surface — e.g. "get as far as you can
toward sending one real message, and report exactly what stopped you">.

Rules:
- Discover everything from the running service. Start wherever you think is right.
- Do not publish, send to real recipients, spend real money, or touch data outside your
  own tenant. If a step would, stop and report it as a blocker instead.
- Report each thing that blocked, surprised, or misled you as ONE sentence, each with the
  exact request that triggered it. A blocker without a reproducible request is not reported.
- At the end: the plan you'd give another agent to finish, with the human-only steps named.
```

The stop-lines in that brief are load-bearing: if the live surface has real side effects, every
runner uses a **scratch/sandboxed tenant**, never a production identity. State which tenant
before round 1.

---

## What the fast suite cannot see — close it, don't rewrite it

An in-memory-repository test suite (fast, no database, the right default for CI) is blind by
construction to exactly three classes — and cold agents driving a real server hit all three
within minutes:

1. **Constraint violations** — the in-memory stores have no constraints, so a check-then-insert
   race that Postgres rejects with a raw 500 passes every unit test.
2. **Driver type coercion** — in-memory data is already the right shape, so a row type that lies
   about what the real driver returns (a `string` claimed as `Date`) compiles and passes, then
   500s in production.
3. **Concurrency** — nothing in the suite races two writers, so the duplicate-under-one-key case
   is invisible.

Don't rewrite the suite — it's what keeps CI fast. Add a **second, much smaller** live-backed
smoke that provisions its own tenant through the public API and runs only the handful of checks
that need a real database (a unique-constraint violation, N concurrent identical creates under
one idempotency key, a raw-SQL aggregate, whatever your cold agents actually found). It exits
non-zero, so CI can run it against a scratch deployment. Every check in it should be a real
defect a cold agent found — not a hypothetical.

---

## The combined prompt — paste into any repo

Use this to run the whole loop end to end in a project that has no ntkit knowledge. It sequences
the two doctrine passes and this harness; where a step maps to a command you have, it says so.

> I want this project to be **fully drivable by an agent** — after one human-assisted
> authentication, an agent should be able to do everything a human operator can, through
> published, documented, agent-native interfaces. Run this as four passes, and stop for my
> decision only where a step is genuinely a human call.
>
> **Pass 1 — Build the surface.** Think deeply about how to make this entire system
> agent-intuitive, agent-ergonomic, and agent-accretive. Put yourself in the driver's seat:
> you are the agent using this. Give me a single **agent contract** (a §0 in the spec) with —
> one perception act that renders the whole situation in one bounded read; machine-*decidable*
> outcomes (every error a closed typed code carrying the exact next call as a remedy, not a
> link); output that grows with divergence, never with inventory; every spending/sending/
> provisioning call idempotent and safe to replay; a trajectory store the tool holds so a
> fresh-context agent replays instead of re-exploring; a layer tower where each layer consumes
> only the one below; and an evaluator (parity gate, remedy gate) that runs outside the surface
> it judges and fails closed. Then make the code match the contract, phase by phase, green at
> each phase.
>
> **Pass 2 — Stand up cold verifiers.** Create three isolated agents on their own tenants and
> keys, with NO source access and NO sight of the diff — heterogeneous stacks if more than one
> is available. Before each round, kill the old server by the PID that owns the port and prove
> the new one is live with a trivial known-true probe. Brief each with the mission template
> (goal + base URL + the one key + stop-lines), and nothing else.
>
> **Pass 3 — Attack in rounds until it converges.** Explore rounds: "find a case this surface
> does not handle correctly, one sentence, with the request that triggers it." Verify rounds:
> re-attack each fix with a control — the old bad input beside a good one. For every finding:
> smallest fix, then prove the check can go RED before you trust it GREEN, then one commit,
> then log it. Converge when a full explore round finds nothing and every canary still bites;
> stop honestly with a backlog if the round/time budget runs out. (If you have `/spar-nt`, this
> pass IS `/spar-nt` — run it.)
>
> **Pass 4 — Close the structural gap.** Add a small live-backed smoke covering the classes the
> in-memory suite can't see — constraint violations, driver coercion, concurrency — seeded from
> exactly what the cold agents found. Non-zero exit, runnable in CI against a scratch tenant.
>
> Report in ATTEST form: the contract, the phase greens, each round's findings and canary-proven
> closures, the converged/stopped verdict, and anything a human must decide.

---

## Self-check for a completed loop

- [ ] An agent contract exists and the code answers to it (DRIVER self-check passes)
- [ ] Verifiers were heterogeneous (or the homogeneous downgrade was named), isolated, source-blind
- [ ] A liveness canary ran before every round; the server was killed by port, not by pattern
- [ ] Explore and verify rounds were kept separate; both questions were asked
- [ ] Every closed finding has a canary proof (red-then-green), not just a green
- [ ] A live-backed smoke covers constraints / coercion / concurrency, seeded from real findings
- [ ] The run converged, or stopped with an honest backlog — never declared clean on a quiet round
