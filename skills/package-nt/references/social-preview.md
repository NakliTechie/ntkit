## Setting the GitHub social preview (no API exists — drive the browser)

This file covers the **repo's** card only — uploading the image to GitHub. For **building**
the image itself (repo or app), or for the deployed app's own meta tags, see
[`social-card-build.md`](social-card-build.md) first.

GitHub exposes no API to *set* the social preview image, only to read whether one is set
(`usesCustomOpenGraphImage`). The steps below are exact — they came from actually doing this
on `NakliTechie/ntkit` and `NakliTechie/scholia`, not from GitHub's docs; the gotcha in step 2
cost a broken card the second time.

### 0. Check current state and regenerate the asset

```bash
gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){usesCustomOpenGraphImage}}'
```

`false` → never set; a launch blocker regardless of what follows. `true` only means *some*
image is set — it does not mean the *current* one is up to date, and there is no hash or
timestamp exposed to check staleness. **Always re-upload after regenerating the asset**;
never rely on `true` to mean "already current." Run the project's own render script first
(e.g. `assets/render-social.sh` in ntkit) so the file on disk is the one you're about to
upload, at 1280×640 (or ≥640×320 — GitHub accepts down to that, but renders soft below it).

### 1. Drive the browser to the setting

Use the **Claude-in-Chrome** extension, not the built-in browser pane — this needs the
user's real logged-in GitHub session, and only Claude-in-Chrome can attach a local file to
a page's file input.

```
navigate → https://github.com/<owner>/<repo>/settings
find → "Social preview" heading
scroll_to that heading's ref
```

### 2. Upload — open the menu first, then attach (never click the picker)

1. Click the **"Edit"** button on the current preview card. It opens a small dropdown (`Upload an image…` / `Remove image`) — an ordinary menu, safe to click.
2. With the menu open, find the **hidden file input** itself, not its label:

```
find → "input element with type=file (hidden) for the social preview image"
file_upload → { ref: <that ref>, tabId, paths: ["<absolute path to the rendered social.png>"] }
```

**Do not click "Upload an image…".** It triggers a native OS file picker the browser tool cannot see, and the run stalls. The menu item itself is a `<label>`; `file_upload` to it fails with "Element is not a file input" — target the `type=file` input the query above resolves to.

**Gotcha (2026-09-24, `NakliTechie/scholia`):** a `file_upload` to the input *before* opening the Edit menu registered a new `openGraphImageUrl` that served `AccessDenied` — `usesCustomOpenGraphImage` read `true` while every share would have shown a broken card. Opening the menu first, then uploading, produced a working image on scholia and again on ntkit (one run each; the cause is not confirmed, so keep the order and always run the step-3 check). The control auto-saves; there is no Save button.

### 3. Confirm it actually saved — hash what GitHub serves

The settings page's preview box can stay **blank even after a successful upload** (seen in dark mode on scholia, 2026-09-24), so a screenshot is not the check. Compare bytes:

```bash
u=$(gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){openGraphImageUrl}}' --jq .data.repository.openGraphImageUrl)
curl -s -m 30 -o /tmp/og.png -w "%{http_code} %{content_type}\n" "$u"   # want: 200 image/png
shasum /tmp/og.png <local social.png>                                     # want: identical hashes
```

`AccessDenied` XML, a non-200, or a different hash → the upload did not take; repeat step 2 with the menu open. Also check the live page points at it: `curl -s https://github.com/<owner>/<repo> | grep 'og:image'` shows the same URL.

Close the tab when done (`tabs_close_mcp`) — it was opened for this task alone.
