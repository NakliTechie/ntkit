# Changelog

## v1.4.0 — 2026-09-06

Driven by Eric Provencher's "Rethinking skills and prompts for GPT-6 Astra" (2026-09-05) and the Claude Code skills docs, which cap each listed description at 1,536 characters and budget the whole listing.

- **Layout:** every command moved from `commands/<name>.md` to `skills/<name>/SKILL.md`. Install is now `cp -r ntkit/skills/* ~/.claude/skills/`. Delete old copies in `~/.claude/commands/` after upgrading.
- **Descriptions:** all 23 cut to 15 words or fewer, trigger first, side effect named (657 → 289 words in aggregate).
- **Routers:** `autopilot`, `walkthrough`, `guide`, `forward-pass`, `capture`, `windup`, `harden` are now a short `SKILL.md` (contract, guards, stop-lines, a phase table) plus `references/` files read on entering each phase. Procedure text moved verbatim; nothing was dropped.
- **AUTHORING.md:** §1 description rule (15 words), new §9 "Route, don't recite", checklist updated.
- **Fix:** `capture-nt` tag-listing command used `rg -ohI` with a brace glob and printed ripgrep's help; replaced with a `grep -rhoE` form.
- `.worktrees/` gitignored.
- `/spar-nt` remains as the deprecated alias for `/harden-nt`.

## v1.3 — 2026-09-05

- `/spar-nt` renamed to `/harden-nt` and reframed around a path map; `/spar-nt` kept as a deprecated alias for one release.

Earlier history: `git log`.
