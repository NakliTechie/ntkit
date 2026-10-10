---
description: "Launch readiness gate, marketing screenshots and video, drafted social posts. Drafts only, never posts."
argument-hint: "[focus: gate | assets | drafts]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Agent", "Skill", "mcp__claude-in-chrome__*"]
entry: "shipped or gate-green verifying; the readiness gate must pass — a red gate stops the run"
exit: "gate report + local, gitignored marketing/ (screenshots, cards, launch video; /windup-nt sweeps it) + drafted collateral (drafts, never posts)"
writes: "marketing/ (or the repo's existing card path), plan/launch-drafts.md, plan/launch-caption.txt, plan/launch-video-plan.md; .gitignore (`/plan`, `/marketing` and `/brag-output*` lines only); a missing README, LICENSE or llms.txt only on the user's yes"
---

Take the project from "the code is done" to "ready to announce": a deep ship-readiness gate, social-ready assets and a launch video, and drafted collateral.

`$ARGUMENTS` (optional): `gate` (readiness only), `assets` (screenshots, cards and launch video only), or `drafts` (collateral only). Empty = all three phases.

Example: `/package-nt gate`

`$SKILL` in the references is this skill's base directory, printed when the skill loads.

## Guards and stop-lines

These hold in every phase; this list is the authority.

- **Drafts, never posts.** Nothing is posted, published or sent.
- **One outward action: the repo's social card.** Upload it yourself through Claude-in-Chrome; it is the project's own repo setting, not a post. Without Claude-in-Chrome it becomes a manual step for the user. Procedure: [`references/social-preview.md`](references/social-preview.md).
- **A red gate stops the run.** Any blocker → say so loudly, skip Phases 2 and 3, and go to Phase 4 for the no-go headline. Going on is an illegal transition per ntkit's `STATES.md` (a kit doc, not a file in this project). The only path past a blocker is a logged override: a `/decide-nt "packaging despite <X> because <why>"` entry in this session, then proceed with a warning.
- **Never overridable:** a secret in the working tree or git history, and a tracked `plan/`. No `/decide-nt` entry moves past either.
- **Rotate, never rewrite.** Tell the user to rotate a leaked key, and how; a pushed key must be rotated regardless. Never rewrite git history yourself: a history scrub is advice for the user.
- **Flag, don't fix.** Don't edit code, the app's `<head>` or its static assets: flag it and give the exact change. You may offer to generate a *missing* README, LICENSE or `llms.txt` (new file only). Launch-blocking *decisions* point at `/decide-nt`.
- **Drafts stay local.** Launch drafts go to `plan/launch-drafts.md`, gitignored; never to a committed path.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Gate | A scorecard — `Ready ✓ · Blockers (must-fix before launch) · Nice-to-haves` — over the whole repo and its history: secrets, `plan/`, `/security-review` + `/forward-pass-nt`, README, social cards (repo + deployed app), LICENSE, agent face, docs, first-run tour, `llms.txt`, hygiene with a fresh-clone install, and Lighthouse + third-party requests against the **deployed** URL. Any blocker stops the run. | `references/gate.md` |
| 2 Assets | A local `marketing/` (gitignored, regenerable): heroes sized per channel, two 1280×640 social cards from one template, a launch video via the vendored brag (`demo` 15–25 s, or `promo` 35–45 s for leadership) or a named skip reason, frame 0 baked into every video and GIF, and a stranger test whose *what* and *who* match the README. | `references/assets.md` |
| 3 Drafts | `plan/launch-drafts.md`: one canonical caption, then X, LinkedIn, Show HN and domain-specific Reddit drafts and a sequenced where-to-post checklist, each tailored to this project and adding no claim the caption and README do not make. | `references/drafts.md` |
| 4 Summary | The scorecard, the asset paths (or why the video was skipped), the video's mode and path, the stranger-test answers, where the drafts live, and one headline: **launch-ready**, or **not launch-ready yet — fix N blockers first**. Nothing posted. | `references/summary.md` |
