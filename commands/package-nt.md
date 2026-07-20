---
description: Package a project for launch — a deep ship-readiness gate (/security-review + /forward-pass-nt + secrets + a launch-essentials checklist), social-framed marketing screenshots (committed), and drafted distribution collateral for X / LinkedIn / Show HN / tailored subreddits (local). Drafts, never posts.
argument-hint: "[focus: gate | assets | drafts]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
entry: "shipped or gate-green verifying; the readiness gate must pass — a red gate stops the run"
exit: "gate report + committed screenshots + drafted collateral (drafts, never posts)"
writes: "marketing/, local draft files"
---

Take the project from "the code is done" to "ready to announce." `/package-nt` is the bookend to `/scaffold-nt`: scaffold opens a project from a handoff; package ships it to the world. It runs a deep ship-readiness gate, generates social-ready screenshots, and drafts the distribution collateral — but it **drafts, it never posts**. Posting is outward-facing; that's yours to pull the trigger on.

If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): `gate` (readiness only), `assets` (screenshots only), or `drafts` (collateral only). Empty = all three phases.

## Phase 1 — Ship-readiness gate (deep) — this gates the rest

Don't generate launch assets for an unshippable repo. Run the full gate:

**Secrets — whole repo + history (the highest-stakes check).** A leaked key at launch is *the* disaster. Scan the **working tree and git history** for API keys, tokens, private keys, `.env` files, hardcoded credentials (known patterns + high-entropy strings), and confirm `.gitignore` covers secret files. `/security-review` is diff-scoped, so a launch *also* needs this whole-repo + history pass — a secret committed months ago is exactly what slips through a diff scan.
- A hit is a **hard blocker.** **Flag it and tell the user to rotate the key** (and how) — do **not** rewrite git history yourself. Rewriting is dangerous and a pushed key must be rotated regardless, so rotation is the real fix.

**Private working docs must not go public — `plan/` stays gitignored.** Planning docs (dead ends, half-baked thinking, internal strategy, and the launch drafts this command writes) leaking into a public repo is an embarrassing exposure. Verify the `plan/` folder — and any internal scratch / working-notes dirs — is **gitignored and not already tracked**: `git check-ignore plan/` matches *and* `git ls-files plan/` returns nothing.
- If `plan/` (or its contents) is already tracked → **hard blocker.** Flag it: `git rm -r --cached plan/`, add `plan/` to `.gitignore`, commit. If it was already pushed to a public remote, the history needs scrubbing too — and treat anything sensitive that was in it as exposed.

**Deep audit (folded in, per the launch standard).**
- Run **`/security-review`** for the vulnerability lens.
- Run **`/forward-pass-nt`** for the whole-app audit (bugs · stray code · leftover debug / test endpoints / backdoors — the embarrassing-at-launch class).
- Treat **Critical / High** findings as launch blockers; Medium / Low as nice-to-haves.

**Launch essentials.**
- **README** — exists with: one-line what-it-is, a hero screenshot/demo, install that actually works, usage, links (demo / source), license.
- **LICENSE** — present and appropriate to intent.
- **A `/guide-nt`** (or equivalent docs), a live/demo link, screenshots, a clear value prop.
- **An `llms.txt`** — the docs' agent face (the human-face/agent-face rule applied to documentation): a compact, LLM-ready summary of what the tool is, its API surface (`window.<app>` hooks, message channel, file formats), and how to drive it — so a coding agent pointed at the repo gets the surface without scraping. Offer to generate it from the README + code if missing. A large project may add `llms-full.txt` with the complete detail.
- **Repo hygiene** — GitHub description + topics set; no debug/junk files; and a **clean install from a fresh clone** (the newcomer path — same cold-start ethos as `/ux-review-nt`).

**Output — a scorecard:** `Ready ✓ · Blockers (must-fix before launch) · Nice-to-haves`. If there are blockers, say so loudly and **stop** — an illegal transition per `STATES.md`. The only path past a blocker is a deliberate, logged override: a `/decide-nt "packaging despite <X> because <why>"` entry in this session, after which proceed with a warning. (Secrets and tracked-`plan/` blockers are never overridable.) Don't auto-fix code — flag + suggest; you may offer to generate a *missing* README/LICENSE (new file only). Launch-blocking *decisions* point at `/decide-nt`.

## Phase 2 — Marketing assets → committed `marketing/`

Social-ready visuals, written into a committed `marketing/` folder (shippable, versioned):
- **Reuse the `/guide-nt` generator** if the repo has one (its screenshots); otherwise capture with the same Playwright pattern — prod build, hydration waits, and **WebGPU flows via the Chrome MCP** (headless has no WebGPU).
- Produce **social-framed** assets: a **hero** (the money screen), an optional **montage / GIF**, padded and sized for **X (~1600×900)**, **LinkedIn (1200×627)**, and a **square (1080×1080)**. Clean background, the best-looking screen, no dev chrome.
- Name by channel (`marketing/hero-x.png`, `marketing/hero-linkedin.png`, …) and list what landed.
- **Make sure `marketing/` is actually committable** — if the repo uses a `*`-plus-allowlist `.gitignore` (the naklios single-file pattern), allowlist `!marketing/` `!marketing/**` or the assets won't ship.

## Phase 3 — Distribution drafts → local `plan/` (gitignored)

Tailored, honest collateral — working material, so it stays local. Write `plan/launch-drafts.md` (gitignored — confirmed in Phase 1; never write launch drafts to a committed path):
- **X / Twitter** — 2–3 hook variants (≤280 chars) + an optional thread, each pointing at the hero image.
- **LinkedIn** — longer professional framing: problem → what you built → why it's different → link.
- **Show HN** — `Show HN: <name> — <one-liner>` + a body in HN's voice: what it is, why you built it, how it works, what's honestly limited, an invite to feedback. **No marketing voice** — HN punishes it.
- **Reddit** — suggest **specific subreddits derived from this project's actual domain** (not generic), each with a tailored draft **and a one-line note on that sub's self-promotion rules** (most restrict direct promo or want a participation ratio). Be honest about etiquette — no astroturf advice.
- **Optional** — a Product Hunt tagline + first comment, a dev.to / blog outline.
- A **where-to-post checklist** with sequencing (Show HN timing; don't simultaneously cross-post; lead with the channel that fits the audience).

Tailor every draft to *this* project — pull the value prop, the audience, and the honest "what's limited" from the README and the gate findings. Generic collateral is worse than none.

## Phase 4 — Summary + go / no-go

Print: the **scorecard** (ready / blockers / nice-to-haves), the **assets** generated (paths), and where the **drafts** live (`plan/launch-drafts.md`). End with a clear **go / no-go**:
- Blockers found → headline "**not launch-ready yet** — fix N blockers first," list them, point decisions at `/decide-nt`.
- Clean → headline "**launch-ready**," and hand over the kit: commit the `marketing/` assets (via `/windup-nt`), then post from `plan/launch-drafts.md` in the checklist's order.

Never post anything — `/package-nt` hands you a ready-to-fire kit; you pull the trigger.
