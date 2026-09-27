## Phase 3 — Boot the app, seeded and ready

Start the app and get it demo-ready:
- **Production build, in a real browser** — this is a *live* demo on your machine, so run it where the audience will see it (a real GPU browser — **WebGPU works here**, unlike the headless capture commands).
- Load `demo/seed/`, and land on the **best opening screen** — the one that tells the story fastest, not a blank dashboard.
- **Confirm it's actually ready** — no console errors, data populated, the key flows click through. A demo that breaks in front of an exec is exactly the failure this command exists to prevent; rehearse the happy path once.

### A server app with persona sign-in

"Production build" means the built assets, not the dev server. The runtime mode is the exception: persona sign-in (Phase 2) is refused in production mode, and dev mode is what turns on the mail and SMS stand-ins. So a server demo runs the production build in the app's **development (non-production) mode**, and the app must still refuse its public development secret for any origin that is not localhost (samvad: `src/config.ts`). If the app lacks that refusal, add it before hosting.

- **Mail and SMS go to the log.** Confirm the app's dev stand-ins are active: a sign-up or send writes the message to the app log, and no provider key is set in the demo settings. Nothing leaves the demo.
- **Listen on 127.0.0.1 only**, on a port distinct from local development (samvad: 8090 beside dev's 8080), so the demo and dev can run at once.
- **Rehearse per role.** Sign in as each persona the storyline uses, and click the flow once.
