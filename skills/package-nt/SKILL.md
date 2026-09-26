---
description: "Launch readiness gate, marketing screenshots, drafted social posts. Drafts only, never posts."
argument-hint: "[focus: gate | assets | drafts]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task", "Skill"]
entry: "shipped or gate-green verifying; the readiness gate must pass — a red gate stops the run"
exit: "gate report + committed screenshots and launch video + drafted collateral (drafts, never posts)"
writes: "marketing/, plan/launch-drafts.md, plan/launch-caption.txt, plan/launch-video-plan.md"
---

Take the project from "the code is done" to "ready to announce." `/package-nt` is the bookend to `/scaffold-nt`: scaffold opens a project from a handoff; package ships it to the world. It runs a deep ship-readiness gate, generates social-ready screenshots, and drafts the distribution collateral — but it **drafts, it never posts**. Posting is outward-facing; that's yours to pull the trigger on.

If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): `gate` (readiness only), `assets` (screenshots, cards and launch video only), or `drafts` (collateral only). Empty = all three phases.

Example: `/package-nt gate`

## Guards and stop-lines

These hold in every phase. The phase files repeat them where they apply; this list is the authority.

- **Drafts, never posts.** Nothing is posted, published or sent. `/package-nt` hands over a ready-to-fire kit; the user pulls the trigger.
- **One outward action: the repo's social card.** Uploading the card image through **Claude-in-Chrome** is the one outward action `/package-nt` takes itself — it is the project's own repo setting, not a post. Only if Claude-in-Chrome is unavailable does it become a manual step for the user. Procedure: [`references/social-preview.md`](references/social-preview.md).
- **A red gate stops the run.** Any blocker → say so loudly, skip Phases 2 and 3, and go to Phase 4 for the no-go headline. Going on is an illegal transition per ntkit's `STATES.md` (kit doctrine — not a file in this project). The only path past a blocker is a deliberate, logged override: a `/decide-nt "packaging despite <X> because <why>"` entry in this session, after which proceed with a warning.
- **Never overridable:** a secret in the working tree or git history, and a tracked `plan/`. No `/decide-nt` entry moves past either.
- **Rotate, never rewrite.** A secret hit is flagged with an instruction to rotate the key, and how. Do not rewrite git history yourself; a pushed key must be rotated regardless.
- **Flag, don't fix.** Don't auto-fix code — flag + suggest. You may offer to generate a *missing* README/LICENSE (new file only). Launch-blocking *decisions* point at `/decide-nt`.
- **Drafts stay local.** Launch drafts go to `plan/launch-drafts.md`, gitignored; never to a committed path.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Gate | A scorecard — `Ready ✓ · Blockers (must-fix before launch) · Nice-to-haves` — over the whole repo and its history: secrets, `plan/` ignored and untracked, `/security-review` + `/forward-pass-nt` (Critical / High block), README in the house shape, a social card on the repo and on the deployed app, LICENSE, agent face with parity, docs + demo + value prop, first-run tour, `llms.txt`, repo hygiene with a fresh-clone install, and Lighthouse SEO + Agentic Browsing + third-party requests against the **deployed** URL. Any blocker stops the run. | `references/gate.md` |
| 2 Assets | A committed, committable `marketing/`: heroes sized per channel, two 1280×640 social cards from one template (repo + deployed app), a 15–25 s launch video via `/brag-slim` or a named skip reason (the video never blocks), a settled frame 0 baked into every video and GIF, and a stranger test whose *what* and *who* match the README. | `references/assets.md` |
| 3 Drafts | `plan/launch-drafts.md`, opening with one canonical caption, then X, LinkedIn, Show HN and domain-specific Reddit drafts, optional extras, and a sequenced where-to-post checklist — every draft tailored to this project, adding no claim the caption and README do not make. | `references/drafts.md` |
| 4 Summary | The scorecard, the asset paths (or why the video was skipped), the stranger-test answers, where the drafts live, and one headline: **launch-ready**, or **not launch-ready yet — fix N blockers first**. Nothing posted. | `references/summary.md` |
