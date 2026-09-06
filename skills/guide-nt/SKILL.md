---
description: "Regenerate the single-file HTML feature guide from a committed generator, capturing each role's surfaces."
argument-hint: "[role/feature to focus | 'update' to refresh an existing guide]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "mcp__computer-use__*"]
entry: "at least one surface is runnable (dev server, CLI binary, or built .app); guide generator committed (or created this run)"
exit: "single-file HTML guide regenerated from the generator — never hand-edited"
writes: "guide generator + output"
---

Build a **searchable HTML guide** for the app: identify each user role, drive the running app through their features **capturing screenshots or terminal transcripts**, and assemble a single-file `guide/index.html` — role sections × feature subsections × captioned captures, with **inline search**. This is the documentation sibling of `/walkthrough-nt`: same role-driven spine, but it *captures and documents* the app instead of *finding and fixing* bugs.

**The guide is a build artifact.** Its source of truth is a small committed **generator** — a capture script (route-plans per role, tagged with a capture backend) plus a builder (captions and sections as data → HTML). The prose lives in the generator's data, so you **edit the generator and regenerate**; you never hand-edit `index.html`.

If the current directory isn't a git repo, ask which project. If no surface can be detected — no dev server, no CLI entry point, no app bundle — say so; there is nothing to capture.

`$ARGUMENTS` (optional): a role (`admin`) or feature (`checkout`) to scope the capture to, or `update` to refresh an existing guide. If empty, cover every role and their primary features.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Surfaces | The app classified as `browser` · `cli` · `native-macos` · `mixed`. The backend decides the route-plan shape and the capture path. | `references/surfaces-and-routes.md` |
| 2 Roles + routes | Roles per surface (always the anonymous visitor and the first-run user; a single-role app drops the role wrapper) and an ordered route-plan `(NN, slug, backend, target, wait_ms)` per role — derived from `verify/features/` when it exists, with drift written back to the map. | `references/surfaces-and-routes.md` |
| 3 Generator | Exists → update its data (route rows, captions, sections) and preserve every hand-written caption. Missing → scaffold `guide/capture.*`, `guide/build_index.py`, `guide/regenerate.sh` on the Bahi pattern. | `references/generator.md` |
| 4 Capture | Per backend: `browser` (production build, readiness wait, retina shots, blank-capture guard, console log per route), `cli` (raw transcripts with exit codes), `native-macos` (computer-use, access requested once per app, not unattended). `update` re-shoots only changed routes. A blank or failing route is a bug for `/walkthrough-nt`, not something to paper over. | `references/capture.md` |
| 5 Build | One self-contained `index.html`: TOC, role sections, image cards with a keyboard-and-swipe lightbox, terminal cards with ANSI rendered, theme taken from the app's own CSS tokens, inline search (`/` focuses, `Esc` clears), responsive on a phone. | `references/build.md` |
| 6 Verify | Serve the guide and look at it: captures load, search filters, lightbox keys and swipes, phone viewport. Print coverage, capture counts, blind spots, and the path. Commit the guide; do not push. | `references/verify.md` |
