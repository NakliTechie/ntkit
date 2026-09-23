## Setting the GitHub social preview (no API exists — drive the browser)

GitHub exposes no API to *set* the social preview image, only to read whether one is set
(`usesCustomOpenGraphImage`). The steps below are exact — they came from actually doing this
on `NakliTechie/ntkit`, not from GitHub's docs, and the one gotcha in them (below) cost a
retry the first time.

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

### 2. Upload — the gotcha

The visible control is an **"Edit"** button on the current preview card. Clicking it opens
a small dropdown (`Upload an image…` / `Remove image`) — safe to click, it's an ordinary
menu, not a file dialog.

**Do not click "Upload an image…".** That item *is* a native file-input trigger — clicking
it opens an OS file picker the browser tool cannot see or interact with, and the run stalls
there. Instead:

```
find → "file input for social preview image upload" (resolves to the "Upload an image…" control)
file_upload → { ref: <that ref>, tabId, paths: ["<absolute path to the rendered social.png>"] }
```

`file_upload` attaches the file directly to the input without opening a picker at all.

### 3. Confirm it actually saved

This control **auto-saves on upload** — there is no separate "Save" button for it (unlike
most of the rest of the Settings page). Confirm two ways, not one:

1. Screenshot immediately after the upload — the preview card should already show the new
   image's content.
2. **Reload the settings page from scratch** (`navigate` to the same URL again) and
   screenshot the Social preview card again. A change that only shows before a reload might
   be an optimistic UI update that didn't actually persist — the reload is the real check.

Close the tab when done (`tabs_close_mcp`) — it was opened for this task alone.

### 4. Re-run the API check

`usesCustomOpenGraphImage` should read `true` (it was likely already `true` from a prior
upload — see the staleness note in step 0, which is why the visual reload-check in step 3
is the check that actually matters here, not this API call by itself).
