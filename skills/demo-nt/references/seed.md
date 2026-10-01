## Phase 1 — The shared demo seed

The demo data is **one canonical asset, `demo/seed/`**, that `/walkthrough-nt`, `/guide-nt` and `/demo-nt` all load. Locate it, or scaffold it: the data files and a small loader the app can call.
- It is **committed and grows with the app**: every new feature extends the seed, so a demo never lands on an empty or half-built screen.
- If `/walkthrough-nt` or `/guide-nt` already injects seed data ad hoc, **promote it into `demo/seed/`** so the three share one source. (`/ux-review-nt` is the exception: it wipes state to test the cold newcomer.)

### A server app: seed through the real API

When the app has a server and a database, the seed is a script, not a data dump.

- **Create the minimum by direct insert, the rest through the API.** Insert only what has no API path: the fictional people, their roles, a session per person, and a credential where the app needs one. Everything a user makes (lists, content, approvals, sends, RSVPs, replies) goes through the running app's own endpoints, as the persona who would make it, so the seed hits real validation, audit and side effects and breaks loudly when an API changes.
- **Signed actions are signed, never bypassed.** If an action needs a signature (a passkey approval, a signed webhook), the seed generates a key pair per persona, registers the public half as that persona's credential, and signs the real challenge the app issues, for the demo's own `ORIGIN` and `RP_ID`. Never add a "skip signature in demo" branch to the app.
- **Fictional and stable.** Invented names, outlets and organisations; `example.*` or reserved domains for email; phone numbers in an unused range. The same personas on every reset. Nothing copied from production.
- **Tell the story in data.** Seed each state the demo will show: something published, something waiting for approval, a draft, an overdue item, a pending verification. An empty column is a gap in the seed.
- **Write the personas file.** The seed ends by writing a personas file (key, id, name, group, role, one-line blurb) to a path outside the served tree, for Phase 2's sign-in page. Its path is the value of the demo-only env var.

### The reset script (`demo/reset.sh`)

One command rebuilds the demo from nothing, so a presenter can wipe what visitors did:

1. Load the demo settings file `~/.config/<project>-demo/env` (Phase 5 writes it in hosted mode). Local-only mode has none: the script then sets the local demo values itself, namely the demo port from Phase 3, a database named `<project>_demo`, and `127.0.0.1` as the origin.
2. Stop the app and worker if they run as services.
3. Drop and recreate the **demo** database only, by the name from step 1. The script never takes a database name from anywhere else.
4. Run migrations and the app's base seed, and create the storage bucket.
5. Start the app and worker, and wait on the health endpoint with a timeout that fails loudly.
6. Run `demo/seed/` against the running app, and print the origin.
