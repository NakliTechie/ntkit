## Phase 4 — Build the interactive explorer (`demo/explorer.html`)

A single self-contained, **interactive** page that goes **high-level → drill-down** — as far as vanilla JS in one file allows (collapsible sections, clickable nodes, a live filter; no build step):

- **Overview first** — open on the big picture: what the project is and a map of its main areas/modules, shipped-vs-in-progress at a glance. Everything below drills down from here.
- **Features** — each surface that actually exists (derive from the feature map — `verify/features/`, left by `/walkthrough-nt` — when one exists; else from routes / components / the README), grouped, with a one-line *value* statement (what it does for the user). **Click a feature to drill in**: its screens, what it depends on, and what it connects to. Honestly mark **shipped vs in-progress** — it's a WIP demo; set expectations, don't overclaim.
- **Connections** — how the pieces relate: a clickable **map** of feature/module relationships and data flow (what feeds or calls what); click a node to jump to that feature's detail. Where a graph is overkill, a per-feature "connects to / depends on" list does the job.
- **Dependencies** — the real stack from the manifests, plus per-feature deps where derivable — the "how it's built" for the technical execs.
- **Inline search** — a sticky box that filters **everything** live (features, connections, deps) by name/description: a `data-search` attribute per card, toggle a `.hidden` class on no-match, `/` to focus, `Esc` to clear (the `/guide-nt` pattern). In a meeting you type a term and jump straight to it.
- **Curated, polished, exec-ready** — built from the app's own `:root` design tokens (like `/guide-nt`), no dev chrome. **Status is curated, never a raw `plan/` dump** — `plan/` is private (dead ends, strategy); pull only public-safe signal. This is the first thing the room sees.

### When the app has a strict CSP

An inline `<script>` or `<style>` fails under `script-src 'self'`. Split the page into `explorer.html` + `explorer.css` + `explorer.js` in `demo/`, and serve the three from the app's demo-only routes (Phase 2), so the hosted demo shows the explorer on its own origin. The **Launch** control then links `/demo`. Worked example: samvad `demo/explorer.{html,css,js}`, with statuses Built / Needs accounts / Next.
