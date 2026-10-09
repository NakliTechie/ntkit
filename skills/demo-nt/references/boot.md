## Phase 3 — Boot the app, seeded and ready

- **Production build, in a real browser** where the audience will see it: a real GPU browser, so **WebGPU works here**, unlike in headless capture.
- Load `demo/seed/`, and land on the **best opening screen**: the one that tells the story fastest, not a blank dashboard.
- **Confirm it's ready**: no console errors, data populated, the key flows click through.

### A server app with persona sign-in

"Production build" means the built assets, not the dev server. The runtime mode is the exception: persona sign-in (Phase 2) is refused in production mode, and dev mode turns on the mail and SMS stand-ins. So a server demo runs the production build in the app's **development (non-production) mode**, and the app must still refuse its public development secret for any origin that is not localhost. If the app lacks that refusal, add it before hosting.

- **Mail and SMS go to the log.** Confirm the app's dev stand-ins are active: a sign-up or send writes the message to the app log.
- **Listen on 127.0.0.1 only**, on a port distinct from local development, so the demo and dev can run at once.
