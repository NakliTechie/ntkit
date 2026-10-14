# Playbook: a proof video from a live recording of the app

How to make a short launch video that shows the real app doing the real thing, with every number taken from the
recorded run. Distilled from the diskformer 80B video (2026-10-13; the author's reference run lived in
`~/Code/diskformer.js/marketing/video-80b/`, which you will not have — treat its file names below as a worked
example to adapt, not a path to open). Two cuts, 16:9 and 9:16, were briefed, recorded, edited, rendered and staged
on Reddit, LinkedIn and the README in about 1 h 45 min.

Portability note: the recorder, the CDP daemon (`~/Code/infra/bin/chrome-cdpd.mjs`), the `chrome-cdp-persistent.md`
playbook, and the external-SSD archive below are the author's own setup. The music library, `bake-poster.sh` and
`assets.md` referenced here ship with ntkit under `package-nt/references/`. Supply your own screen recorder and a
Chrome you can drive if you do not have the author's infra; the honesty rules and the step order are what carry.

Use it when the claim is "this works" and the proof is watching it work: a model answering in a browser tab, a tool
finishing a job. For an explainer with invented visuals, or a promo with no live footage, use `/package-nt`'s launch
video (brag) or `/hyperframes` instead. This playbook sits under hyperframes' `general-video` workflow and adds the
recording, the honesty rules and the distribution steps.

## The rules (non-negotiable)

1. **Real footage only.** Record the live, deployed app (or the exact build being announced), never a mock.
2. **Every number on screen comes from the recorded run.** The recorder writes `events.json` with the app's own
   readouts. No estimates, no rounding up ("80B parameters, 48 GB file", never "80 GB").
3. **Sped-up footage says so.** Every segment faster than real time carries a speed badge (`10× speed`) and a clock
   showing real elapsed time. A segment at real speed says `real speed`. One constant rate per segment.
4. **Hold on what people must read.** Give each answer or result 3-6 s at rest before cutting (Chirag's note on the
   first cut: "give a few moments for people to read the responses").
5. **The video matches the app.** Take the palette and type from the live page into `frame.md`, so footage and
   designed frames read as one piece.
6. **Each shape is recorded, not cropped.** The 9:16 cut gets its own takes in a phone viewport. Zooming a 16:9 take
   leaves the text too small on a phone.
7. **Stage, never post.** Uploads and drafts are fine; the final Post, Publish or Commit click on a public surface is
   Chirag's (the README video commit is the project's own repo, so it is ours).
8. **Sound serves the footage, never fakes it.** The music is a bed under the whole piece, kept low under every result
   hold so the numbers stay readable (rule 4); no stinger or beat-drop lands on a number or a speed badge. Narration
   says only what is true and on screen — confirm the rendered words with `npx hyperframes transcribe`, because the
   voice garbles names. The footage carries the proof; sound must not imply a result the run did not produce. Reuse a
   cleared launch-video track where you can; audio source files stay out of commits.

## Steps

### 0. Brief (10 min)
- `npx hyperframes init marketing/<video-name> --non-interactive --example=blank --skill=general-video`.
- `BRIEF.md`: one-sentence message, audience, destination, aspect, length, angle `proof`. Under Notes: the rules
  above, the exact wording of the claim, and the end card (name, URL, repo).
- `frame.md`: palette and fonts lifted from the app's CSS; the honesty markers; do and don't.
- `STORYBOARD.md`: Hook (the claim in 3 short lines) → Setup (the app, real speed) → the slow part (sped up, badge +
  clock) → Proof (the result, held) → How (one diagram) → Close (name, URL, repo). Show it; build after approval.
- **Sound (default on).** Name one music track in `BRIEF.md`, reused from the launch-video library the brag path
  ships: `package-nt/references/brag/assets/music/` (the ende.app "Happy Beats / Business Moves" tracks, with beat
  maps in `cues/<stem>.music-cues.json` and first-20-25 s planning in `<stem>.music-cues.md`). Pick by the cue preset,
  not by ear alone. Draft one narration line per scene here too. The sound is built in Step 5b. A proof video can ship
  silent — say so in the brief if that is what you want.
- `marketing/` stays gitignored (`/marketing` in `.gitignore`).
- **Mark the folder irreplaceable:** `touch marketing/<video-name>/.source`. The takes cannot be recorded again,
  so `/windup-nt`'s marketing sweep keeps any folder holding a `.source` file, cited in a plan item or not
  (`skills/windup-nt/bin/marketing.sh`). This replaces the old "name it in an open plan item" safeguard.

### 1. Make the app recordable (15 min, once per app)
The recorder waits on app state, not on sleeps. The app exposes a few globals the recorder can poll, for example
diskformer's `window.dfLoaded`, `window.dfResult` (with its `stats`) and the `#status` / meter text. Add them in the
app if missing; they are cheap and also help tests.

### 2. Stage off camera
Anything slow and dull happens before recording: downloads, imports, logins to test data. diskformer's
`record.mjs stage <file>` sets the app's own file input through CDP (`DOM.setFileInputFiles`) so the GGUF lands in the
recording profile's storage. The recording profile is a dedicated `--user-data-dir` inside the video folder.

