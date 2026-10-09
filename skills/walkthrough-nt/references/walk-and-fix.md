## Phase 4 — Walk and fix, one step at a time

For each role, drive each journey and repeat per step:

1. **Act** through the real controls and forms. Don't shortcut via URLs unless you're testing deep links.
2. **Observe** twice. The Phase 3 invariant set is checked mechanically: a breach is a finding with an ID even when the step looked fine. Then judge the step itself: did the UI change, did the right data render, did the action do anything (network and resulting state included)?
3. **If it broke, fix it now.** Give it a stable ID by severity, `C1/H1/M1/L1` (the `/forward-pass-nt` scheme), and capture evidence: repro steps · expected vs observed · a console or network excerpt · a screenshot. Then:
   - **Suspect your driver and your assertion before the app.** Re-run in a clean context with the instrumentation stripped. Then re-derive from the code path what "working" looks like and confirm you observe that: most false candidates are a wrong assertion (the wrong element checked, a poll shorter than the call, missing `acceptDownloads`, a toggle's second click read as a second open). A programmatic `.click()` does not move focus like a real click; a synchronous read after an `async` handler runs before the handler resumes.
   - **A search miss is not evidence of absence.** `grep` on a file containing a NUL byte prints nothing and exits 1; use `rg` or `grep -a`.
   - **Read back each edit** to confirm it landed on the line and file you meant (not an earlier match, not a generated file's source without regenerating, not another worktree).
   - **Re-verify in the browser**: re-walk that exact step and confirm no new console error. After an HMR reload or restart, re-establish the role's session and seed first.
   - **When you made two changes, run the isolation matrix**: each alone, then both. One run's harness change alone went green for the wrong reason, leaving the defect latent.
   - **Commit it**: one focused commit for the fix, by path, local only.
4. **Continue** the journey from where you were.

**Timebox each fix, one fix at a time.** A root cause that becomes a large refactor, a shared-contract change, or a product-behaviour call is deferred: log the finding ID, what's broken and what would unblock it, point at `/decide-nt`, and keep walking.

**Cross-role authorization probe:** as a low-privilege role, try a high-privilege action or URL directly. Does the guard hold, or does the UI only hide the button? Fix a leak in place, or defer it if it needs a policy call.

**Stub what the browser can't drive** (payments, outbound email, native file pickers): monkeypatch the global, e.g. `window.showSaveFilePicker = async () => fakeHandle`, so the journey continues, and note what was stubbed vs genuinely exercised.
