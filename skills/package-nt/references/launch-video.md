## The launch video (Phase 2)

Made by brag, vendored in [`brag/`](brag/VENDORED.md). You assemble the direction and take the output; brag owns the story, visuals, audio and render.

### Pick the mode: who watches it

| Mode | For | Length |
|---|---|---|
| `demo` (default) | People who will use or install it | 15–25 s |
| `promo` | Leadership and non-technical viewers | 35–45 s |

Use `promo` when the user asks for a promo, or names a leadership, executive or non-technical audience. Otherwise use `demo`.

### Pick the path: which brag runs

| When | Path | Read and follow |
|---|---|---|
| You are a current Claude Opus model (brag's own docs name Opus 5.5), and the user did not ask for the full workflow or a voiceover | brag-slim: you build and render the video with local tools | `brag/slim.md` |
| Any other model, you cannot tell which model you are, or the user asked for the full workflow or a voiceover | full brag: Hyperframes builds and renders | `brag/brag.md` |

Read the file and follow it for the rest of this step, with the direction below as the user's input. brag is not an installed skill, so do not use the Skill tool for it. Read `<skill-dir>` in either file as `$SKILL/references/brag/`.

### Preconditions: a miss skips the video, it never blocks the run

- **`ffmpeg -version` exits 0.** A Homebrew upgrade can leave a binary on `PATH` that no longer loads its libraries; the fix is `brew upgrade ffmpeg`.
- **A surface to show**: a browser app, or a CLI whose transcripts show it working.
- **Full path only**: `node --version` is 22 or later, `npx hyperframes doctor` passes, and the Hyperframes companion skills are installed (`npx hyperframes skills`). Offline or refused → skip with the reason.
- **Music** is not vendored (license; `brag/VENDORED.md`). The full path runs without it, or with a track the user supplies; tracks in `brag/assets/music/` stay out of commits.

### The direction

Hand brag one brief with every item below; do not invoke it and then feed the direction piece by piece.

- **Input**: the project directory; the deployed URL only when the repo cannot be served locally.
- **Tone** from the house shape the Unity sentence names (`~/.claude/reference/naklitechie-doctrines/DIRECTIONS.md`):

  | Shape | brag tone |
  |---|---|
  | Calm | `polished` |
  | Dense | `app-store` |
  | Mono | `deadpan` |

  No Unity sentence → `polished`. Use the loud presets (`chaotic`, `yc-parody`, `cinematic`) only when the user asks for one.
- **Length**: for `promo`, pass `--duration 40` on either path. `demo` takes brag's default.
- **Storyboard beats, `demo`**: when the `/guide-nt` generator (`guide/capture.*` or `demo/capture.*`) defines `HERO_FLOW`, pass those captures in order as the entry → key action → result beats, each with its target (URL or command). Without `HERO_FLOW`, derive the flow from the README's "how it works" and the main route.
- **Storyboard beats, `promo`**: one beat per key feature the product has today, from the README and the feature list. Each beat is a headline of a few words saying what the viewer gets from it, held 3–4 s, over a screen that moves: crop, zoom, pan, or a desktop screen paired with a phone screen. Open with who it is for; add no supporting line unless it earns its place.
- **What, not how or who (`promo`)**: show what the product lets the viewer do. Leave out approvals and sign-off, verification methods, owners, deadlines, statuses, roles and security mechanics. Crop or mask that part of a screen; never edit the text inside one.
- **No technical artefacts (`promo`)**: no URL, repo, install line, command, code, version string or hash, file name, stack name, or jargon (API, passkey, token, database) in any line or on any screen. Crop address bars and version lines out of screens.
- **Data**: the demo seed (`demo/seed/`) when it exists. Never real user data, secrets or credentials, in the brief or on a screen.
- **Claims**: only what the README and the gate findings support. No invented numbers, users, or testimonials.
- **Audience**: who it is for, said on screen in the first 10 seconds, in the README's words. When the README never names an audience, derive one from what the product does and its stated scope and limits. When the user names the audience, use their words.
- **Sample-data label**: when screens show fictional sample content and a real person or organisation is named on screen, every frame with a screen carries a small, readable "Sample data" label.
- **Last beat, `demo`**: the name and how to get it: the deployed URL when there is one, else the repo URL and the install line.
- **Last beat, `promo`**: the name alone. The caption and the post carry the link.
- **Full path, no waiting**: brag's step 4 starts a preview and asks before it renders. Render straight away unless the user is present and asked to review; `/package-nt` checks the result itself (step 3 below, then the stranger test).

### Take the output

Both paths write `brag-output/` (or `brag-output-<timestamp>/` when that exists) in the project root.

1. Copy `brag.mp4` → `marketing/launch.mp4` and `brag.jpg` → `marketing/launch.jpg`.
2. Copy `share-copy.txt` → `plan/launch-caption.txt` and `brag-plan.md` → `plan/launch-video-plan.md`. Phase 3 starts its caption from the first.
3. Run `"$SKILL/references/bake-poster.sh" marketing/launch.mp4 marketing/launch.jpg`.
4. Check the length: `ffprobe -v error -show_entries format=duration -of csv=p=0 marketing/launch.mp4` prints a value from 15 to 25 (`demo`) or 35 to 45 (`promo`).
5. Delete the `brag-output*/` folder. On any failed render, delete it too and say so; windup's marketing sweep also catches a leftover.
6. Over 25 MB, re-encode the video at `-crf 23`, then run step 3 again.
