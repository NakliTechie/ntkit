## Phase 4 — Build the interactive explorer (`demo/explorer.html`)

One self-contained, interactive page that goes **high-level → drill-down** in vanilla JS (collapsible sections, clickable nodes, a live filter; no build step):

- **Overview first**: what the project is, a map of its main areas, shipped vs in-progress at a glance.
- **Features**: each surface that actually exists (from the feature map in `verify/features/`, left by `/walkthrough-nt`, when one exists; else from routes, components and the README), grouped, with a one-line *value* statement. Click a feature to drill into its screens, what it depends on, and what it connects to. Mark **shipped vs in-progress** honestly; do not overclaim.
- **Connections**: a clickable map of feature and module relationships and data flow; click a node to jump to that feature.
- **Dependencies**: the real stack from the manifests, plus per-feature deps where derivable.
- **Inline search**: a sticky box that filters everything live (features, connections, deps) by name and description: a `data-search` attribute per card, a `.hidden` class on no-match, `/` to focus, `Esc` to clear (the `/guide-nt` pattern).
- **Curated and exec-ready**: built from the app's own `:root` design tokens, no dev chrome. **Status is curated, never a raw `plan/` dump**: `plan/` is private (dead ends, strategy); pull only public-safe signal.

### When the app has a strict CSP

An inline `<script>` or `<style>` fails under `script-src 'self'`. Split the page into `explorer.html`, `explorer.css` and `explorer.js` in `demo/`, and serve the three from the app's demo-only routes (Phase 2), so the hosted demo shows the explorer on its own origin. The **Launch** control then links `/demo`.
