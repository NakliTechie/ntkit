---
description: "Cut a release: semver, CHANGELOG, tag, push, GitHub release, verify the deploy live."
argument-hint: "[major | minor | patch | x.y.z]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "verifying with gate green — no failing verifier, no open fix-workplan items; refuse otherwise (override via /decide-nt)"
exit: "tag + GitHub release + CHANGELOG landed and the deploy verified live, or an explicit refusal naming the guard"
writes: "CHANGELOG.md, version bump, git tag"
---

Cut a versioned release. Where `/package-nt` drafts the *announcement*, `/release-nt` does the *mechanics*: read the commits since the last tag, suggest a semver bump, write the CHANGELOG, draft the release notes — and, **only after you confirm**, commit the bump, tag, push, create the GitHub release, and kick the deploy. Tagging and releasing are outward-facing, so it prepares everything and shows it first; it never publishes a release without a yes.

If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): the bump (`major` / `minor` / `patch`) or an explicit version (`1.4.0`). If empty, suggest one from the commits.

## Phase 0 — Entry guard (illegal-transition check)

A release is the transition to `shipped` (per ntkit's `STATES.md` — kit doctrine, not a file in this project), and it's guarded. Before anything else, check:

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

## Phase 4.5 — Verify the deploy actually landed

A push is not a deploy, and a green local check is not a green live one. Once the deploy reports done, verify **against the deployed URL**:
- **Fetch a marker from the new build** — a string that exists only in this release. If it's missing, the deploy is still propagating or it failed; don't report success on the basis of having pushed.
- **Bust the cache when you check.** A first read straight after a deploy can be served stale and look like a half-finished rollout — new assets live, old HTML. Re-fetch with a cache-busting query and `Cache-Control: no-cache` before concluding anything is wrong.
- **Re-run the checks that can only fail in production.** Anything depending on host routing behaves differently locally: a static dev server 404s a missing file, while most hosts serve `index.html` for it, so `/robots.txt`, `/llms.txt`, redirects, headers and 404 handling are **untestable until deployed**. Confirm each returns the right status *and* the right `content-type`.
- Confirm response **headers** the repo claims (cache-control, security headers) are actually applied — a `_headers` / `netlify.toml` / `vercel.json` rule that never took effect is silent.

## Phase 5 — Handoff

Print the released version, the release URL, and the **verified** deploy status — what you fetched from the live host, not just that the push succeeded. Suggest `/package-nt` for the announcement collateral. (CHANGELOG is committed; any working drafts stay in local `plan/`.)
