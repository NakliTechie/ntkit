## Phase 1 — Ship-readiness gate

**Secrets: working tree and git history.** Scan both, and confirm `.gitignore` covers secret files. `/security-review` scans only the diff, so it misses a key committed months ago.
- A hit → hard blocker. Name the file and the commit, and tell the user to rotate the key, and how.

**`plan/` ignored and untracked.** Check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives) (`git check-ignore -q plan`; add `/plan`, no trailing slash: `plan` may be a symlink), and `git ls-files plan` is empty. Check internal scratch or notes dirs the same way.
- Tracked → hard blocker. Suggest `git rm -r --cached plan`, `/plan` in `.gitignore`, and a commit. If it reached a public remote, tell the user to treat its contents as exposed; scrubbing that history is advice for the user, not your action.

**Deep audit.** Run `/security-review` and `/forward-pass-nt`. Critical / High findings → blockers; Medium / Low → nice-to-haves.

**Launch essentials.**
- **README** — check it against `~/.claude/reference/naklitechie-doctrines/README-DOCTRINE.md` when present; without it, the required sections are a header sentence, constraints, up to four claim badges, one hero, Install before Why, product sections, commands, verification, license, and documentation pointers. A missing required section or a README over 120 lines → blocker; name the section. Missing comparisons with alternatives never block.
- **Social card on both surfaces the project has.**
  - **Repo:** `gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){usesCustomOpenGraphImage}}'` must print `true`; `false` → blocker. Clear it yourself once no other blocker stands: render the card per [`social-card-build.md`](social-card-build.md) and upload it per [`social-preview.md`](social-preview.md). Also check the repo's About description (`gh repo edit --description`) is current; it feeds `og:title`/`og:description`, and a README rebuild never touches it.
  - **Deployed app (any project with a live URL):** `curl -s <deployed-url> | grep -i 'og:image\|twitter:image\|og:title'`, never localhost. No `og:image`/`twitter:image` resolving to an absolute, live image → blocker. The finding carries the exact change from [`social-card-build.md`](social-card-build.md); you do not edit the app.
- **LICENSE** — present and fit for the project's intent. Missing → blocker; offer to generate one.
- **Agent face with parity** — from `/forward-pass-nt`'s agent-readiness lens (run it, or re-read a recent one). A surface meant to be agent-operated with no declared tool manifest (MCP tools, `window.<app>.tools`, a documented API or CLI contract) → blocker. Parity is `manifest ⊇ command bus`, each omission fixed or marked person-only, mutating entries staged; a gap with no live consequence → nice-to-have, named.
- **Docs, demo, value prop** — a `/guide-nt` guide or equivalent docs, a live or demo link, screenshots, a clear value prop. Missing → nice-to-have.
- **First-run tour** — a tool with a surface ships the guided tour per `~/.claude/reference/naklitechie-doctrines/BUILD-DOCTRINE.md` (*Surface conventions*). Absent → nice-to-have.
- **`llms.txt`** — present and current. Missing → nice-to-have; offer to generate it from the README and code.
- **Repo hygiene** — GitHub description and topics set, no debug or junk files (each miss → nice-to-have), and a clean install from a fresh clone (fails → blocker).

**Machine-face audit (web projects): Lighthouse SEO and Agentic Browsing against the deployed URL.** Each failing audit → nice-to-have, named.
- One `aria-label` on a role-less `div` can sink Agentic Browsing.
- SPA hosts serve `200 text/html` for a missing `robots.txt` or `llms.txt`. Fetch both from the live host and require `text/plain`; HTML → nice-to-have, named.
- **Third-party requests** — list the hosts the live page calls. When the README claims the tool runs entirely in the browser or has no tracking, any third-party host → blocker (suggest vendoring it); otherwise → nice-to-have.

**Output: a scorecard** — `Ready ✓ · Blockers (must-fix before launch) · Nice-to-haves`. Any blocker stops the run (SKILL.md guards).
