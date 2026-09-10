## Phase 0 — Detect the surface

Pick exactly one before Phase 1 — the cold-start recipe and the objective-audit tool both depend on getting this right, and guessing wrong wastes the whole run:

- **Explicit override wins.** If `$ARGUMENTS` names a surface, use it.
- **Otherwise, read repo signals:** an `.xcodeproj`/`Info.plist` or an Android manifest → **native**; a TTY-rendering framework (Bubbletea, Textual, ratatui, blessed, ncurses-style raw-mode) with no browser entry → **tui**; a `package.json`/`Cargo.toml`/`pyproject.toml` `bin` entry (or equivalent) with no server/browser entry → **cli**; anything that serves HTTP/renders in a browser → **web** (today's default path).
- **Genuinely ambiguous** (e.g. a repo exposing both a CLI and a web dashboard, neither clearly primary): ask once, naming the candidates — don't silently pick one.
- **State the chosen surface in the report header** alongside the `Reviewer:` line, so a reader knows which cold-start recipe and which objective-audit tool were in play.
