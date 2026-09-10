## Phase 2 — Walk the canonical first-time journey, narrating each beat

This is the spine, and it's the same spine on every surface — only the mechanics that capture each beat change: web narrates a screenshot per click; CLI narrates stdout/stderr/exit code per invocation; TUI narrates a `tmux capture-pane -p` per keystroke sent; native narrates a `computer-use`/Simulator screenshot per tap. Step through the cold path the way a new user actually moves: **arrival → first screen → any splash/tour → the asks (credentials, model, judge, permissions) → first real action → first value.** At **every beat**, capture:
- **What's on screen** right now.
- **What the obvious next action is** — or whether the newcomer has to *guess*.
- **What's confusing, premature, or missing** — asked before it's needed, or needed before it's asked.
- **Where they stall, bounce, dead-end, or have to backtrack.**

Record it as a **numbered step narrative** ("1. Land → see X. 2. Click Y → modal asks for creds *before explaining why* …"), each beat carrying its **timestamp into the recording** so a reader can jump to the moment rather than reconstruct it. That narrative is the report's backbone — it's the evidence that the journey, not just a screen, is the unit of review.

## Phase 2b — Apply the newcomer-friction lenses

Across the journey and the whole surface, score these:
- **Arrival / orientation** — does the empty/landing state say *what this is* and the *single* next action, or dump them in a blank screen?
- **Onboarding-sequence ordering** — is the order driven by user-need or by build-order? Just-in-time vs front-loaded asks. Can they skip/defer? Are defaults sane enough to start *without* configuring?
- **Information architecture / nav** — grouped by user task, or a junk-drawer of whatever got added? Can a newcomer *predict* where things live? Orphaned / duplicated / buried entry points? Is "Settings" a dumping ground for unrelated things?
- **Progressive disclosure** — right amount shown per step, or flooded with advanced options up front?
- **Time-to-first-value** — how many steps from arrival to the first useful outcome; where exactly do they stall?
- **Consistency drift** — labels, patterns, and terminology that diverge across features built at different times (the accretion tell).
- **Empty & error / recovery states** — what the newcomer sees when something's blank, fails, or they mis-step. On CLI this is the error-message text itself; on native it includes what a denied permission does to the next screen.
- **Affordances** — do controls signal what they do, or is the next move invisible? Reads differently per surface: web/native = visual signifiers (button styling, icons); CLI = whether `--help` and error text surface the next move; TUI = whether a keybinding legend is on screen at all.
