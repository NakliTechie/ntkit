## Phase 2 — Walk the canonical first-time journey, narrating each beat

Same spine on every surface; only the capture changes (web: a screenshot per click; CLI: stdout, stderr and exit code per invocation; TUI: `tmux capture-pane -p` per keystroke; native: a screenshot per tap). Step through **arrival → first screen → any splash or tour → the asks (credentials, model, judge, permissions) → first real action → first value.** At every beat, capture:
- what's on screen;
- the obvious next action, or whether the newcomer has to guess;
- what's confusing, premature or missing (asked before it's needed, needed before it's asked);
- where they stall, bounce, dead-end or backtrack.

Record it as a **numbered step narrative** ("1. Land → see X. 2. Click Y → modal asks for creds *before explaining why* …"), each beat carrying its timestamp into the recording.

## Phase 2b — Score the newcomer-friction lenses

Score the journey and the surface on eight lenses: arrival and orientation · onboarding order (user need or build order) · IA and nav · progressive disclosure · time-to-first-value · consistency drift (the accretion tell) · empty, error and recovery states · affordances (web/native: visual signifiers; CLI: whether `--help` and error text surface the next move; TUI: whether a keybinding legend is on screen).
