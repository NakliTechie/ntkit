## Phase 7 — The presenter protocol (`plan/demo-protocol.md`)

The repo's `demo/` holds the mechanics. The protocol file holds the playbook: how to show this project to a person, from this machine, in this state. Write it on the first run and update it in place on later runs, so it matches what the run just booted and probed.

**Where it lives.** `plan/` is private and gitignored, which is why addresses and machine paths may go here. Before writing, confirm `git check-ignore -q plan` exits 0 and `git ls-files plan` is empty. If `plan` is missing, create it per ntkit's `MEMORY.md` §0 (a folder or a symlink; never replace a link). If `plan` is not ignored, append `/plan` to `.gitignore`.

**What kind of file it is.** It is a working document owned by `/demo-nt`, like `/package-nt`'s launch drafts. It holds no work items, so the record and derived-file rules in `MEMORY.md` do not bind it. A demo gap the run finds (a missing seed state, a broken flow) goes in the run's final reply, not into `pending.md`.

**Never in it:** a secret, a token, a credential file's contents, or a real person's contact detail. Name where secrets live (`~/.config/<project>-demo/env`, `~/.cloudflared/`), never their values.

### Sections

1. **Addresses.** The live demo (`/demo` in hosted mode, else the local URL), the explorer, and any hostname that is not for people (storage).
2. **What runs where.** Local-only or hosted. For hosted: the tunnel name, the config and credentials paths, the zone, the launchd labels, the ports, the demo database and bucket names, the settings file path, the log directory, and which checkout and branch the demo serves. Say that mail and SMS are dev stand-ins that write to the log.
3. **Before a demo** (a numbered list that fits in 5 minutes): machine awake and on power, container runtime running, `demo/reset.sh`, a health check with its expected output, one sign-in with what the first screen must show, device passkey enrolment for any passkey-gated persona, the explorer open in a second tab.
4. **The personas.** Every persona from the seed with role and what they show. Say they are fictional and identical after every reset.
5. **Storylines by audience.** One short path per audience that matters to this project (for example: a senior decision-maker in 10 minutes, a day-to-day user in 5, a technical reviewer). Each is a sequence of persona sign-ins and screens that tells one story. Always include: say up front that the data is fictional, and name what is "next" as the explorer marks it.
6. **After a demo.** Reset to wipe visitors' changes. What a reset does not remove (passkeys on visitors' devices). How to take the demo offline and bring it back (the tunnel agent's `bootout` and `bootstrap`).
7. **Keeping it current.** A new feature extends `demo/seed/` and the explorer, then a reset. `/demo-nt` rebuilds and reprints the links.
8. **Safety rails (do not remove).** Demo sign-in exists only with its env var and is refused in production. Each public hostname's probe result from Phase 6, with the date. The demo's own database and secret, never real data.

Worked example: samvad's `plan/demo-protocol.md` (66 lines) follows these eight sections, with storylines for a senior office, press partners, technical reviewers, and anyone.
