---
description: "Replay a flow on the real deployed surface for machine evidence; code stays read-only."
argument-hint: "[flow to verify, e.g. voice-clone | ocr | the feature just changed]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Agent", "mcp__claude-in-chrome__*"]
entry: "a change deployed or runnable on the real surface; the real runtime reachable (prod URL, or a real browser with the model/state cached)"
exit: "a live-check report of verified RESULTs (or a BLOCKER) written; the feature's honest state moved to shipped, or held"
writes: "plan/live-check-<date>.md"
---

Prove the **deployed thing actually runs**, end to end, with machine evidence read from the real runtime. Until this run passes, the honest state of a change on a path the dev preview can't exercise is *"implemented, not yet verified"*, never `shipped`.

**READ-ONLY on source.** It drives the app and reads evidence; it never edits code. A failure hands off: a bug → `/walkthrough-nt`; a design or UX gap → `/ux-review-nt` or `/decide-nt`; a code defect → a separate fix pass with its own verification.

`$ARGUMENTS` (optional): the flow to verify (e.g. `voice-clone`, `ocr`, `search`). If empty, verify the feature that changed most recently (from `git log` or the latest `plan/` summary).

If the project has no runnable surface (a pure library with full deterministic tests), say so: live-check doesn't apply, and the test suite is the verifier.

## Phase 0 — Does it need a live check?

If the change is fully exercised by the dev preview plus a deterministic check (a pure function with a unit test, a config edit, copy), say so and stop.

It is **required** when the change touches a path the preview can't run:
- a **heavy in-browser model** (WebGPU / wasm), cached only in a real browser;
- a **real-device API**: camera, mic, file-system picker, clipboard, notifications;
- a **gesture-gated** path: audio autoplay, fullscreen, permission prompts;
- a **cross-origin or mirrored** surface (an app embedded under a different origin);
- **cached or persisted state across a reload** (IndexedDB / OPFS / Cache Storage / picked folders);
- **timing-dependent** behaviour (streaming, races, debounced or queued work).

Name the trigger(s) that fired in the report header.

## Phase 1 — Reach the real runtime

- **Prod, if it auto-deploys.** Confirm the deploy landed in the browser: a CDN edge or `curl` can serve a stale copy for minutes after the browser sees the new one. Check for a marker unique to the change in the loaded page (an element id, a string).
- **A real browser where the model is cached (Chrome via claude-in-chrome).** Headless Chromium has no WebGPU, and the built-in browser pane starts with an empty cache; the user's Chrome has the multi-GB model on disk.

Confirm the prerequisites before testing behaviour:
- the project's harness `doctor` (left by `/walkthrough-nt`), if any, reports green;
- the model is cached (enumerate Cache Storage / IDB for its files);
- the capability exists (`navigator.gpu`, `getUserMedia`, the picker API);
- **the tab is in the foreground.** WebGPU and rAF loops stall in a hidden tab; a load that hangs at "100%" is almost always this. If `document.visibilityState` is `hidden`, ask the user to front the tab and wait.

## Phase 2 — Exercise the real user path with a real gesture

Read the flow's file in `verify/features/` first, when one exists. Then walk the genuine sequence through the actual UI:
- For anything gesture-gated, use **trusted input** (a real click or keypress via the browser MCP), not `element.click()` in JS: a programmatic click carries no user activation, so audio stays suspended and focus doesn't move.
- Feed **real input**. When a real person's likeness or voice would be the input, use a **public-domain or properly licensed** source, keep the output on-device, and keep anything generated an obvious test artifact, never a distributable impersonation.
- Follow the true order (upload/record → process → act → persist), not a shortcut that skips the step under test.

## Phase 3 — Instrument, and read machine evidence

Every claim needs a resolving pointer; don't eyeball it.
- **Hook the output.** Wrap the sink that proves the work happened and read its shape: buffer sample count and duration, token count, image dimensions, row counts, the network requests fired (or not fired, for an on-device claim). LocalMind example: wrap `AudioContext.prototype.createBuffer`; a 175 680-sample / 7.32 s buffer is real speech, a <2 400-sample buffer is the bug.
- **Run a control** when the defect is input-specific: the failing input and a known-good input side by side.
- **Reload to prove persistence**, then re-read the restored state; don't infer it from the write path.
- **Read the response headers** on the flow's requests and flag: wildcard CORS with `Access-Control-Allow-Credentials`, a session or auth cookie missing `HttpOnly`/`Secure`/`SameSite`, a stack trace or SQL error text in a production error response, an unauthenticated `/debug`, `/admin`, `/status` or `/.env` route. (Checklist condensed from [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill), MIT.) A hit is a Security finding; don't widen it into a full sweep, which is `/forward-pass-nt`'s job.
- **Confirm a suspected regression with a second measurement.** A programmatic `.click()` doesn't move focus or grant activation, and a synchronous read right after an `async` handler runs before the handler resumes; both make working features look broken. Reproduce with real input and a settled microtask before it earns a finding.

## Phase 4 — Report as verified RESULTs, and set the state

Write `plan/live-check-<date>.md` in ATTEST form:
- **Header**: the flow, the surface (prod URL or real browser), the Phase 0 trigger(s), and whose eyes (maker or checker).
- **One `RESULT (verified)` per proven claim**, each with its resolving pointer: the command run, the sample count, the duration, the restored value. Only these claims may use the reserved words.
- **Explicit `not exercised` lines** for paths you couldn't reach, with why (env / hardware / gesture) and the residual `RISK` (severity + what would confirm it). An un-run path never reads as passing by omission.
- **A `BLOCKER`** with the tried-trail if the runtime was unreachable (deploy didn't land, no cached model, WebGPU absent).

**The gate:** a clean live-check moves the feature's honest state to `shipped`. A fail or an unreachable runtime caps it at *"implemented, not yet verified"* and hands the defect to the right command. Report worst news first; never launder a partial run into a full pass.

## Playbook hook

If the user's config (CLAUDE.md / memory) or the project names a live-check or replay playbook for this kind of surface, read it before Phase 1.

## Impact declaration

`plan/live-check-<date>.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).
