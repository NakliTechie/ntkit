---
description: Launch the project for a live demo — boot it with the shared demo-seed data (the same asset /walkthrough-nt and /guide-nt use), and generate + open an interactive HTML explorer (features · connections · dependencies, high-level → drill-down, with inline search), then hand you clickable links to both the live app and the explorer. For demoing work-in-progress to customers or execs.
argument-hint: "[focus: seed | explorer | launch]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "app boots with the shared demo seed"
exit: "live-app and explorer links handed to the presenter"
writes: "nothing durable"
---

A presenter's launcher for live demos. When you need to show work-in-progress to a customer or a senior exec, `/demo-nt` does two things: boots the real app **seeded and ready** (no empty-state fumbling in front of the room), and builds + opens an **interactive explorer** — a drill-down map of what's been built (features · connections · dependencies) with inline search — then hands you **clickable links to both**.

Where `/guide-nt` *documents* how to use features and `/ux-review-nt` *critiques* the cold newcomer path, `/demo-nt` is **presenter mode**: the app is running, seeded, and the story is on one page.

If the project has no runnable surface, say so. If the current directory isn't a git repo, ask which project — don't guess. `$ARGUMENTS` (optional): `seed`, `explorer`, or `launch` to run just that part.

## Phase 1 — The shared demo seed (the load-bearing asset)

The demo data is **one canonical asset — `demo/seed/`** — that `/walkthrough-nt`, `/guide-nt`, and `/demo-nt` all load. Locate it, or scaffold it: the data files + a small loader the app can call (the way Bahi loads a sample `.khata`, or LocalMind seeds IndexedDB + injects sample content).
- It's **committed and grows with the app**: every new feature extends the seed, so a demo never lands on an empty or half-built screen, and all three commands stay current automatically.
- If `/walkthrough-nt` or `/guide-nt` already injects seed data ad-hoc, **promote that into `demo/seed/`** so the three share one source instead of drifting apart. (`/ux-review-nt` is the deliberate exception — it wipes state to test the cold newcomer.)

## Phase 2 — Boot the app, seeded and ready

Start the app and get it demo-ready:
- **Production build, in a real browser** — this is a *live* demo on your machine, so run it where the audience will see it (a real GPU browser — **WebGPU works here**, unlike the headless capture commands).
- Load `demo/seed/`, and land on the **best opening screen** — the one that tells the story fastest, not a blank dashboard.
- **Confirm it's actually ready** — no console errors, data populated, the key flows click through. A demo that breaks in front of an exec is exactly the failure this command exists to prevent; rehearse the happy path once.

## Phase 3 — Build the interactive explorer (`demo/explorer.html`)

A single self-contained, **interactive** page that goes **high-level → drill-down** — as far as vanilla JS in one file allows (collapsible sections, clickable nodes, a live filter; no build step):

- **Overview first** — open on the big picture: what the project is and a map of its main areas/modules, shipped-vs-in-progress at a glance. Everything below drills down from here.
- **Features** — each surface that actually exists (derive from routes / components / the README), grouped, with a one-line *value* statement (what it does for the user). **Click a feature to drill in**: its screens, what it depends on, and what it connects to. Honestly mark **shipped vs in-progress** — it's a WIP demo; set expectations, don't overclaim.
- **Connections** — how the pieces relate: a clickable **map** of feature/module relationships and data flow (what feeds or calls what); click a node to jump to that feature's detail. Where a graph is overkill, a per-feature "connects to / depends on" list does the job.
- **Dependencies** — the real stack from the manifests, plus per-feature deps where derivable — the "how it's built" for the technical execs.
- **Inline search** — a sticky box that filters **everything** live (features, connections, deps) by name/description: a `data-search` attribute per card, toggle a `.hidden` class on no-match, `/` to focus, `Esc` to clear (the `/guide-nt` pattern). In a meeting you type a term and jump straight to it.
- **Curated, polished, exec-ready** — built from the app's own `:root` design tokens (like `/guide-nt`), no dev chrome. **Status is curated, never a raw `plan/` dump** — `plan/` is private (dead ends, strategy); pull only public-safe signal. This is the first thing the room sees.

## Phase 4 — Present + open, and hand over the two links

Serve both and confirm they work — the explorer renders and its search filters, and the **Launch** control reaches the seeded app. Then **end the run by printing two clickable links** so you can open either in one move when the meeting starts:

- **→ Live demo** — the running, seeded app (the URL from Phase 2).
- **→ Explorer** — `demo/explorer.html` (served, or `file://`).

Also note the opening screen, what's seeded, and that the seed is now shared with `/walkthrough-nt` and `/guide-nt`.

**Privacy:** the explorer is committed (`demo/`, so it evolves with the app), but **curated for the audience** — the built-and-coming story, not the internal kitchen. If the repo is public or the WIP is sensitive, gitignore `demo/explorer.html` instead — a one-line change.
