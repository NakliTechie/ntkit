## Phase 3 — Detect or scaffold the generator (the edit-vs-regenerate decision)

Look for an existing generator — a `guide/` or `demo/` folder with a capture script + builder (Bahi uses `demo/{capture.py,build_index.py,regenerate.sh}`).

- **It exists → you are UPDATING.** Read it. Add/adjust route-plan rows (each tagged with its `backend`) and **caption data** for new or changed features; **preserve every existing hand-written caption and section intro**. Then regenerate (Phase 5) — full, or *scoped* to the changed role/feature. **Do not patch `index.html` by hand** — it's regenerated output; edits there are lost on the next run.
- **None exists → SCAFFOLD one**, modelled on the Bahi pattern, generalized to whatever Phase 1 detected:
  - `guide/capture.*` — route-plans per role, each row carrying a `backend` (Phase 4).
  - `guide/build_index.py` — `CAPTIONS` (slug → title + one-line description) and `SECTIONS` (title, intro, item-slugs) as **data**, assembled into `guide/index.html` (Phase 5).
  - `guide/regenerate.sh` — ensure each needed surface is up (dev server / built binary / built .app) → capture → build (Bahi's orchestration; idempotent server start).

**The rule:** the output HTML is generated; the source of truth is the generator's *data* (route-plans + captions + sections). Updating = edit data → regenerate. This is why regenerate beats hand-editing — a full rebuild re-shoots captures and re-assembles HTML but **never loses prose**, because the prose isn't in the HTML.
