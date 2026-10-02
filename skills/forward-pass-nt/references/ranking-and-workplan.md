## Phase 3 — Aggregate, dedupe, rank, assign IDs

Collect and dedupe findings across subagents. Challenge the serious ones (below), then rank and assign each a **stable ID** that the workplan, progress log and commits cite:

- **Critical → `C1, C2, …`** — exploitable security hole, data loss, or a bug that breaks core functionality in normal use
- **High → `H1, H2, …`** — likely-hit bug or real security weakness; fix before shipping
- **Medium → `M1, M2, …`** — real issue, narrower blast radius or rarer trigger
- **Low → `L1, L2, …`** — minor bug or hardening opportunity
- **Stray → `S1, S2, …`** — dead/leftover code (separate track, not severity-ranked)
- **Stub → `SB1, SB2, …`** — stub masquerading as done (separate track). A live-path/claimed-done stub ALSO gets a severity ID (usually C/H); cross-reference the two so a fake-done section shows up in both places.
- **Test value → `T1, T2, …`** — a test that costs maintenance without protecting anything, or a production seam that exists only for tests (separate track). Each carries its recommendation (`D` delete · `C` consolidate · `F` fix the assertion · `seam` remove a test-only production seam) plus the keeper test that still proves the contract and the command that runs it. A vacuous test that hides a live defect (a negative that passes because the guard it claims to test is missing) ALSO gets a severity ID.
- **Agent-readiness → `AR1, AR2, …`** — a missing/incomplete agent-facing door (separate track). A gap that's also live and consequential now (an unstaged mutating manifest entry, a reachable capability with no door at all) ALSO gets a severity ID. A pure ergonomics gap with no live caller yet stays AR-only.

Each finding: `**ID** [Bug|Security|Stray|Stub|Test|Agent-readiness] path:line — what it is · why it matters · suggested fix`, with `path` written from the project root. A Stub names what's claimed (and where) vs. what the code does. An Agent-readiness gap names which check it fails (door missing / parity gap / unstaged mutation / DRIVER principle / attribution) and, for a parity gap, the UI action with no manifest counterpart. A Test finding names the hunting class, the keeper, and the command that runs the keeper. A Security finding also names its `ingress: path:line` (`references/security-classes.md`, "What counts as a finding").

**Severity anchor for Security findings** (adapted from [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill), MIT): the discriminator is whether the result *fully defeats* an explicit control with real consequences, or only weakens it. If you can't state the concrete damage, the severity is lower than it feels.
- **Critical** — unauthenticated actor gets code execution, full data-store access, or takeover of arbitrary accounts.
- **High** — an actor fully defeats an explicit control with real consequences: auth bypass, cross-tenant read/write, stored script execution hitting other users, authenticated code execution.
- **Medium** — a real boundary violation with limited blast radius, uncommon preconditions, or a narrow affected resource set.
- **Low** — disclosure of non-secret internals, or an effect that needs sustained effort for minimal gain.

