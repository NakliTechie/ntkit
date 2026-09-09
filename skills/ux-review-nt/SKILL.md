---
description: "Cold first-run UX walk — browser, CLI, TUI, or native app; ranked report, read-only."
argument-hint: "[area to focus, e.g. first-run | settings | nav] [surface: web|cli|tui|native — auto-detected if omitted]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task", "mcp__computer-use__*", "mcp__Claude_Code_iOS_Simulator__*"]
entry: "app boots; state wipeable to cold-start"
exit: "first-run + IA report written (read-only run)"
writes: "plan/ux-review-<date>.md"
---

Review the app **as a cold first-time user** — the person who wasn't there when each feature was bolted on. Features get added in build-order, which makes sense to whoever built it; to a newcomer the nav, setup, settings, and first-run flow are an accretion, not a journey. This command walks the genuine newcomer path and reports where that accretion trips them.

**READ-ONLY.** It ranks findings and proposes an ideal first-run sequence + information architecture — it never edits the app. Structural changes (reorder onboarding, regroup nav) are *product* calls → `/decide-nt`; a friction point that's actually a *bug* → hand to `/walkthrough-nt`.

On the **browser surface**, it's the third walkthrough sibling: `/walkthrough-nt` finds bugs and fixes them, `/guide-nt` captures screenshots and documents — both **seed data so screens aren't empty**. `/ux-review-nt` does the **opposite**: it wipes all state, because the whole point is to experience exactly what a newcomer experiences — the empty state, the first-run asks, the "what is this and what do I do" moment. On **CLI, TUI, and native (macOS/iOS)** surfaces `/walkthrough-nt` and `/guide-nt` don't reach yet, so this command runs the cold walk alone there — same wipe-first posture, no seeded state, on whichever surface the app actually presents.

**Stronger with different eyes — rotate them across runs.** This is a checker command — its whole value is that it doesn't share the maker's blind spots, and two runs of the same model misjudge the same things identically. Fresh context is the floor; a different **model family** is the stronger posture. Before starting, find this command's most recent prior report in `plan/` and read its `Reviewer:` header line — **that line only, never the prior findings**, which would contaminate the cold-newcomer posture this command exists to manufacture — then pick this run's eyes:

- **First run** (no prior report): proceed as the current agent.
- **Repeat run:** prefer a reviewer from a **different family** than the prior run — an agent CLI on the PATH (`codex`, `gemini`, …; check with `which`) driven through this same brief via Bash. None reachable → use a **different model** of the current family (subagent with a model override). Even that unavailable → run as-is and say so in the report, never silently.
- **Never rotate below the floor:** fresh-but-weak eyes find less than strong eyes looking twice. If every alternative is materially weaker than the current agent, keep the current agent and log the rotation as unavailable.

Whichever ran, the report header carries one line — `Reviewer: <model> · prior: <model> (<date>)` or `prior: none` — that line is the whole log; the next run reads it to rotate. If you are the family that built most of this code, say that there too — the reader should know which grade of eyes graded it.

If the current directory isn't a git repo, ask which project — don't guess. If the project has no interactive surface at all (pure library, backend-only with no CLI/API console), say so and suggest `/forward-pass-nt` instead.

`$ARGUMENTS` (optional): an area to focus — `first-run`, `settings`, `nav` — and/or a surface override — `web`, `cli`, `tui`, `native`. If the surface is empty, detect it (Phase 0). If the focus is empty, walk the whole cold journey from arrival to first value.

## Phase 0 — Detect the surface

Pick exactly one before Phase 1 — the cold-start recipe and the objective-audit tool both depend on getting this right, and guessing wrong wastes the whole run:

