## The launch video (Phase 2)

A 15–25 second video of the product in use, with a soundtrack and a caption. The
skill that makes it is `/brag-slim` from [latent-spaces/brag](https://github.com/latent-spaces/brag)
(MIT): one markdown file, no bundled assets, the model builds and renders the video
with the tools on the machine. `/package-nt` assembles the direction and takes the
output. `/brag-slim` owns the story, visuals, audio and render.

### Preconditions: check first; a miss skips the video, it never blocks the run

- **The skill is installed** at `~/.claude/skills/brag-slim/SKILL.md` or
  `.claude/skills/brag-slim/SKILL.md`. Missing → skip, and list this install line under
  nice-to-haves. It is pinned to the upstream commit this kit was checked against; read
  a newer one before you move the pin.
  ```bash
  mkdir -p ~/.claude/skills/brag-slim && curl -fsSL https://raw.githubusercontent.com/latent-spaces/brag/c893c5ed52aed84e3e2ee56787de869fccdae6b0/skills/brag-slim/SKILL.md -o ~/.claude/skills/brag-slim/SKILL.md
  ```
- **`ffmpeg -version` exits 0.** Check that it starts, not that it exists: a Homebrew
  upgrade of one of its libraries leaves the binary on `PATH` and unable to load
  (`Library not loaded: …libx265…`). The fix is `brew upgrade ffmpeg`.
- **There is a surface to show**: a browser app, or a CLI whose transcripts show it
  working. A library with no surface → skip, and say so.

### The direction: build all of it before invoking

`/brag-slim` takes plain language. Hand it one brief with every item below; do not
invoke it and then feed the direction piece by piece.

- **Input**: the project directory, which is brag-slim's "Project" input. Use the
  deployed URL instead only when the repo cannot be served locally.
- **Tone** from the house shape the Unity sentence names (`~/.claude/reference/naklitechie-doctrines/DIRECTIONS.md`):

  | Shape | brag-slim tone |
  |---|---|
  | Calm | `polished` |
  | Dense | `app-store` |
  | Mono | `deadpan` |

  No Unity sentence → `polished`. Use the loud presets (`chaotic`, `yc-parody`,
  `cinematic`) only when the user asks for one.
- **Storyboard beats**: when the `/guide-nt` generator (`guide/capture.*`, or
  `demo/capture.*` on the Bahi layout) defines `HERO_FLOW`, pass those captures in
  that order as the entry → key action → result beats, with each route's target (URL
  or command). Without `HERO_FLOW`, derive the flow from the README's "how it works"
  and the main route, and say so in the summary.
- **Data**: the shared demo seed (`demo/seed/`) when it exists, so the screens show
  a product in use, not an empty first run. Never real user data.
- **Claims**: only what the README and the gate findings support. No invented
  numbers, users, or testimonials. brag-slim has the same rule; restate it anyway.
- **Audience**: who it is for, said on screen in the first 10 seconds, in the README's
  words. When the README never names an audience, derive one from what the product
  does and its "use something else if" line, and say so in the summary. brag-slim
  asks itself who the product is for but does not have to show it. A video that
  leaves the audience out fails the stranger test on *who*.
- **Last beat**: the name and how to get it: the deployed URL when there is one, else
  the repo URL and the install line. The video has to pass the stranger test with no
  post text around it.
- **Format**: landscape, 1920×1080. Vertical or square only when asked.

### Take the output

brag-slim writes `brag-output/` (or `brag-output-<timestamp>/` when that exists) in
the project root, with its intermediates in `work/` inside it.

1. Copy `brag.mp4` → `marketing/launch.mp4` and `brag.jpg` → `marketing/launch.jpg`.
2. Copy `share-copy.txt` → `plan/launch-caption.txt` and `brag-plan.md` →
   `plan/launch-video-plan.md`. Both are working material, so they stay in the
   gitignored `plan/`. Phase 3 starts its caption from the first.
3. Run `references/bake-poster.sh marketing/launch.mp4 marketing/launch.jpg`.
   brag-slim bakes its own poster; this run proves it, and fails if the size, frame
   count, duration or frame 0 is off.
4. Check the length: `ffprobe -v error -show_entries format=duration -of csv=p=0 marketing/launch.mp4`
   prints a value from 15 to 25.
5. Delete the `brag-output*/` folder. This run generated it, its `work/` holds frames
   and audio stems, and none of it belongs in a commit.
6. The video is a committed asset. Over 25 MB, re-encode it at `-crf 23` before the
   commit, then run step 3 again.
