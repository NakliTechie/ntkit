---
description: "Replay a flow on the real deployed surface for machine evidence; code stays read-only."
argument-hint: "[flow to verify, e.g. voice-clone | ocr | the feature just changed]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
entry: "a change deployed or runnable on the real surface; the real runtime reachable (prod URL, or a real browser with the model/state cached)"
exit: "a live-check report of verified RESULTs (or a BLOCKER) written; the feature's honest state moved to shipped, or held"
writes: "plan/live-check-<date>.md"
---

Prove the **deployed thing actually runs** — load the real model, drive the real surface, fire a real user gesture, instrument the real output, and read **machine evidence** that the feature works end to end. This is the closing verifier: the move that earns the reserved words ("works", "shipped") for a change the dev preview could never exercise.

It is the **operational discharge of hard rule ⑤** — *"done is the verifier's word (fresh-context tests / lint / schema / **replay / timing**)."* `node --check` passed, the bundle built, the diff reads correct — all of that is `inferred` or `observed`. For a heavy-model / device-API / gesture-gated / cached-state / timing-dependent path, **behaviour is only `verified` by a live replay.** Until this run passes, the honest state is *"implemented, not yet verified"* (ATTEST §3), never `shipped`.

Skipping this gate is how a green static check launders a broken feature — the failure class it exists to prevent is "built fine, merged, silently broke the runtime path, shipped."

Among the checker siblings it runs **last**, after merge/deploy, on the real runtime, and asks *"does the deployed artifact functionally run?"* — not `/forward-pass-nt`'s code audit, not `/walkthrough-nt`'s find-and-fix, and not `/ux-review-nt`'s *"is it good to use?"* (which can run against a mockup; live-check cannot run without the real runtime).

**READ-ONLY on source.** live-check drives the app and reads evidence; it never edits code. A failure hands out: a bug → `/walkthrough-nt`; a design/UX gap → `/ux-review-nt` or `/decide-nt`; a code defect → a fix pass (its own verification). The maker–checker split holds.

`$ARGUMENTS` (optional): the flow to verify (e.g. `voice-clone`, `ocr`, `search`). If empty, verify the feature that changed most recently (read `git log` / the latest `plan/` summary to find it).

If the current directory isn't a git repo, ask which project — don't guess. If the project has no runnable surface (a pure library with full deterministic tests), say so: live-check doesn't apply, the test suite is already the verifier.

## Phase 0 — Does it even need a live check? (the trigger test)

live-check is **not** for every change. If the change is fully exercised by the dev preview plus a deterministic check (a pure function with a unit test, a config edit, copy), say so and stop — running a live replay adds nothing.

