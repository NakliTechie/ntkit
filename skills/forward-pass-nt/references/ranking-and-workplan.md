## Phase 3 — Aggregate, dedupe, rank, assign IDs

Collect all findings. Dedupe across subagents. Rank by severity and **assign each a stable ID** so it can be referenced everywhere downstream (workplan, progress log, commits):

- **Critical → `C1, C2, …`** — exploitable security hole, data loss, or a bug that breaks core functionality in normal use
- **High → `H1, H2, …`** — likely-hit bug or real security weakness; fix before shipping
- **Medium → `M1, M2, …`** — real issue, narrower blast radius or rarer trigger
- **Low → `L1, L2, …`** — minor bug or hardening opportunity
- **Stray → `S1, S2, …`** — dead/leftover code (separate track, not severity-ranked)
- **Stub → `SB1, SB2, …`** — stub masquerading as done (separate track). A live-path/claimed-done stub ALSO gets a severity ID (usually C/H) — cross-reference the two so a fake-done section shows up in both places and can't be lost.
- **Test value → `T1, T2, …`** — a test that costs maintenance without protecting anything, or a production seam that exists only for tests (separate track). Each carries its recommendation (`D` delete · `C` consolidate · `F` fix the assertion · `seam` remove a test-only production seam) plus the keeper test that still proves the contract and the command that runs it. A vacuous test that hides a live defect (a negative that passes because the guard it claims to test is missing) ALSO gets a severity ID.
- **Agent-readiness → `AR1, AR2, …`** — a missing/incomplete agent-facing door (separate track). A gap that's also live and consequential right now (an unstaged mutating manifest entry, a reachable capability with no door at all) ALSO gets a severity ID, same cross-reference rule as a live-path Stub. A pure ergonomics gap (DRIVER's self-check) with no live caller yet stays AR-only.

Each finding: `**ID** [Bug|Security|Stray|Stub|Test|Agent-readiness] path:line — what it is · why it matters · suggested fix`. For a Stub, name the masquerade explicitly: what's claimed (and where) vs. what the code actually does. For an Agent-readiness gap, name which check it fails (door missing / parity gap / unstaged mutation / DRIVER principle / attribution) and, for a parity gap, the specific UI action with no manifest counterpart. For a Test finding, name the hunting class, the keeper, and the command that runs the keeper.

**Severity anchor for Security findings** (adapted from [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill), MIT): the discriminator is whether the result *fully defeats* an explicit control with real consequences, or only weakens it. If you can't state the concrete damage, the severity is lower than it feels.
- **Critical** — unauthenticated actor gets code execution, full data-store access, or takeover of arbitrary accounts.
- **High** — an actor fully defeats an explicit control with real consequences: auth bypass, cross-tenant read/write, stored script execution hitting other users, authenticated code execution.
- **Medium** — a real boundary violation with limited blast radius, uncommon preconditions, or a narrow affected resource set.
- **Low** — disclosure of non-secret internals, or an effect that needs sustained effort for minimal gain.

**Anti-patterns — don't record these as Security findings** (same source): a missing best-practice with no reachable result (that's a Low or a hardening note, not a Critical); a defense-in-depth gap where an outer layer already stops the attack; guessed deployment/provider/browser behavior not visible in this repo (that's a `Worth a look` with the missing fact named, not a confirmed finding); a caller affecting only their own data (self-impact isn't a boundary violation); a parser/runtime effect reported stronger than what you actually observed.

**Preserve dismissals — don't silently drop.** When you discard something as a false positive or non-issue, record it in a dedicated **"False positives / non-issues (verified)"** list WITH the one-line reasoning that cleared it (e.g. `C3 — false positive: getStockOnHand sums batches only; the opening-stock column is never added to a total`). This stops the next forward pass from re-flagging it. Still drop pure linter/typechecker/CI noise without ceremony.

Keep a short **"Worth a look (lower confidence)" → `W1, W2, …`** bucket for fresh-eyes hunches you couldn't fully verify — don't hide them, don't inflate their severity.

## Phase 4 — Batch the findings into a fix-workplan

Turn the actionable findings (everything except false-positives/non-issues) into an **ordered, batched workplan** — the executable counterpart to the findings list:

- **Group into themed batches** by area/subsystem (e.g. "Transaction integrity", "Input validation", "Auth"), not by severity — related fixes that touch the same code travel together.
- **Order batches for execution.** Put a keystone first — a batch others depend on — and mark it: `## Batch A — <theme>  (keystone)`. Respect sequencing.
- **Tri-state checkboxes** on every item: `[ ]` open · `[x]` done · `[~]` partial.
- **Each item carries** its finding ID, precise location, and a one-line "what + why it works": `- [ ] **H5** <fix> (path:line). <one-line rationale>.`
- **`[test]` markers** — append e.g. **[test: <how>]** to any item whose fix can't be verified by static reasoning or unit tests and needs a runtime check.
- **Test-value items (`T`) are gated.** A `D` or `C` item is not done until the named keeper goes red under one deliberate mutation of the production code it guards, with the source restored byte for byte afterwards. A guards-nothing `D` inverts the check: the named mutation leaves the deleted test green. An `F` item is done when the repaired test goes red under that mutation. A `seam` item is done when no non-test caller remains (`grep`) and the build and full suite pass. Batch `T` items by production owner, one owner per batch. A `T` item that also carries a severity ID goes in its severity batch instead.
- **Deferrals state why + what unblocks.** A `[~]` partial or deferred item must say what's done, what's left, and what would un-defer it — and point at `/decide-nt` when the blocker is a decision: `DEFERRED: needs a versioned-hash migration story — decide first (/decide-nt).`
