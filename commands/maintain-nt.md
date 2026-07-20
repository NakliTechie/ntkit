---
description: Maintenance sweep — find outdated/deprecated dependencies, stale GitHub Actions versions, security advisories, dead links, and lockfile drift; rank them and batch into a fix-workplan. Applies safe quick-fixes automatically (verified, reverted on failure); majors defer to /execute-nt. Writes plan/maintenance-<date>.md.
argument-hint: "[focus: deps | actions | security | links]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "a repo with dependencies or workflows"
exit: "ranked fix-workplan written; safe quick-fixes applied + verified"
writes: "plan/maintenance-<date>.md"
---

Keep a shipped project alive. `/maintain-nt` sweeps for the rot that accumulates after launch — outdated/deprecated dependencies, stale GitHub Actions, security advisories, dead links, lockfile drift — ranks what it finds, and hands back a batched fix-workplan in the `/forward-pass-nt` shape. The sweep itself is read-only; the **safe class** — SHA-pins, patch bumps, dead links — gets applied on the spot and verified, because that class is defined by reversibility. Anything that can break you (major bumps, breaking changes) stays in the workplan for `/execute-nt`.

This is the on-demand version of a scheduled upkeep routine — run it on a cadence.

If the current directory isn't a git repo, ask which project — don't guess. `$ARGUMENTS` narrows the sweep to one lens.

## Phase 1 — Detect the stack

Manifests + locks (`package.json` + lockfile, `pyproject.toml` + `uv.lock`, `Cargo.toml`, `go.mod`), CI workflows (`.github/workflows/`), and docs with links (README, `docs/`).

## Phase 2 — Sweep (per lens)

- **Dependencies** — outdated (`npm outdated`, `pip list --outdated`, `uv` / `cargo` / `go` equivalents) and deprecated packages. Separate **major** (breaking, needs care) from **minor/patch** (safe).
- **GitHub Actions** — action versions pinned to a stale major or a floating tag (`@v3`, `@main`); suggest the current major, ideally SHA-pinned.
- **Security** — known advisories against the lockfile (`npm audit`, `pip-audit`, `osv-scanner`). (Deep code-vuln review is `/security-review`.)
- **Dead links** — `curl -I` the URLs in README/docs; flag 4xx/5xx.
- **Lockfile drift** — lock out of sync with the manifest.

## Phase 3 — Rank + batch

Assign stable IDs and rank by **risk**: a security advisory or a deprecated-and-unmaintained dep = High; a major version bump = Medium (with a one-line breaking-change note); a stale action pin or dead link = Low. **Batch by area** (Deps / Actions / Security / Docs). Each item: what · why · the exact bump/fix · a `[test]` marker (a dep bump needs a runtime/test check before it's trusted).

## Phase 4 — Report + safe quick-fixes

**Write `plan/maintenance-YYYY-MM-DD.md`** in the `/forward-pass-nt` report shape: findings by ID, a batched Workplan, and a coverage note (what was checked, what wasn't) — plain teammate language throughout, no AI-speak or filler. Then **apply the safe quick-fixes now, no confirmation** — SHA-pin actions, patch-level bumps, fix dead links — verifying each (install/build still green) and reverting any that fails its check; report what landed with evidence. **Defer major bumps to `/execute-nt`** (so each is fixed and verified individually); point breaking-change calls at `/decide-nt`.

End by naming the highest-risk finding, and that `/execute-nt` works the workplan while `/replan-nt` folds it.
