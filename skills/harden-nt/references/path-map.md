## Phase 1 — Build the path map

Before any round, write down what the surface claims to support. This is the artifact the whole command produces, and it exists before any testing does. Draw it from the contract, the docs, and the code's entry points — not from what you think is risky:

- **Happy paths** — the operations the surface is for, one line each.
- **Boundaries** — empty, absent, oversized, malformed, wrong type, wrong permission.
- **State transitions** — what must happen before what; what a second call does.
- **Concurrency and idempotency** — same call twice, two callers at once, retry after partial failure.
- **Cross-tenant and authorization** — what one caller must not be able to reach.

Each path gets a state: **uncovered** → **exercised** → **hardened**. Only the last one means anything, and only Phase 4 can grant it.

The map is a human artifact and will be incomplete. That is what the adversarial rounds are for.

## Phase 5 — Carry the map forward

One running document across rounds, never restarted. The map is the state:
- **Uncovered** — in the map, not yet exercised. Oldest first.
- **Exercised** — demonstrated to hold, but carrying no proven check. Honest middle state; don't let it pass for done.
- **Hardened** — fixed or confirmed, with a check proven able to fail.

A path a later round breaks again is **reopened**, not filed as new — it carries its prior record forward, so the next attempt starts from the earlier failure's history. Every round runs against the **current** surface, warm-started from all prior fixes.
