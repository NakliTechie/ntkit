## Phase 6 — Verify + report

- **Serve `guide/` and exercise every behaviour in `build.md`** at desktop and at ~375px: captures load (not blank), ANSI renders (not raw escape codes), search filters and `Esc` restores, TOC anchors jump, and the lightbox keys and swipes work.
- **Shipping:** commit the guide; do not push (`/windup-nt` ships it). Respect `.gitignore` and `.assetsignore`; when screenshots are large, let the user decide whether to commit or host them.
- **Report**: where the guide is; roles × features covered per surface; total screenshots and transcripts; what was (re)captured; any `empty`/`fail`/console-error/non-zero-exit routes (the blind spots), each worth a `/walkthrough-nt`; and, for an update, that you edited the generator and regenerated, not the HTML.