- **Explicit override wins.** If `$ARGUMENTS` names a surface, use it.
- **Otherwise, read repo signals:** an `.xcodeproj`/`Info.plist` or an Android manifest → **native**; a TTY-rendering framework (Bubbletea, Textual, ratatui, blessed, ncurses-style raw-mode) with no browser entry → **tui**; a `package.json`/`Cargo.toml`/`pyproject.toml` `bin` entry (or equivalent) with no server/browser entry → **cli**; anything that serves HTTP/renders in a browser → **web** (today's default path).
- **Genuinely ambiguous** (e.g. a repo exposing both a CLI and a web dashboard, neither clearly primary): ask once, naming the candidates — don't silently pick one.
- **State the chosen surface in the report header** alongside the `Reviewer:` line, so a reader knows which cold-start recipe and which objective-audit tool were in play.

## Phase 1 — Cold start (the defining setup)

Manufacture a genuine newcomer, recipe by surface:

**Web:**
- **Wipe everything.** A fresh browser context with no storage — localStorage, sessionStorage, IndexedDB, cookies, cache, service workers, OPFS, any picked folders. (A new Playwright context is cold by default; in a persistent browser, clear site data first.) **Do not seed** — empty *is* the thing under test.
- **Serve a production build** — the real bundle a newcomer hits, on explicit `127.0.0.1` + a known-free port.
- **WebGPU can't be tested headless.** Headless Chromium has **no WebGPU**, so a local-AI app that loads/runs a model in-browser errors on the model step — you can't walk the post-load journey cold. Walk those beats with the **Chrome MCP** (a real GPU browser); otherwise capture the pre-model first-run and record the model-dependent beats as blind spots. (This is the single most common gap in a local-AI cold review.)
- **Approach from the canonical entry** the way a first-timer would — the landing URL / repo, no prior knowledge, no deep-link shortcuts. Pretend you've never seen it.

**CLI:**
- **Isolated `$HOME`.** Run with `HOME=$(mktemp -d)` (and an otherwise-inherited `PATH`) so no dotfiles, cached config, saved auth, or shell history leak in. Build/install fresh into that environment — don't reuse a warm install.
- **Approach via the documented install path** a newcomer would actually follow (the README's install command), not a shortcut you already know.

**TUI:**
- Same isolated-`$HOME` recipe as CLI, but launched inside a **detached `tmux` session** (`tmux new-session -d`) since the app is full-screen and interactive — a one-shot shell invocation can't drive it.
- Start at a **known terminal size** (e.g. 80×24) and note it in the report; TUI rendering is size-sensitive and a finding that's really "the terminal was 200 columns wide" isn't a finding.

**Native (macOS / iOS):**
- **macOS:** remove `~/Library/Application Support/<app>`, the app's preferences plist, and any keychain items it created, then launch fresh via `mcp__computer-use__open_application`.
- **iOS:** `xcrun simctl erase <device>`, then install + launch fresh via the Simulator tool's `launch` action.
- Either way, request tool access (`request_access` / the simulator's device-permission prompt) **as its own observed step**, not silently before the walk starts — a newcomer sees that prompt too.

## Phase 2 — Walk the canonical first-time journey, narrating each beat

This is the spine, and it's the same spine on every surface — only the mechanics that capture each beat change: web narrates a screenshot per click; CLI narrates stdout/stderr/exit code per invocation; TUI narrates a `tmux capture-pane -p` per keystroke sent; native narrates a `computer-use`/Simulator screenshot per tap. Step through the cold path the way a new user actually moves: **arrival → first screen → any splash/tour → the asks (credentials, model, judge, permissions) → first real action → first value.** At **every beat**, capture:
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
- **Empty & error / recovery states** — what the newcomer sees when something's blank, fails, or they mis-step. On CLI this is the error-message text itself; on native it includes what a denied permission does to the next screen.
- **Affordances** — do controls signal what they do, or is the next move invisible? Reads differently per surface: web/native = visual signifiers (button styling, icons); CLI = whether `--help` and error text surface the next move; TUI = whether a keybinding legend is on screen at all.

## Phase 4 — Map the IA + objective audit (surface-specific)

- **IA map** — enumerate the actual nav tree, its grouping logic (or lack of it), depth, and orphans: on web/native this is the menu/settings tree; on CLI/TUI it's the subcommand/screen tree. This is the raw material for the re-grouping proposal. **Only now** — after the cold walk is done, never before it — read the feature map (`verify/features/`, left by `/walkthrough-nt`) if one exists, as a completeness check: a feature area the cold journey never surfaced is itself a discoverability finding. Reading it before the walk would contaminate the newcomer posture the whole command exists to manufacture.

The objective layer below sits *beside* the heuristic critique from Phase 3, not instead of it — and only one surface here gets a real Lighthouse-grade *score*. Say so plainly in the report rather than dressing a checklist up as a score.

**Web — Lighthouse.** Run a Lighthouse audit (Chrome DevTools MCP) for **Accessibility** and **Performance**; capture the scores and the top failing audits. Add targeted a11y checks a newcomer actually hits: **keyboard-only** traversal of the first-run flow, visible focus, color contrast, tap-target size. Tie each a11y finding back to the journey beat where it bites (e.g., "the credential modal can't be advanced or dismissed by keyboard — a screen-reader user is stuck at step 3").
- **A high accessibility score is a floor, not a verdict — never report it as "accessible."** Automated rules catch contrast, missing labels and invalid ARIA; they do not catch a skip link that lands on the wrong section, a focus trap that leaks, or a primary action sitting 25 tab stops in. Expect the worst findings of the review to be ones Lighthouse passed. Say the score *and* what it doesn't cover.
- **Performance may not be in the audit you just ran.** The Chrome DevTools MCP `lighthouse_audit` tool **excludes Performance by design** — so CLS and LCP need a separate performance trace. Don't infer "perf is fine" from four green headline categories. Measure CLS on a **throttled mobile viewport**; desktop-unthrottled hides it.
- **Confirm any regression with a second measurement before you report it.** First readings mislead — a cold cache, a warm cache, a page already loaded, or a synthetic interaction all produce numbers that look like defects. Two specific traps: driving the UI with programmatic `.click()` doesn't move focus the way a real click does (so focus-restore looks broken when it isn't), and reading state synchronously after an `async` handler reads it before the handler resumed (so persistence looks broken when it isn't). When something looks broken, reproduce it with real input and a settled microtask before it earns a finding.

**CLI — a scripted health check, not a score.** Enumerate every subcommand and confirm each answers `--help`/`-h` with exit `0` and non-empty output — report the coverage fraction. Feed a handful of canned bad inputs (missing required arg, unknown flag, nonexistent path) to the main entry points and judge each response: does it name the problem and suggest a fix, or dump a raw traceback/errno? Time `--version` and the first real command for startup lag. Spot-check exit codes on one known-good and one known-bad invocation. There is no automated pass/fail here — report the coverage fraction and the message-quality judgment call plainly as judgment, not as a score.

**TUI — a checklist, not a score.** From the first screen, is the quit key shown or discoverable, and within how many keypresses? Is a keybinding legend present on every screen, or only some? Does the layout survive a live resize and a narrow (80-column) terminal without garbling? Does it degrade sanely under `NO_COLOR`/`TERM=dumb`? Report each as yes/no/partial with the screen it was checked on — this phase has no numeric score on this surface, full stop.

**Native (macOS/iOS) — the one surface with a real automated a11y audit.** iOS: run `XCUIApplication().performAccessibilityAudit()` (via `xcodebuild test` or an equivalent XCUITest target) — a genuine, scriptable, Apple-shipped audit with real pass/fail output, the closest thing to Lighthouse outside the browser. macOS: no equivalent audit tool exists, so query the accessibility tree (`mcp__computer-use__app_ax_find`) on each screen and confirm interactive elements expose real accessible names/roles — a weaker, checklist-grade proxy, say so. Performance on either: cold-launch-to-first-interactive timing as the TTFV analog, plus idle memory footprint if the tooling on hand can read it.

## Phase 5 — Rank, and propose the ideal newcomer journey + IA

- **Rank with stable IDs** by how badly each blocks a newcomer reaching first value, using the shared severity scheme — `C/H/M/L` (Critical / High / Medium / Low), same as `/forward-pass-nt` and `/walkthrough-nt` so the IDs read the same downstream. Add the objective-audit track from Phase 4 (a real score on native/iOS and web, a checklist on CLI/TUI — label it accordingly, don't blur the two).
- **Each finding:** the specific step/screen · what a cold user experiences · *why* it trips them · a concrete fix · tagged **quick win** (trivial: a label, a default, a dead button) or **structural** (reorder onboarding, regroup nav — a design call → `/decide-nt`).
- **The counter-proposal — the constructive heart.** Don't stop at "this is confusing." Give the **re-ordered ideal first-run sequence** and a **re-grouped IA** — "here's the journey a newcomer *should* have." Concrete, step-by-step, so the user can decide and act on it.

## Phase 6 — Write the report

**Write `plan/ux-review-YYYY-MM-DD.md`**, in this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.
1. **Header** — date, scope, the cold-start state used, the newcomer persona walked, the `Reviewer:` line (this run's model · prior run's model + date, per the rotation rule above).
2. **The newcomer journey** — the numbered step narrative from Phase 2, friction flagged inline.
3. **Findings** — ranked `C/H/M/L`, each tied to a step, with fix + quick-win/structural tag.
4. **IA map + proposed re-grouping** — current tree vs the task-grouped version.
5. **Ideal first-run sequence** — the re-ordered counter-proposal.
6. **Objective audit** — Lighthouse scores + top failing audits (web) or the native a11y-audit result, or the CLI/TUI checklist, whichever surface this run used — labeled as a score or a checklist, never blurred.
7. **Coverage / blind spots** — what couldn't be reached cold (e.g., flows gated behind real credentials).

Create `plan/` if missing and ensure it's gitignored; if today's report exists, suffix `-2`. **Don't edit the app** — this is read-only. **Print to chat:** the journey's worst friction beats, the ranked findings, the objective-audit results, and the headline of the ideal-sequence proposal (keep the full proposal in the file).

End by pointing structural recommendations at `/decide-nt`, any genuine bugs at `/walkthrough-nt`, and noting that `/replan-nt` folds this report into `pending.md`/`workplan.md`.

## Impact declaration

`plan/ux-review-<date>.md` is a **record**: append-only, never rewritten. The derived files (`pending.md`, `workplan.md`, `history.md`'s `## Decisions` and `## Dead ends`) are a projection over the records, rewritten only by `/replan-nt`, `/windup-nt` and `/scaffold-nt`. (Full contract: [`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) in the ntkit repo.) End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- workplan.md/B2#3 — status: [ ] → [x], verified by <the check that proves it>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. Do not write the item into `pending.md` or `workplan.md` yourself — a record that declares its impact and a reconcile pass that folds it are what keep the plan rebuildable from the log. An `add` line with nothing later citing this record is a **ghost**, and `plancheck` reports it.