It is **REQUIRED** when the change touches any path the preview structurally can't run:
- a **heavy in-browser model** (WebGPU / wasm — the preview pane can't load it; it's cached only in a real browser);
- a **real-device API** — camera, mic, file-system picker, clipboard, notifications;
- a **gesture-gated** path — audio autoplay, fullscreen, permission prompts (a programmatic call won't trigger it);
- a **cross-origin / mirrored** surface (e.g. an app embedded under a different origin);
- **cached or persisted state across a reload** (IndexedDB / OPFS / Cache Storage / picked folders);
- **timing-dependent** behaviour (streaming, races, debounced/queued work).

If any apply, the static gate is not the verifier — this run is. Name which trigger(s) fired in the report header.

## Phase 1 — Reach the real runtime

Pick the surface that actually exercises the path:
- **Prod, if it auto-deploys** — the real bundle a user hits. Confirm the deploy **landed**, and beware: a CDN edge / `curl` can serve a *stale* copy for minutes after the browser already sees the new one. **The browser is the source of truth** — check for a marker unique to the change *in the loaded page* (an element id, a string), not via `curl`.
- **A real GPU browser where the model/state is cached** — drive it with the Chrome MCP (claude-in-chrome), not the in-app preview pane. Headless / preview Chromium has **no WebGPU** and an empty cache; the real browser has the ~GB model already on disk.

Then confirm the **prerequisites are actually present** before you test behaviour — don't assume:
- the project's verification harness, if it has a `doctor` (left by `/walkthrough-nt`), reports green — run it before hand-checking the items below,
- the model is cached (enumerate Cache Storage / IDB for its files),
- the capability exists (`navigator.gpu`, `getUserMedia`, the picker API),
- **the tab is FOREGROUND.** WebGPU (and rAF-driven loops) **throttle or stall in a hidden/backgrounded tab** — a load that hangs at "100%" is almost always this. Check `document.visibilityState`; if `hidden`, ask the user to front the tab and wait, don't diagnose a bug.

## Phase 2 — Exercise the real user path with a real gesture

Walk the genuine sequence a user takes, through the **actual UI**. Read the flow's file in the feature map first (`verify/features/`, left by `/walkthrough-nt`) when one exists — it names the entry points, the gated variants, and what usually lies, so you drive the real path instead of rediscovering it:
- For anything **gesture-gated**, use a **trusted input** — a real click/keypress via the browser MCP, not `element.click()` in JS. A programmatic click doesn't carry user activation, so audio stays suspended and focus doesn't move — you'll mis-read a working feature as broken.
- Feed **real input**. If the path needs a real-world asset (a voice sample, a document, an image), use a genuine one. When a **real person's likeness/voice** would be the input, prefer a **public-domain / properly-licensed** source, keep the output **on-device**, and keep any generated content an obvious **test artifact** — never a distributable impersonation. (Functional QA of your own tool is fine; producing deceptive content is not, even for "testing".)
- Follow the true order — upload/record → process → act → persist — not a shortcut that skips the step under test.

## Phase 3 — Instrument, and read machine evidence

Do **not** eyeball "it seems to work." Attach a probe and read numbers — every claim needs a resolving pointer:
- **Hook the output.** Wrap the sink that proves the work happened and read its shape: audio buffer sample-count & duration, generated token count, decoded image dimensions, row counts, the actual network requests fired (or *not* fired, for an on-device claim). (LocalMind example: wrap `AudioContext.prototype.createBuffer` → a 175 680-sample / 7.32 s buffer is proof of non-degenerate speech; a <2 400-sample buffer is the bug.)
- **Run a CONTROL** when the defect is input-specific. Prove the fix by contrast: the failing input *and* a known-good input, side by side (the `!`-ending line vs a plain line). One passing run doesn't isolate the cause; the pair does.
- **Reload to prove persistence.** For any "survives a refresh / restored from disk" claim, actually reload and re-read the restored state — don't infer it from the write path.
- **Confirm a suspected regression with a second measurement.** First readings mislead. Two classic false-positives (shared with `/ux-review-nt`): a programmatic `.click()` doesn't move focus / grant activation like a real click (focus-restore & audio look broken when they aren't); and a **synchronous read right after an `async` handler** reads *before* the handler resumed (persistence looks broken when it isn't). Reproduce with real input and a settled microtask before it earns a finding.

## Phase 4 — Report as verified RESULTs, and set the state

Write `plan/live-check-<date>.md` in ATTEST form:
- **Header** — the flow, the surface (prod URL / real browser), which Phase-0 trigger(s) fired, and whose eyes (maker or checker — machine-read evidence makes this less eyes-dependent than the heuristic reviews, but still say it).
- **One `RESULT (verified)` per proven claim, each with its resolving pointer** — the command run, the sample count, the duration, the restored value. These are the only claims allowed the reserved words.
- **Explicit `not exercised` lines** for paths you couldn't reach — with *why* (env / hardware / gesture) and the residual `RISK` (severity + what would confirm it). Never let an un-run path read as passing by omission (ATTEST §3, rule 4).
- **A `BLOCKER`** if the runtime was unreachable at all (deploy didn't land, no cached model, WebGPU absent) — with the tried-trail.

**The gate:** a clean live-check is what moves the feature's honest state to `shipped`. A fail (or an unreachable runtime) caps it at *"implemented, not yet verified"* and hands the defect to the right sibling. Report worst-news-first; do not launder a partial run into a full pass.

## Playbook hook

If the user's config (CLAUDE.md / memory) or the project itself names a live-check or replay playbook for this kind of surface, read it before Phase 1 — it carries the concrete probes and gotchas this generic spec can't.
