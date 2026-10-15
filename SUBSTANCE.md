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
self-report.

## 6. Named reward-hacking patterns to refuse

Naming a hack makes it catchable (the value ATTEST's banned-words list gives, too). Sixteen that
agent-driven work invites most — refuse them; §1–5 cover the rest. A handback that cites a pattern
or principle by name also names the decision it changed; a citation with no decision behind it is
name-dropping, not applying (idea from Cursor's `pstack` principle names).

1. **Gate self-weakening** — editing the verifier so a failing check passes. The committed
   `/walkthrough-nt` verifier *is* the gate; changing it to go green is tampering, not a fix.
2. **Proof-class inflation** — fixtures, mocks, or hand-inserted rows shown as live proof. Live
   proof is a runtime-selected subject with a real receipt — ATTEST `verified`/`observed`, not
   `assumed` dressed up.
3. **Tautological tests** — a test that asserts whatever the code already does, or skips the
   negative case. Each feature item pre-specifies one assertion a naive wrong build would fail.
   The sharpest form is a test written *against a defect you just found*: if the assertion you were
   about to add would go green on today's broken behaviour, you are pinning the bug as intended and
   the next reader will treat it as a decision. Delete the test and record the gap instead.
   **The authoring gate.** Before any new test, answer four questions: what observable behaviour
   or contract it protects; what credible regression turns it red; why the existing suite does not
   already catch that (each contract has one owner test, at the strongest boundary that can reach
   it); and whether it needs a production seam (an export, flag, or hook no real caller uses). A
   missing answer means no test yet. A needed seam means test at the real boundary instead. A port
   for a network, third-party, clock, or randomness dependency is not such a seam: production's real
   adapter calls it (dependency categories, `skills/forward-pass-nt/references/test-value.md`).
   **Failure modes first.** For code tested in isolation, write down how it can fail before
   writing it; each failure mode becomes the assertion a naive build would fail. A test written
   after the code tends to assert whatever the code does. **A regression test must go red on the
   pre-fix code** for the reason it names, and the run records that red; one that never failed
   proves the mock, not the fix. An end-to-end check ends in an artifact a cold reader can replay:
   the command, its output, the screenshot or trace. A suite that only prints "passed" is not one.
4. **Stub-as-done** — a placeholder that compiles (a TODO / `unimplemented` marker) counted as
   finished. It builds ≠ it works; committed code carries no scaffolds.
5. **Spec-editing as progress** — weakening a plan, spec, or frozen decision instead of building
   it. Plan edits never close a feature item; a frozen decision moves only through `/decide-nt`.
6. **Demo-path hardcoding** — special-casing the demo inputs so the happy path passes. Verify on
   runtime-selected subjects that differ from the dev fixtures (`/walkthrough-nt`, `/demo-nt` seed).
7. **Re-run-until-green** — treating an unexplained red as noise and running it again until it
   passes, instead of reading the assertion. The green obtained that way is not evidence of
   anything: if the check really is nondeterministic then *that* is the finding, and if it is not,
   a true signal has just been discarded. The common cause is dull and worth knowing — a
   single-test red off a half-saved tree, where a test landed a moment before the fix it asserts.
   **Read the failing assertion before you re-run**, and never absorb an unread red with a retry,
   a longer timeout, or a skip; that is gate self-weakening (#1) with extra steps. The same rule
   covers any tool's silence: a search that returns nothing on a file it refused to read is not
   evidence of absence. A signal nobody read is not a check.
8. **Deletion without a keeper** — removing a test because "another layer covers it" without
   naming that test and showing it goes red. Pruning a suite is real work; a deletion count is not
   progress. Each deleted test names its keeper, and the keeper is shown red under one deliberate
   mutation of the code it guards, with the source restored byte for byte afterwards. A test that
   fails on today's code is a bug report, not a deletion candidate. "The E2E suite would catch it"
   is a claim until the E2E test is named: E2E rarely reaches protocol, migration, or security
   contracts.
9. **Unbounded evidence** — a test, eval or diagnostic run that writes one file per case, per
   operator or per layer, until the disk holds hundreds of thousands of them (300K and 600K files
   have been seen). Volume is not rigor. Every run writes generated data to **one** temp directory
   with a stated budget (default: 5,000 files and 500 MB), prefers one aggregate file (JSONL,
   archive, database) to many small ones, and deletes the directory on success, failure and
   interrupt. A run that hits its budget stops and reports; it never raises the budget on its own.
   Only a short summary, never the bulk output, enters `plan/` or the repo. Check with the file
   count, not just bytes: `find . \( -name .git -o -name node_modules -o -name .venv -o -name .build \) -prune -o -type f -print | wc -l`.
10. **Verification churn** — running tests, evals or diagnostics between implementation steps,
    repeating an unchanged suite, or adding a new diagnostic script for every symptom. Build a
    complete batch first. Run only the checks that cover the changed batch, once, at its boundary.
    One diagnostic batch per failure; a second needs a written hypothesis the first batch ruled
    out. For systems-level work the order is feature complete, benchmark, optimise, and
    verification stays at the accuracy bar the project states, not at bit-equality with a reference.
    "Check once per batch" assumes a bounded batch; item 11 is its other half. The one speed number
    allowed before the Benchmark phase is one observed speed reading per stage boundary (one command, a few runs, the current build against the reference on the same machine), labelled "observed, not a benchmark" and reported in the handback. It informs; it never starts tuning and never gates.
11. **Unbounded batch** — the opposite failure of item 10: thousands of lines built and never run,
    because the boundary check keeps moving out. A batch is one capability family that one
    boundary run can check, sized at roughly a day of work. Past that, close the batch early and
    check it. Source that has never run is not progress, however much of it exists (a Quench batch
    reached ~3,900 uncommitted lines across a dozen model families with zero checks run).
12. **Scope by transcription** — copying a reference system's whole feature list into the parity
    matrix and calling that "feature complete". The matrix inherits every product the reference
    bundles (a text engine's matrix once held 117 rows of image, video and music generation), and
    the phase can never close. The owner approves the matrix's scope before work starts; rows
    outside the product's core job are waived by default; a matrix over ~100 rows, or with rows from
    a different product category, gets a scope question first.
13. **Periphery while blocked** — when the keystone waits on a decision, working whatever is open
    instead of the next item in the stated order, and leaving the decision in a doc the owner
    never sees. A blocked item moves on to the next item in order, never to the widest open
    surface. The decision goes to the owner at once (`/notify-nt` plus the chat they are in), with
    options and a default. A file in the repo is not a notification.
14. **Invisible product** — stage reports that list tests, receipts and evidence files but never
    say how to run the thing. A working build that the owner has not touched is not delivered.
    Every stage handback ends with a **Try it** block: the exact command or URL for the current
    working build, reachable from where the owner actually is (another machine, a phone on the
    LAN), or "no runnable build yet: <why>".
15. **Comment as patch** — a comment that explains a workaround, a surprise or a "do not remove"
    rule, left in place of the fix. The comment is a defect report on our own code, so the work
    item is the root-cause change, then the comment goes. A rule that matters gets encoded as a
    type, assertion, test or lint rule. A comment about something outside the repo (a
    third-party quirk, a protocol rule) stays, with the reason. Detected by
    `/forward-pass-nt` (Comments as symptoms) and fixed by `/autopilot-nt`. Idea from Cursor's
    `pstack` `no-comments`.
16. **Unexplained number** — a speed, accuracy or cost number reported or acted on without knowing
    what it measured. A number is evidence only with three things beside it: the run count and
    spread; the limiter, meaning the resource or code path that stops it being twice as good (a
    core, a lock, the disk, the network, the load generator), read from a profile or counters taken
    during the run, never guessed from the code; and the other things it could be measuring, each
    ruled out with evidence (errors, cached or skipped work, code that never ran, a reference left
    on default settings, noise, a part too small to matter end to end). A saving larger than the
    whole time the changed part used to take means the number measured something else. Applies to
    the Benchmark and Optimise phases, `/lab-nt` keeps and eval results. Idea from Cursor's `pstack`
    `explain-the-number`.

## 7. Gates and fan-out: general principles

Set 2026-10-14 from a measurement of 200 autopilot first checks (`plan/racing-measurement-2026-10-14.md`
in the plans repo) and the owner's rule: too many gates cause failures and loops that only extend the
build. Each principle binds every skill, present and future.

1. **A gate earns its place by what it catches.** A new gate, check or review step names what it
   catches, the measured rate at which it catches it, and the signal that would remove it. No
   measurement, no gate. `/traces-nt` is the measuring tool.
2. **Repair before adding a gate.** The cheapest fix for a failing check is a retry by the same maker.
   In the measurement, one more patch after a first-check failure passed 9 of 10 times. Add a gate
   only where a retry does not recover.
3. **Retries are capped and end in a park, never a loop.** Two honest attempts, then park the item
   with what was tried (`/autopilot-nt` already does this). A new step may not restart the count.
   The park note also names the one premise both attempts shared and the observation that would come
   out differently if it were false. Two failures on one premise are evidence against it, so the next
   attempt tests the premise before it tries a third fix (idea from Cursor's `pstack`
   `attack-the-premise`).
4. **Check per batch, not per step** (§3 items 9 to 11). Every extra checkpoint adds wall time and
   a chance of a false stop. Add one only where a failure would otherwise travel further.
5. **Fan out reads and independent work by default.** Parallel reads, reviews and items with
   non-overlapping paths cost little and find more.
6. **Race competing attempts only on a trigger.** Racing needs three things: a scorer outside the
   attempts, attempts that differ (another approach or another model family), and a trigger such as
   a second failure or an item flagged as having more than one plausible approach. Racing every item
   doubles the work to catch the 18% that fail, and the same-maker retry already catches most of those.
7. **No attempt scores its own win.** The scorer, its inputs and the goal sit outside every attempt's
   writable scope (the `/lab-nt` measurement lockbox). Pick the winner by a fixed rule: passes the
   check, then the smaller diff, then fewer files touched. Add "self-scored race" to §6 when a
   skill first implements racing.
8. **Isolate what attempts touch.** Each parallel attempt gets its own worktree, branch and port.
   Collisions in the archive were reused branch names and fixed ports, not shared files or the GPU.
   Scarce shared resources get a claim (`proposals/dibs.md`, on branch `dibs-architecture`).
9. **Gates are reviewed like code.** A gate that passes almost always, or whose failures are almost
   always false stops, is removed. Re-measure after each ntkit release that adds or changes a gate.

---
*Delivery rigor — the third pillar beside `STATES.md` (the machine) and `ATTEST.md` (the
report). Substance over ceremony; credit only for what runs.*