**Caps for Security findings — rank by marginal capability** (adapted from [google/mantis](https://github.com/google/mantis) `mantis-calibrate`, Apache-2.0). A finding is worth what the attacker gains over the position they start from. A cap only lowers the ceiling; it never raises a finding.
- **Critical** needs a full trace: the ingress `path:line`, the sink `path:line`, and every guard between them named. A missing link caps it at **High**.
- **High** at most when the defect fires only under a non-default configuration.
- **Medium** at most when the attacker needs admin or owner rights and stays inside that domain; when a normal feature already gives them the same power (an admin pulling through a bug what the UI already lets them download); or when the defect fires only under a configuration the docs call insecure or dev-only.
- **Low** at most for a dependency CVE with no path shown from this app's input to the vulnerable function, for a precondition that already grants what the exploit gives (a shell user gaining a shell), and for a defect that fires only in a debug build, dev mode, or test route that production cannot reach.

**Not Security findings** (same source as the anchor): a missing best practice with no reachable result, or a defense-in-depth gap an outer layer already covers (both are hardening notes, Low at most); guessed deployment/provider/browser behavior not visible in this repo (a `Worth a look` naming the missing fact); a caller affecting only their own data; a parser/runtime effect reported stronger than what you observed.

**Challenge before ranking — the finder never validates its own finding** (adapted from [google/mantis](https://github.com/google/mantis) `mantis-review`, Apache-2.0). Every candidate headed for Critical or High, and every Security candidate, goes to a fresh subagent that did not find it: one per claim, or one per small batch of unrelated claims. The brief carries the one-sentence claim, its `path:line`, and its ingress for Security; never the finder's reasoning. The instruction: *assume this is false and try to disprove it from the code.* The challenger checks that every cited path, line, and symbol exists, that the attacker really controls the source, and that no guard on the path already stops it. Use a different model family when one is reachable, same rule as the rotation. For a Bug, the challenger runs the claim when it can: a few-line repro or test outside the tree (the scratch directory, never the repo) that shows the code breaking its cited contract. Running beats judging (from [Argus](https://arxiv.org/abs/2510.06663), Mang et al., SIGMOD 2026). Their LLM judge accepted 5% false candidates; in mature code, that rate buries the real bugs. A repro that fails as claimed goes in the entry as `repro: <command> → <observed>`. Three outcomes:
- **stands** — keeps its place, with the challenger's one line of confirming evidence in the entry;
- **falls** — moves to False positives with the challenger's reason;
- **unclear** — moves to Worth a look, naming the fact that would settle it.

**Chain pass.** After ranking, ask whether two findings combine into a worse one: a path traversal plus a writable config directory, a stored XSS plus a missing CSRF check, an info leak plus a guessable ID. A chain gets its own ID at the severity of the combined result, judged by the privilege its first step needs, and lists its parts; the parts keep their own IDs.

**Reconcile with prior runs — after your own findings are ranked, never before.** Now read the earlier `plan/forward-pass-*.md` reports (and those in `plan/_archive/`) and `history.md`'s Dead ends and Decisions. Match on the sink's file plus the defect class, never on ID, since IDs restart every run. A prior finding whose file changed since that report's `Commit:` is matched against today's code, not by line number. Mark each of your findings:
- **new**;
- **still open** — cite the prior report and ID;
- **regression** — the prior item was `[x]` and the defect is back; rank it at least at its prior severity and name the reintroducing commit when `git log -L` shows it;
- **re-flagged** — a prior dismissal covers it; keep the dismissal unless you can name new evidence that defeats its reasoning, and when you reopen, quote both.

**A recorded decision is not re-argued** (adapted from [mattpocock/skills](https://github.com/mattpocock/skills) `improve-codebase-architecture`, MIT). When a finding's fix would undo a dated entry in `history.md` Decisions, quote the decision beside the finding. A severity-ranked finding keeps its rank. A Stray or Worth-a-look finding stays only when you can name the cost the decision causes today; otherwise drop it to False positives, citing the decision. A kept one is a deferral in Phase 4 that points at `/decide-nt`, never an item `/autopilot-nt` can settle by default.

A prior open finding your pass did not meet is never closed by silence. Check it now, or list it in the coverage map as not re-checked.

**Preserve dismissals.** A discarded false positive or non-issue goes in a **"False positives / non-issues (verified)"** list with the one-line reasoning that cleared it, so the next pass doesn't re-flag it. Drop pure linter/typechecker/CI noise without ceremony.

**"Worth a look (lower confidence)" → `W1, W2, …`** holds hunches you couldn't verify; don't hide them, don't inflate their severity.

## Phase 4 — Batch the findings into a fix-workplan

Every actionable finding (all but false positives) goes into an ordered, batched workplan:

- **Themed batches** by area/subsystem, not severity, so fixes touching the same code travel together. Keystone first, marked: `## Batch A — <theme>  (keystone)`.
- **Tri-state checkboxes:** `[ ]` open · `[x]` done · `[~]` partial.
- **Item shape:** `- [ ] **H5** <fix> (path:line). <one-line rationale>.`
- **`[test: <how>]`** on any item whose fix needs a runtime check beyond static reasoning or unit tests.
- **Test-value items (`T`) are gated.** A `D` or `C` item is not done until the named keeper goes red under one deliberate mutation of the production code it guards, with the source restored byte for byte afterwards. A guards-nothing `D` inverts the check: the named mutation leaves the deleted test green. An `F` item is done when the repaired test goes red under that mutation. A `seam` item is done when no non-test caller remains (`grep`) and the build and full suite pass. Batch `T` items by production owner, one owner per batch. A `T` item that also carries a severity ID goes in its severity batch instead.
- **Deferrals state why + what unblocks.** A `[~]` partial or deferred item says what's done, what's left, and what would un-defer it, pointing at `/decide-nt` when the blocker is a decision: `DEFERRED: needs a versioned-hash migration story — decide first (/decide-nt).`