### 3. Record takes
`record.mjs take "<question>"` (copy and adapt the reference): headless Chrome
(`--headless=new --enable-unsafe-webgpu --user-data-dir=<profile> --remote-debugging-port=<port>`), one CDP socket.
- **16:9:** `Emulation.setDeviceMetricsOverride` 1920×1080 at `deviceScaleFactor: 2`, then `Page.startScreencast`
  (JPEG q90, max 3840×2160). Ack every frame. Save each frame with its timestamp.
- **9:16:** 540×960 at `deviceScaleFactor: 2`, so the page takes its phone layout and frames come out 1080×1920. The
  screencast ignores the scale factor here, so capture with `Page.captureScreenshot` in a loop at about 10 fps
  (20 fps starved the GPU during the model load). Mobile emulation drops synthetic mouse clicks: press buttons through
  the DOM (`el.click()`, `form.requestSubmit()`).
- **Act like a person:** move to the button, click, type one character at a time (`Input.insertText`, ~45 ms apart).
- **Mark milestones** in `events.json` with the app's readouts at each: `load-click`, `loaded` (status + meter text),
  `type-start`, `send`, `first-token` (a MutationObserver on the reply), `done` (stats + reply text), `end`.
- Write `frames.json` (wall-clock t0 + frame list). One take per model or scenario; record the hero first.

### 4. Frames to a constant-rate video
Screencast frames arrive at uneven times. Resample to 30 fps by holding the latest frame, then encode:

```python
import json, bisect                     # run inside footage/take-N
d = json.load(open('frames.json')); t0 = d['t0Wall'] / 1000
fr = [(f['t'] - t0, f['f']) for f in d['frames']]; ts = [x[0] for x in fr]
end = fr[-1][0] + 0.5; fps = 30; out = []
for i in range(int(end * fps)):
    k = max(0, bisect.bisect_right(ts, i / fps) - 1)
    out.append(f"file 'frames/{fr[k][1]}'\nduration {1/fps:.6f}")
out.append(f"file 'frames/{fr[-1][1]}'")
open('concat.txt', 'w').write('\n'.join(out))
```
```bash
ffmpeg -y -f concat -safe 0 -i concat.txt -vf "fps=30,format=yuv420p" -c:v libx264 -crf 16 -preset medium -movflags +faststart ../../assets/take1.mp4
```
The same script serves both capture modes, since both store frame times as wall-clock seconds. To hold the last
frame for reading time: `-vf "tpad=stop_mode=clone:stop_duration=6"`. Check a take with a contact sheet:
`ffmpeg -i take.mp4 -vf "select='eq(n\,90)+eq(n\,1200)',scale=960:-1,tile=2x2" -frames:v 1 contact.jpg`.

### 5. Compose
- One untimed camera wrapper (`#world`, 1920×1080, page pixels = video pixels) around the footage clips; camera moves
  are GSAP tweens on the wrapper (`aim(x, y, zoom)`), never on the timed clips.
- Cut the take into segments: the same `<video>` source repeated, each with `data-start`, `data-duration`,
  `data-media-start` and one `data-playback-rate`. Times come from `events.json`.
