## The launch video (Phase 2)

A short video with a soundtrack and a caption, in one of two modes (below). It is made
by brag, vendored in [`brag/`](brag/VENDORED.md) at commit `c893c5e`, so a fresh ntkit install needs no other
skill. `/package-nt` assembles the direction and takes the output. brag owns the story,
visuals, audio and render.

### Pick the mode: who watches it

| Mode | For | Length | Shape |
|---|---|---|---|
| `demo` (default) | People who will use or install it | 15–25 s | The product in use: entry → key action → result, then how to get it |
| `promo` | Leadership and non-technical viewers | 35–45 s | One big headline per thing it lets you do, over moving screens, ending on the name |

Use `promo` when the user asks for a promo, or names a leadership, executive or
non-technical audience. Otherwise use `demo`. Say in the summary which mode ran and why.
A demo shown to leadership reads as thin. A promo shown to builders leaves out what they
need to try it.

### Pick the path: which brag runs

Follow upstream's own dispatch:

| When | Path | Read and follow |
|---|---|---|
| You are Claude Opus 5.5, and the user did not ask for the full workflow or a voiceover | brag-slim: one file; the model builds and renders the whole video with the tools on the machine | `brag/slim.md` |
| Any other model, you cannot tell which model you are, or the user asked for the full workflow or a voiceover | full brag: the story and brief here, Hyperframes builds and renders | `brag/brag.md` |

Read the file and follow it for the rest of this step, with the direction below as the
user's input. There is no installed skill to call, so do not use the Skill tool for it.
Read `<skill-dir>` in either file as `references/brag/`. Say in the summary which path ran.

### Preconditions: check first; a miss skips the video, it never blocks the run

- **`ffmpeg -version` exits 0.** Check that it starts, not that it exists: a Homebrew
  upgrade of one of its libraries leaves the binary on `PATH` and unable to load
  (`Library not loaded: …libx265…`). The fix is `brew upgrade ffmpeg`.
- **There is a surface to show**: a browser app, or a CLI whose transcripts show it
  working. A library with no surface → skip, and say so.
- **Full path only**: `node --version` is 22 or later, `npx hyperframes doctor` passes,
  and the Hyperframes companion skills are installed (`npx hyperframes skills`). Both
  come from npm, so offline or refused → skip the video with the reason. The brag-slim
  path needs none of this.
- **Full path music**: the ende.app tracks are not vendored (license; see
  `brag/VENDORED.md`). brag then runs without music, or with a track the user supplies;
  the SFX ship. Tracks a user downloads into `brag/assets/music/` stay out of commits.

### The direction: build all of it before invoking

Both paths take plain language. Hand brag one brief with every item below; do not
invoke it and then feed the direction piece by piece.

- **Input**: the project directory, brag's "Project" input. Use the
  deployed URL instead only when the repo cannot be served locally.
- **Tone** from the house shape the Unity sentence names (`~/.claude/reference/naklitechie-doctrines/DIRECTIONS.md`):

  | Shape | brag tone |
  |---|---|
  | Calm | `polished` |
  | Dense | `app-store` |
  | Mono | `deadpan` |

  No Unity sentence → `polished`. Use the loud presets (`chaotic`, `yc-parody`,
  `cinematic`) only when the user asks for one.
- **Storyboard beats, `demo`**: when the `/guide-nt` generator (`guide/capture.*`, or
  `demo/capture.*` on the Bahi layout) defines `HERO_FLOW`, pass those captures in
  that order as the entry → key action → result beats, with each route's target (URL
  or command). Without `HERO_FLOW`, derive the flow from the README's "how it works"
  and the main route, and say so in the summary.
- **Storyboard beats, `promo`**: one beat per key feature the product has today, from
  the README and the feature list. Each beat is a headline of a few words that says what
  the viewer gets from it, how it helps them ("Reach the journalists who matter.",
  "Answer their questions.", "Wake up to the day, by 7 am."),
  held 3–4 s, over a screen that moves: crop, zoom, pan, or a desktop screen paired
  with a phone screen. Open with who it is for; add no supporting line unless it earns
  its place.
- **What, not how or who (`promo`)**: show what the product lets the viewer do, never
  how it is done or who does it. Leave out approvals and sign-off, verification
  methods, owners, deadlines, statuses, roles and security mechanics. Crop or mask
  that part of a screen; never edit the text inside one.
- **No technical artefacts (`promo`)**: no URL, repo, install line, command, code,
  version string or hash, file name, stack name, or jargon (API, passkey, token,
  database) in any line or on any screen. Crop address bars and version lines out of
  screens.
- **Data**: the shared demo seed (`demo/seed/`) when it exists, so the screens show
  a product in use, not an empty first run. Never real user data.
- **Claims**: only what the README and the gate findings support. No invented
  numbers, users, or testimonials. brag has the same rule; restate it anyway.
- **Audience**: who it is for, said on screen in the first 10 seconds, in the README's
  words. When the README never names an audience, derive one from what the product
  does and its "use something else if" line, and say so in the summary. brag asks
  itself who the product is for but does not have to show it. A video that
  leaves the audience out fails the stranger test on *who*. When the user names the
  owner differently (a person rather than an office, say), use their words.
- **Sample-data label**: when screens show fictional sample content and a real person
  or organisation is named on screen, every frame with a screen carries a small,
  readable "Sample data" label. Otherwise fictional statements beside a real name read
  as real ones.
- **Last beat, `demo`**: the name and how to get it: the deployed URL when there is
  one, else the repo URL and the install line. The video has to pass the stranger test
  with no post text around it.
- **Last beat, `promo`**: the name alone. No URL, repo or install line; the caption
  and the post carry the link.
- **Format**: landscape, 1920×1080. Vertical or square only when asked.
- **Full path, no waiting**: brag's step 4 starts a preview and asks before it renders.
  Render straight away unless the user is present and asked to review;
  `/package-nt` checks the result itself (step 3 below, then the stranger test). For
  `promo`, pass `--duration 40`.

### Take the output

Both paths write `brag-output/` (or `brag-output-<timestamp>/` when that exists) in the
project root: brag-slim keeps its intermediates in `work/`, full brag in `composition/`.

1. Copy `brag.mp4` → `marketing/launch.mp4` and `brag.jpg` → `marketing/launch.jpg`.
2. Copy `share-copy.txt` → `plan/launch-caption.txt` and `brag-plan.md` →
   `plan/launch-video-plan.md`. Both are working material, so they stay in the
   gitignored `plan/`. Phase 3 starts its caption from the first.
3. Run `references/bake-poster.sh marketing/launch.mp4 marketing/launch.jpg`.
   Both paths bake their own poster; this run proves it, and fails if the size, frame
   count, duration or frame 0 is off.
4. Check the length: `ffprobe -v error -show_entries format=duration -of csv=p=0 marketing/launch.mp4`
   prints a value from 15 to 25 (`demo`) or 35 to 45 (`promo`).
5. Delete the `brag-output*/` folder. This run generated it, its `work/` holds frames
   and audio stems, and none of it belongs in a commit.
6. The video is a committed asset. Over 25 MB, re-encode it at `-crf 23` before the
   commit, then run step 3 again.
