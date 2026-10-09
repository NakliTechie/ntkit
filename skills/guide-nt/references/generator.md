## Phase 3 — Detect or scaffold the generator

Look for an existing generator: a `guide/` or `demo/` folder with a capture script and a builder.

- **It exists → you are updating.** Read it. Add or adjust route-plan rows (each tagged with its `backend`), `HERO_FLOW` (add it if missing), and **caption data** for new or changed features; **preserve every existing hand-written caption and section intro**. Then regenerate (Phase 5), in full or scoped to the changed role or feature. Do not patch `index.html` by hand; the next run overwrites it.
- **None exists → scaffold one**, fitted to whatever Phase 1 detected:
  - `guide/capture.*`: route-plans per role, each row carrying a `backend` (Phase 4), plus the `HERO_FLOW` list (Phase 2) as a top-level constant, so `grep HERO_FLOW` finds it.
  - `guide/build_index.py`: `CAPTIONS` (slug → title + one-line description) and `SECTIONS` (title, intro, item slugs) as **data**, assembled into `guide/index.html` (Phase 5).
  - `guide/regenerate.sh`: bring up each needed surface (dev server, built binary, built .app) with an idempotent start → capture → build.
