---
description: Cut a release — suggest a semver bump from the commits since the last tag, generate/update CHANGELOG.md, draft release notes, then (only on confirmation) commit the bump, tag, push, create the GitHub release, and note the deploy. The mechanics, where /package-nt is the marketing.
argument-hint: "[major | minor | patch | x.y.z]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "verifying with gate green — no failing verifier, no open fix-workplan items; refuse otherwise (override via /decide-nt)"
exit: "tag + GitHub release + CHANGELOG landed, or an explicit refusal naming the guard"
writes: "CHANGELOG.md, version bump, git tag"
---

Cut a versioned release. Where `/package-nt` drafts the *announcement*, `/release-nt` does the *mechanics*: read the commits since the last tag, suggest a semver bump, write the CHANGELOG, draft the release notes — and, **only after you confirm**, commit the bump, tag, push, create the GitHub release, and kick the deploy. Tagging and releasing are outward-facing, so it prepares everything and shows it first; it never publishes a release without a yes.

If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): the bump (`major` / `minor` / `patch`) or an explicit version (`1.4.0`). If empty, suggest one from the commits.

## Phase 0 — Entry guard (illegal-transition check)

A release is the transition to `shipped` (see `STATES.md`), and it's guarded. Before anything else, check:

1. **Verifier green** — run the project's own check (tests / typecheck / build — and the committed verification harness if `/walkthrough-nt` has left one; the lever is the definition of green). A failing verifier stops the run. **No verifier defined** (a single-file tool with no tests or build) → the check passes vacuously; note "no verifier defined" in the release notes draft and move on — the guard blocks on red, never on absent.
2. **No open fix-workplan** — scan `plan/` for the most recent `forward-pass-*` / `ux-review-*` / `maintenance-*` report; any unchecked `[ ]` item in its keystone batch stops the run.
3. **No HELD autopilot branch** — an unmerged `autopilot/<date>` branch means unreviewed work; stop and point at it.

On failure, **refuse with the guard named**: "Illegal transition to `shipped`: <what failed>. Fix it, or override deliberately with `/decide-nt \"releasing despite <X> because <why>\"` and re-run." An override recorded via `/decide-nt` in this session lets the run proceed — a guard bypassed on purpose with a logged reason is a decision; bypassed silently is a bug.

## Phase 1 — Read the history

- Find the last release: `git describe --tags --abbrev=0` (or `git tag`); if none, this is the first release.
- Collect the commits since it: `git log <last-tag>..HEAD --oneline`.
- Detect the version source: `package.json`, `pyproject.toml`, `Cargo.toml`, a `VERSION` file, or git-tags-only. Note the current version.

## Phase 2 — Suggest the bump

From the commits, suggest **major / minor / patch** — a breaking change → major, a new feature → minor, fixes/chores → patch (honor conventional-commit prefixes — `feat:` / `fix:` / `feat!:` — if the repo uses them; otherwise infer from the messages). `$ARGUMENTS` overrides. Show the suggested new version and the one-line reasoning.

## Phase 3 — CHANGELOG + release notes

- **Update `CHANGELOG.md`** (Keep a Changelog style): a new `## [x.y.z] — YYYY-MM-DD` section grouping the commits into **Added / Changed / Fixed / Removed**. Create the file if missing.
- **Bump the version** in the manifest (and lockfile if relevant).
- **Draft the GitHub release notes** — the highlights, the changelog section, and a "Full changelog" compare link (`<last-tag>...vX.Y.Z`).

## Phase 4 — Confirm, then publish

Show the planned **version**, the **CHANGELOG diff**, the **release notes**, and the exact `git` / `gh` commands. **Pause for confirmation.**
- On **yes**: commit the bump + CHANGELOG, `git tag vX.Y.Z`, push commits + tag, `gh release create vX.Y.Z` with the notes, and note (or trigger) the deploy. Never force-push.
- On **no**: leave the bump + CHANGELOG staged for you to edit.

## Phase 5 — Handoff

Print the released version, the release URL, and the deploy status. Suggest `/package-nt` for the announcement collateral. (CHANGELOG is committed; any working drafts stay in local `plan/`.)
