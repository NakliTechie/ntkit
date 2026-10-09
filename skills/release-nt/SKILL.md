---
description: "Cut a release: semver, CHANGELOG, tag, push, GitHub release, verify the deploy live."
argument-hint: "[major | minor | patch | x.y.z]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent"]
entry: "verifying with gate green — no failing verifier, no open fix-workplan items; refuse otherwise (override via /decide-nt)"
exit: "tag + GitHub release + CHANGELOG landed and the deploy verified live, or an explicit refusal naming the guard"
writes: "CHANGELOG.md, version bump, git tag"
---

Cut a versioned release: suggest the bump, write the CHANGELOG and release notes, then — **only after the user confirms** — commit, tag, push, create the GitHub release, and verify the deploy live. `/package-nt` drafts the announcement; this does the mechanics.

`$SKILL` is this skill's base directory, printed when the skill loads; sibling kit skills sit beside it (`$SKILL/../<skill>/`).

`$ARGUMENTS` (optional): `major` / `minor` / `patch` or an explicit version. Empty → suggest one from the commits (conventional-commit prefixes when the repo uses them).

Not in a git repo → ask which project; this command tags and pushes.

## Phase 0 — Entry guard

A release is the transition to `shipped` (ntkit `STATES.md`). Check:
1. **Verifier green** — the project's tests / typecheck / build, and the committed harness if `/walkthrough-nt` left one. Red stops the run. No verifier defined → passes; say "no verifier defined" in the notes.
2. **No open fix-workplan** — the latest `forward-pass-*` or `ux-review-*` report in `plan/` has no unchecked `[ ]` item in its keystone batch.
3. **No HELD autopilot branch** — an unmerged `autopilot/<date>` branch is unreviewed work.

On failure, refuse with the guard named: "Illegal transition to `shipped`: <what failed>. Fix it, or override with `/decide-nt \"releasing despite <X> because <why>\"` and re-run." A `/decide-nt` override logged this session lets the run proceed.

## Phase 1 — Prepare

From the commits since the last tag (none → first release): the suggested version with one line of reasoning, a new `## [x.y.z] — YYYY-MM-DD` CHANGELOG section (Keep a Changelog: Added / Changed / Fixed / Removed; create the file if missing), the version bump in the manifest (and lockfile), and GitHub release notes with a `<last-tag>...vX.Y.Z` compare link.

## Phase 2 — Confirm, then publish

Show the version, the CHANGELOG diff, the notes and the exact commands, then **pause for confirmation**.
- **Yes:** commit the bump + CHANGELOG; `git tag -a vX.Y.Z -m "<name> vX.Y.Z"` (annotated: `--follow-tags` silently skips a lightweight tag and `gh release create` then refuses); `git push origin main --follow-tags`; confirm the tag with `git ls-remote --tags origin vX.Y.Z`; `gh release create vX.Y.Z` with the notes; note or trigger the deploy. Never force-push.
- **No:** leave the bump and CHANGELOG staged for the user to edit.

## Phase 3 — Verify the deploy landed

A push is not a deploy. Against the deployed URL:
- Fetch a marker that exists only in this release. Missing → still propagating or failed; don't report success.
- Re-fetch with a cache-busting query and `Cache-Control: no-cache` before concluding a rollout is half-done; the first read after a deploy is often stale.
- Re-check what only fails in production: hosts serve `index.html` for a missing file, so `/robots.txt`, `/llms.txt`, redirects and 404s need the right status **and** `content-type` from the live host.
- Confirm the response headers the repo claims (cache-control, security headers) are applied.

**Social card.** If this release changed the repo's social card image, re-upload it through Claude-in-Chrome and verify it by hash, per `$SKILL/../package-nt/references/social-preview.md`.

## Phase 4 — Handoff

Print the version, the release URL, and the **verified** deploy status (what you fetched from the live host). Suggest `/package-nt` for announcement collateral.
