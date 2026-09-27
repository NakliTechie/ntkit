# Vendored: latent-spaces/brag

Upstream: https://github.com/latent-spaces/brag (MIT, © 2026 Shunit Haviv Hakimi; see `LICENSE`).
Commit: `c893c5ed52aed84e3e2ee56787de869fccdae6b0` (2026-09-24), upstream `skills/brag/`.

`/package-nt` reads these files to make the launch video, so a fresh ntkit install needs
no separate skill. They are copies, not edits: `VENDORED.sha256` holds a hash for every file,
and `tests/brag-vendor.test.sh` fails if one changes.

| Here | Upstream |
|---|---|
| `brag.md` | `skills/brag/SKILL.md`, renamed so no skill loader registers it as a command |
| `slim.md` | `skills/brag/slim.md`, byte-identical to `skills/brag-slim/SKILL.md` (upstream enforces this) |
| `references/`, `scripts/`, `assets/sfx/`, `assets/music/README.md`, `assets/music/cues/` | the same paths under `skills/brag/` |
| `LICENSE` | the repo root `LICENSE` |

Read `<skill-dir>` in `brag.md` and `slim.md` as this folder.

**Left out: the five music tracks** (`assets/music/*.mp3`, 13 MB). They come from ende.app
"Happy Beats / Business Moves". Its standard license (checked 2026-09-27) forbids redistributing
the audio files as-is to other libraries or repositories, and upstream's own music README says to
verify the terms before redistributing. The cue presets stay. The full path runs without music,
per `references/audio.md` ("the required assets are missing"), or with a track you supply. To get
the bundled music back on your machine, download the tracks from ende.app into `assets/music/`;
the `.gitignore` there keeps them out of commits. The SFX are Kenney, CC0, and ship as-is.

**Updating.** Copy upstream `skills/brag/` at the new commit over this folder with the same
mapping and exclusion, read the diff, then regenerate the hashes:
`find . -type f ! -name 'VENDORED*' ! -path './assets/music/.gitignore' | sed 's#^\./##' | sort | xargs shasum -a 256 > VENDORED.sha256`
and update the commit above.
