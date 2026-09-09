# Changelog

## Unreleased

- **Changed:** `ux-review-nt` now covers four surfaces, not just browser — CLI, TUI, and native (macOS/iOS) via a new Phase 0 surface detection (explicit override or repo-signal inference), per-surface cold-start recipes in Phase 1, and a per-surface objective-audit swap in Phase 4 (Lighthouse stays web-only; native/iOS gets a real automated a11y audit via `XCUIApplication().performAccessibilityAudit()`; CLI gets a scripted `--help`-coverage + error-message-quality health check; TUI gets a yes/no/partial checklist). `allowed-tools` gains `mcp__computer-use__*` and the iOS Simulator tool. Only one surface (native/iOS) gets a real score; CLI/TUI are explicitly labeled checklists, not scores, so the report never blurs the two.
- **Added:** [`MEMORY.md`](MEMORY.md) — the `plan/` memory contract. Splits the folder into **records** (append-only: reports, summaries, `soc.md`) and **derived** files (`pending.md`, `workplan.md`, `history.md`'s indexes) that are a projection over them, so the plan can be rebuilt from the log. Five writer rules (the human writes anywhere; agents append to records, may flip the status of an item they did the work for, and may not add/drop/re-rank/re-word — that belongs to `/replan-nt`, `/windup-nt`, and `/scaffold-nt`; a goal is recorded, never self-authored into the shared plan). Record files declare an `## Impact`; derived items carry `[from: <record>]` provenance. Surfaced as guard 5 in [`STATES.md`](STATES.md) and §8.5 in [`AUTHORING.md`](AUTHORING.md).
- **Added:** `plancheck` (`skills/replan-nt/bin/plancheck.py`) — a mechanical replay check over a `plan/` folder. Reports **orphans** (a derived item whose provenance names no record) and **ghosts** (a record declaring an `add` impact nothing cites); untagged items are info, not failure. Stdlib only, never calls a model, never edits anything. Exit 0 clean / 1 divergence / 2 could not run; `--since` and `--json`. `/replan-nt` Step 4.5 now runs it instead of judging by reading, and falls back to the previous read-and-judge behaviour when it is absent.
- **Changed:** nine record-writing commands (`forward-pass`, `walkthrough`, `ux-review`, `maintain`, `live-check`, `harden`, `autopilot`, `windup`, `lab`) end their report with an `## Impact` section declaring what should change in the derived files, or `none — <reason>`.
- **Changed:** `autopilot-nt` given a prose goal now records it verbatim and queues it **in its own run record**, not as checkboxes in `plan/workplan.md`, and never edits the goal mid-run — an agent that authors the criteria it is judged against can meet them by editing. Its `writes:` contract narrows to status flips on items that already exist. `harden-nt` likewise routes deferrals through an `## Impact` line instead of writing workplan items directly.
- **Fix:** `plancheck` no longer reads a format placeholder written in prose (`[from: <record>]`) as a real provenance tag and reports it as an orphan. Angle brackets never appear in a record slug, so such a line counts as untagged. Found by dogfooding the checker on a project whose decision log documents the tag grammar.
- **Fix:** `plancheck` reads numbered list items, not only `-`/`*` bullets. `pending.md`'s `## Now` section is commonly an ordered list, and an item that did not parse was an item whose provenance was never checked. Found by dogfooding on a project whose Now section is numbered.
- **Compatibility:** additive, not a migration. An untagged derived item means hand-written, so every existing `plan/` folder passes unchanged (verified: 161 items across three real repos, exit 0).

- **Changed:** `capture-nt` Step 2 becomes an orient step run *before* fetching — duplicate check, nearby notes to link against, and tag-reuse suggestions — so a source the vault already holds is never re-fetched, and new notes reuse existing tags instead of coining novel ones. `ask-nt` Step 2 leads with ranked search rather than an unordered file list, and names the keyword-search ceiling explicitly. Both use the vault's optional `bin/vaultdb.py` index when present and fall back to the previous `rg` behaviour when it is absent.
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
