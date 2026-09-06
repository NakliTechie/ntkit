## Phase 2 — Prove the target is alive

Before round 1, and again any time a round returns suspiciously clean: run one trivial, known-true probe and confirm it answers correctly — a health check, a known record, a marker string. Not optional. The costliest failure this pattern has hit was a harness silently pointed at a stale target: a kill command matched nothing, a prior server kept running, two full rounds ran against it, and every real fix in those rounds came back reported as refuted. A round is worthless if the target isn't the target you think it is.

## Phase 3 — Rounds: constructive, adversarial, verify

Every round is typed, and the type changes the brief. Keep them separate — mixed briefs return mushy findings.

- **Constructive round** (the default while the map has uncovered paths). Hand each agent a slice of the map and the surface's contract: *"demonstrate that this path behaves as specified, and show your input and output."* A path that holds moves to **exercised**. A path that does not is a finding, stated as one sentence against the surface.
- **Adversarial round** (run at least one, and again whenever constructive rounds stop finding anything). Brief each agent with the contract and nothing else: *"find a case this surface does not handle correctly."* No hints toward known weak spots. Every finding here **adds a path to the map** — that is the point of the round, and the map is what you keep.
- **Verify round** (a specific path, marked hardened). Brief the agent with only the path's one-sentence claim and how to reach the surface — not the fix, not the diff. Confirm with a **control**: the exact input that used to fail alongside a known-good input, side by side. A single passing run doesn't isolate a fix; the pair does.

Findings are one sentence each, addressed to the surface rather than the code — "`POST /v1/domains` stores `parent_domain_id` unvalidated" is a finding; "the validation logic looks wrong" is not. A finding without a reproducible input is not a finding; ask for one before recording it.