- Overlays in screen space, each a timed `class="clip"`: speed badge per segment, a real clock (`0:42 real time`,
  counting real seconds at the segment's rate), a stats bar whose numbers are typed in from `events.json`, callouts.
- Designed frames (hook, diagram, close) as sub-compositions in `compositions/`.
- Write the numbers into the HTML by script from `events.json` rather than by hand, so a re-record updates them.
- Sound (the music bed and the narration) is added in Step 5b, after the visual segments are cut, so the narration
  can be timed to the scenes.

### 5b. Sound (default on)
A proof video ships with sound unless the brief says silent: a music bed under the whole piece and one narration line
per scene. Build it after Step 5, because each line is sized to its scene.

**Narration.**
- One line per scene, short enough to finish before the next scene starts.
- Generate each line on its own, never in a batch: `npx hyperframes tts "<line>" --voice am_michael -s 1.0 -o assets/voice/s1.wav`.
  The local Kokoro voice works when signed out of HeyGen. The batch engine (`media-use/audio/scripts/audio.mjs`) ran
  Kokoro in parallel and 4 of 6 lines failed; each worked when run alone.
- Respell names the voice garbles, then confirm the rendered words with `npx hyperframes transcribe`: `Qwen` → `Chwen`,
  `gpt-oss` → `G P T O S S`, `llama.cpp` → `llama dot C P P`. Raise `-s` up to about 1.1 to fit a line into its scene.

**Music.**
- Default: reuse a cleared track from the launch-video library (Step 0), looped to length.
- For a bespoke bed, generate one with local MusicGen through `media-use/audio/scripts/audio.mjs --only bgm`. It needs
  `transformers torch soundfile numpy` in the system Python, and `torchvision` must match `torch` or the import fails
  with `operator torchvision::nms does not exist`. It writes about 30 s; loop it to length with ffmpeg
  `acrossfade=d=4`, then fade in and out.

**Mount and mix.**
- Each sound is an `<audio id=…>` on the orchestrator (a scene never holds audio). Without an `id` the render is silent.
- Set the music bed to `data-volume` about 0.35.
- Duck the bed under the narration: run the hyperframes-audio carve, `scripts/carve.mjs --comp index.html` (skill
  `/hyperframes-audio`). A volume duck alone does not finish the mix. The carve needs `@hyperframes/core` in the project
  (`npm i -D @hyperframes/core@<cli version>`). Re-run the carve after any voice change.
- Audio source files stay out of commits (gitignored with `marketing/`).

Worked example: the width promo (the author's run, `~/Code/diskformer.js/marketing/promo-width/` — `index.html`,
`assets/voice/`, `assets/bgm/`), which you will not have; adapt its layout.

### 6. Check, preview, approve
`npx hyperframes lint` while building, `npx hyperframes check` at the end. Snapshot sheet at each beat:
`npx hyperframes snapshot --at 2.6,6.9,... --no-end --describe false -o .hyperframes/snap` then tile with ffmpeg and
read it. Open `npx hyperframes preview` (Studio) for Chirag, and render only after his yes.

### 7. Render both shapes
- 16:9: `npx hyperframes render -o renders/<name>-16x9.mp4 --fps 30 --quality delivery`.
- 9:16: generate `vertical.html` from `index.html` with a script (viewport, overlay positions, camera aims, `v`-prefixed
  sub-compositions, the 9:16 takes), render with `-c vertical.html`, then delete `vertical.html` (two root files fail
  `check`). Reference: `make-vertical.py`.
- Verify each render: `ffprobe` for size, fps, duration and an audio stream (sound is the default,
  `ffprobe -v error -show_entries stream=codec_type -of csv=p=0`), plus a frame sheet compared against `events.json`.
  Confirm the 9:16 render carries sound too, not only the 16:9 — the vertical generator must copy every `<audio>`, the
  bed and each narration line.
- Thumbnail: bake the strongest settled frame into frame 0 (`package-nt/references/bake-poster.sh <mp4> <seconds>`),
  because X, LinkedIn and Slack show frame 0. Optional stranger test as in `package-nt/references/assets.md`.

### 8. Distribute (stage only)
- **README video (GitHub):** upload the mp4 through the repo's own README web editor (Edit file, attach the file
  into the editor), so GitHub finalizes it as a `user-attachments/assets/<id>` link. An upload into an issue or
  comment draft that is never submitted is never published, and the link stays dead. Check
  `curl -sL -o /dev/null -w "%{http_code} %{content_type} %{size_download}"` returns `200 video/mp4` at the file's
  exact byte count. Put the link on its own line under the heading. Watch the editor: the upload inserts text, so
  replace the editor content with the committed README plus the new link, then pull and diff afterwards.
- **Reddit:** through the CDP daemon (`~/Code/infra/bin/chrome-cdpd.mjs`, playbook `chrome-cdp-persistent.md`),
  since Claude-in-Chrome refuses reddit.com. A video in the body makes it a media post. Lead with the result, not the
  project (repeat self-promotion is frowned on in r/LocalLLaMA). Stop before Post. Kill the daemon after.
- **LinkedIn / X:** Claude-in-Chrome, upload the 16:9 (LinkedIn) or the 9:16 (Shorts, Reels), fill the text from
  `plan/launch-drafts.md`, pick a thumbnail in the video settings, stop before Post.
- Captions and text live in `plan/launch-drafts.md` (gitignored).

### 9. Clean up and keep the source
- Delete the recording profile by name once both shapes are final; it holds full model copies (54 GB for three
  models in the reference run). Report it with its size.
- Keep the project folder and `assets/` takes: the takes cannot be recorded again identically. The `.source` marker
  from Step 0 keeps the folder through `/windup-nt`'s marketing sweep, cited in a plan item or not. After posting, move
  the folder to an archive on the external SSD (for example `/Volumes/Models2/videos/<project>-<video-name>/`) to free
  the working disk; the marker travels with it.
- Delete `footage/take-*/frames/` (thousands of JPEGs) once the mp4 takes are verified.

## Gotchas met so far
- A recorder that sleeps instead of waiting on app state cuts mid-answer; poll the app's globals with a timeout.
- Put any scroll or camera move after a milestone mark, or the on-screen clock runs long by the scroll time.
- A regex edit to the composition that matches 0 times fails silently; assert a match count in every scripted edit.
- `hyperframes check` fails with two root HTML files present (`vertical.html` beside `index.html`).
- The first frame of a hook is near-empty; bake a poster into frame 0 or the post shows a blank thumbnail.
- Headless Chrome's GPU is shared with the app: a 20 fps screenshot loop slowed an 80B model load. Record the heavy
  step at a lower capture rate, or nothing else on the GPU.
- Big recordings need disk: check `df -h /` before recording; the profile copy of each model counts.
