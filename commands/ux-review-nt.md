---
description: "Cold-first-timer UX review — wipe all state, walk the app as a brand-new user, and report where build-order accretion fails the newcomer (arrival, onboarding sequence, nav/IA, time-to-first-value), plus an objective Lighthouse a11y + performance pass. Read-only: ranks findings and proposes an ideal first-run + IA; never restructures."
argument-hint: "[area to focus, e.g. first-run | settings | nav]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
entry: "app boots; state wipeable to cold-start"
exit: "first-run + IA report written (read-only run)"
writes: "plan/ux-review-<date>.md"
---

Review the app **as a cold first-time user** — the person who wasn't there when each feature was bolted on. Features get added in build-order, which makes sense to whoever built it; to a newcomer the nav, setup, settings, and first-run flow are an accretion, not a journey. This command walks the genuine newcomer path and reports where that accretion trips them.

**READ-ONLY.** It ranks findings and proposes an ideal first-run sequence + information architecture — it never edits the app. Structural changes (reorder onboarding, regroup nav) are *product* calls → `/decide-nt`; a friction point that's actually a *bug* → hand to `/walkthrough-nt`.

It's the third browser-walkthrough sibling: `/walkthrough-nt` finds bugs and fixes them, `/guide-nt` captures screenshots and documents — both **seed data so screens aren't empty**. `/ux-review-nt` does the **opposite**: it wipes all state, because the whole point is to experience exactly what a newcomer experiences — the empty state, the first-run asks, the "what is this and what do I do" moment.

If the project has no browser surface, say so. If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): an area to focus — `first-run`, `settings`, `nav`. If empty, walk the whole cold journey from arrival to first value.

## Phase 1 — Cold start (the defining setup)

Manufacture a genuine newcomer:
- **Wipe everything.** A fresh browser context with no storage — localStorage, sessionStorage, IndexedDB, cookies, cache, service workers, OPFS, any picked folders. (A new Playwright context is cold by default; in a persistent browser, clear site data first.) **Do not seed** — empty *is* the thing under test.
- **Serve a production build** — the real bundle a newcomer hits, on explicit `127.0.0.1` + a known-free port.
- **WebGPU can't be tested headless.** Headless Chromium has **no WebGPU**, so a local-AI app that loads/runs a model in-browser errors on the model step — you can't walk the post-load journey cold. Walk those beats with the **Chrome MCP** (a real GPU browser); otherwise capture the pre-model first-run and record the model-dependent beats as blind spots. (This is the single most common gap in a local-AI cold review.)
- **Approach from the canonical entry** the way a first-timer would — the landing URL / repo, no prior knowledge, no deep-link shortcuts. Pretend you've never seen it.

## Phase 2 — Walk the canonical first-time journey, narrating each beat

This is the spine. Step through the cold path the way a new user actually moves: **arrival → first screen → any splash/tour → the asks (credentials, model, judge, permissions) → first real action → first value.** At **every beat**, capture:
- **What's on screen** right now.
- **What the obvious next action is** — or whether the newcomer has to *guess*.
- **What's confusing, premature, or missing** — asked before it's needed, or needed before it's asked.
- **Where they stall, bounce, dead-end, or have to backtrack.**

Record it as a **numbered step narrative** ("1. Land → see X. 2. Click Y → modal asks for creds *before explaining why* …"). That narrative is the report's backbone — it's the evidence that the journey, not just a screen, is the unit of review.

## Phase 3 — Apply the newcomer-friction lenses

Across the journey and the whole surface, score these:
- **Arrival / orientation** — does the empty/landing state say *what this is* and the *single* next action, or dump them in a blank screen?
- **Onboarding-sequence ordering** — is the order driven by user-need or by build-order? Just-in-time vs front-loaded asks. Can they skip/defer? Are defaults sane enough to start *without* configuring?
- **Information architecture / nav** — grouped by user task, or a junk-drawer of whatever got added? Can a newcomer *predict* where things live? Orphaned / duplicated / buried entry points? Is "Settings" a dumping ground for unrelated things?
- **Progressive disclosure** — right amount shown per step, or flooded with advanced options up front?
- **Time-to-first-value** — how many steps from arrival to the first useful outcome; where exactly do they stall?
- **Consistency drift** — labels, patterns, and terminology that diverge across features built at different times (the accretion tell).
- **Empty & error / recovery states** — what the newcomer sees when something's blank, fails, or they mis-step.
- **Affordances** — do controls signal what they do, or is the next move invisible?

## Phase 4 — Map the IA + objective Lighthouse a11y / perf pass

- **IA map** — enumerate the actual nav / menu / settings tree, its grouping logic (or lack of it), depth, and orphans. This is the raw material for the re-grouping proposal.
- **Lighthouse — accessibility + performance.** Run a Lighthouse audit (Chrome DevTools MCP) for **Accessibility** and **Performance**; capture the scores and the top failing audits. Add targeted a11y checks a newcomer actually hits: **keyboard-only** traversal of the first-run flow, visible focus, color contrast, tap-target size. Tie each a11y finding back to the journey beat where it bites (e.g., "the credential modal can't be advanced or dismissed by keyboard — a screen-reader user is stuck at step 3"). This objective layer sits *beside* the heuristic critique, not instead of it.

## Phase 5 — Rank, and propose the ideal newcomer journey + IA

- **Rank with stable IDs** by how badly each blocks a newcomer reaching first value, using the shared severity scheme — `C/H/M/L` (Critical / High / Medium / Low), same as `/forward-pass-nt` and `/walkthrough-nt` so the IDs read the same downstream. Add an a11y/perf track from Phase 4.
- **Each finding:** the specific step/screen · what a cold user experiences · *why* it trips them · a concrete fix · tagged **quick win** (trivial: a label, a default, a dead button) or **structural** (reorder onboarding, regroup nav — a design call → `/decide-nt`).
- **The counter-proposal — the constructive heart.** Don't stop at "this is confusing." Give the **re-ordered ideal first-run sequence** and a **re-grouped IA** — "here's the journey a newcomer *should* have." Concrete, step-by-step, so the user can decide and act on it.

## Phase 6 — Write the report

**Write `plan/ux-review-YYYY-MM-DD.md`**, in this order:
1. **Header** — date, scope, the cold-start state used, the newcomer persona walked.
2. **The newcomer journey** — the numbered step narrative from Phase 2, friction flagged inline.
3. **Findings** — ranked `C/H/M/L`, each tied to a step, with fix + quick-win/structural tag.
4. **IA map + proposed re-grouping** — current tree vs the task-grouped version.
5. **Ideal first-run sequence** — the re-ordered counter-proposal.
6. **Accessibility + performance** — Lighthouse scores, top failing audits, keyboard/focus/contrast/tap-target notes.
7. **Coverage / blind spots** — what couldn't be reached cold (e.g., flows gated behind real credentials).

Create `plan/` if missing and ensure it's gitignored; if today's report exists, suffix `-2`. **Don't edit the app** — this is read-only. **Print to chat:** the journey's worst friction beats, the ranked findings, the Lighthouse scores, and the headline of the ideal-sequence proposal (keep the full proposal in the file).

End by pointing structural recommendations at `/decide-nt`, any genuine bugs at `/walkthrough-nt`, and noting that `/replan-nt` folds this report into `pending.md`/`workplan.md`.
