---
description: "Boot the app on the demo seed, open a feature explorer, optionally host it publicly."
argument-hint: "[focus: seed | explorer | launch | host | probe] [host=<demo-hostname>] [files=<storage-hostname>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent", "mcp__claude-in-chrome__*", "mcp__Claude_Browser__*"]
entry: "app boots with the shared demo seed; hosted mode also needs host=<hostname> in a zone the user named"
exit: "live-app and explorer links handed to the presenter; hosted: every public hostname refused the anonymous probe first"
writes: "plan/demo-protocol.md (created or updated in place)"
---

A presenter's launcher for live demos: boot the real app **seeded and ready**, build an **interactive explorer** of what's been built (features, connections, dependencies, inline search), and hand over **clickable links to both**. Drive the browser with Claude in Chrome (a real GPU browser) or the built-in browser pane; Playwright runs through Bash.

If the project has no runnable surface, say so.

## Inputs and defaults

- **Focus** (`$ARGUMENTS`, optional): `seed` runs Phase 1 only, `explorer` runs Phase 4, `launch` runs Phases 3 and 8 (boot the seeded app, hand over the links). `host` runs Phases 5–7 against an app that already boots; `probe` runs Phase 6 alone. Default: every phase that applies.
- **`host=<hostname>`** (default: unset → **local-only mode**, the demo runs on `127.0.0.1` and nothing is published). Setting it selects **hosted mode**: a public URL served from this machine through a named Cloudflare tunnel. Its registered domain is the only zone the run may touch.
- **`files=<hostname>`** (default: unset). A second public hostname for object storage, needed only when the app hands browsers presigned storage URLs. Must sit in the same zone as `host=`.
- **Persona sign-in**: built when the app has accounts; skipped when it has none. Announced either way.

Examples: `/demo-nt` (local) · `/demo-nt host=demo.<your-domain>` · `/demo-nt host=<app>.<your-domain> files=<app>-files.<your-domain>` · `/demo-nt probe host=<app>.<your-domain>`.

## Guards and stop-lines

These hold in every phase.

- **No zone named, nothing published.** Without `host=`, the run creates no tunnel, no DNS record and no public URL. `host` or `probe` focus without `host=` stops with that reason and asks for the hostname.
- **Only the named zone.** Never create a Cloudflare account, an API token, a key, or a DNS record in a zone the user has not named. Never overwrite an existing DNS record (`--overwrite-dns` is never passed); an existing record stops the phase.
- **User step: the Cloudflare authorisation.** `cloudflared tunnel login` needs the user in a browser to sign in and pick the zone. Print the command and wait; never drive it.
- **Probe before the link.** In hosted mode, Phase 6 is not optional. An anonymous list, read or write that succeeds on any public hostname is a blocker: the public link is not printed until a re-probe refuses it.
- **Fictional data, separate everything.** The demo uses its own database, bucket and secret, never real or production data. Mail and SMS stay on the app's dev stand-ins; no provider key goes into demo settings.
- **Demo sign-in never reaches production.** Persona sign-in exists only when its env var is set, and the app refuses to start with that var in production mode. No signature bypass: passkey-gated actions use the app's real enrolment.
- **No secrets in the repo.** Tunnel credentials and the demo secret stay in `~/.cloudflared/` and `~/.config/<project>-demo/`; the protocol file names paths, never values.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead. Local-only mode runs Phases 1–4, 7 and 8.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Seed | One committed `demo/seed/`, shared with `/walkthrough-nt` and `/guide-nt`. Server apps: fictional people inserted, everything else through the real API (signed actions really signed), a personas file, and `demo/reset.sh`. | `references/seed.md` |
| 2 Personas | Apps with accounts: a `/demo` page that signs in as each fictional persona in one click, registered only when the demo env var is set, refused in production, with "Add a passkey on this device" through the real enrolment flow. | `references/personas.md` |
| 3 Boot | The production build running, seeded, on the best opening screen, with no console errors and the happy path rehearsed per role; mail and SMS writing to the log. | `references/boot.md` |
| 4 Explorer | `demo/explorer.html`: overview, features (shipped vs in-progress), connections, dependencies, live inline search; curated, never a `plan/` dump. | `references/explorer.md` |
| 5 Host | Hosted mode: tunnel, one DNS record per named hostname, ingress, a settings file outside the repo (origin, RP ID, trust-proxy, demo database, fresh secret), CSP on the public origins, launchd agents for app, worker and tunnel. | `references/host.md` |
| 6 Probe | Hosted mode: every public hostname probed with no credentials for list, read and write, each refused, with a positive control; results dated for the protocol. | `references/probe.md` |
| 7 Protocol | `plan/demo-protocol.md` created or updated: addresses, what runs where, before-a-demo checklist, personas, storylines per audience, after-a-demo steps, safety rails. | `references/protocol.md` |
| 8 Hand over | The two links, below. | this file |

## Phase 8 — Hand over the two links

Serve both and confirm in a browser that the explorer renders, its search filters, and its **Launch** control reaches the seeded app. End the run with two clickable links:

- **→ Live demo** — the running, seeded app (the URL from Phase 3; in hosted mode `https://<host>/demo`, printed only after Phase 6 passed).
- **→ Explorer** — `demo/explorer.html` (served, or `file://`; in hosted mode `https://<host>/demo/explorer.html`).

Also note the opening screen, what's seeded, and where the protocol file is. In hosted mode, add the reset command and how to take the demo offline.

**Privacy:** the explorer is committed (`demo/`) but curated for the audience: the built-and-coming story, not the internal kitchen. If the repo is public or the WIP is sensitive, gitignore `demo/explorer.html` instead.
