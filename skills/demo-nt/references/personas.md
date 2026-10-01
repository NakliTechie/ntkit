## Phase 2 — Persona sign-in (apps with accounts only)

Skip this phase when the app has no sign-in. Otherwise build a demo-only page that signs in as any fictional persona in one click, so the presenter never types an OTP or waits for an email in front of the room.

### The page (`/demo`)

- **Lists every persona from the personas file** (Phase 1), grouped by role: name, role, one-line blurb saying what that persona shows. One **Sign in** button each.
- **Signs in through the app's own session code.** The button calls a demo route that starts an ordinary session for that persona's id. Session cookies, roles and audit rows are the real ones; only the credential check is skipped.
- **Links the explorer** (`/demo/explorer.html`), served by the same demo-only routes, so a hosted demo needs one origin for both.

### The gate (not optional)

- **Registered only when the demo env var is set** (it points at the personas file). With it unset, the routes do not exist: no 404 page that names them, no hidden link.
- **Refused in production, at startup.** The app throws before it listens when the demo env var is set in production mode. Put the check in the config module, where the other production refusals live, and again in the demo module, so a deploy that forgets to unset the var fails to start.

### Passkey-gated actions: enrol the presenter's device

A persona whose job needs a passkey (an approver who signs) cannot use the seed's private key from a browser. Do not add a signature bypass. Instead:

- The staff card gets a second button, **Add a passkey on this device**. It asks the app to issue an ordinary enrolment invite for that persona and redirects to the app's real enrolment page.
- The presenter enrols once per device, with the device's own authenticator. Every later approval is a real WebAuthn signature against the demo's `RP_ID`.
- Say in the protocol file (Phase 7) that passkeys are per device, and that a reset removes the server side only.
