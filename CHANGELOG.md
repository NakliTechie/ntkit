# Changelog

## Unreleased

- **Changed:** ATTEST formatting applies only to designated formal outputs exceeding approximately 200 unformatted characters. Ordinary conversation and shorter outputs use natural prose; evidence standards and execution permissions remain unchanged.
- **Fix:** `capture-nt` stages explicit capture-owned file paths and commits only those paths, preserving unrelated staged changes.
- **Added:** `package-nt` launch gate checks for a first-run guided tour (the spotlight walkthrough per the Build Doctrine's Surface conventions, driven by the vendored `tour.js`) — a nice-to-have, not a hard blocker.

## v1.5.0 — 2026-09-06

- **Removed** `/spar-nt`, the deprecated alias for `/harden-nt` carried since v1.3. Delete `~/.claude/skills/spar-nt/` after upgrading. The kit is 22 skills.

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
