## Phase 3 — Aggregate, dedupe, rank, assign IDs

Collect all findings. Dedupe across subagents. Rank by severity and **assign each a stable ID** so it can be referenced everywhere downstream (workplan, progress log, commits):

- **Critical → `C1, C2, …`** — exploitable security hole, data loss, or a bug that breaks core functionality in normal use
- **High → `H1, H2, …`** — likely-hit bug or real security weakness; fix before shipping
- **Medium → `M1, M2, …`** — real issue, narrower blast radius or rarer trigger
- **Low → `L1, L2, …`** — minor bug or hardening opportunity
- **Stray → `S1, S2, …`** — dead/leftover code (separate track, not severity-ranked)
- **Stub → `SB1, SB2, …`** — stub masquerading as done (separate track). A live-path/claimed-done stub ALSO gets a severity ID (usually C/H) — cross-reference the two so a fake-done section shows up in both places and can't be lost.

Each finding: `**ID** [Bug|Security|Stray|Stub] path:line — what it is · why it matters · suggested fix`. For a Stub, name the masquerade explicitly: what's claimed (and where) vs. what the code actually does.

**Preserve dismissals — don't silently drop.** When you discard something as a false positive or non-issue, record it in a dedicated **"False positives / non-issues (verified)"** list WITH the one-line reasoning that cleared it (e.g. `C3 — false positive: getStockOnHand sums batches only; the opening-stock column is never added to a total`). This stops the next forward pass from re-flagging it. Still drop pure linter/typechecker/CI noise without ceremony.

Keep a short **"Worth a look (lower confidence)" → `W1, W2, …`** bucket for fresh-eyes hunches you couldn't fully verify — don't hide them, don't inflate their severity.

## Phase 4 — Batch the findings into a fix-workplan

Turn the actionable findings (everything except false-positives/non-issues) into an **ordered, batched workplan** — the executable counterpart to the findings list:

- **Group into themed batches** by area/subsystem (e.g. "Transaction integrity", "Input validation", "Auth"), not by severity — related fixes that touch the same code travel together.
- **Order batches for execution.** Put a keystone first — a batch others depend on — and mark it: `## Batch A — <theme>  (keystone)`. Respect sequencing.
- **Tri-state checkboxes** on every item: `[ ]` open · `[x]` done · `[~]` partial.
- **Each item carries** its finding ID, precise location, and a one-line "what + why it works": `- [ ] **H5** <fix> (path:line). <one-line rationale>.`
- **`[test]` markers** — append e.g. **[test: <how>]** to any item whose fix can't be verified by static reasoning or unit tests and needs a runtime check.
- **Deferrals state why + what unblocks.** A `[~]` partial or deferred item must say what's done, what's left, and what would un-defer it — and point at `/decide-nt` when the blocker is a decision: `DEFERRED: needs a versioned-hash migration story — decide first (/decide-nt).`
