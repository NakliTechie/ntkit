## Setting the GitHub social preview

GitHub has no API to set the repo's social preview, only to read whether one is set. Use a browser signed in to GitHub with repository settings access and a file upload tool. If the user performs the upload, give them the image path and settings URL, then run the same verification.

### 0. Check the current state

```bash
gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){usesCustomOpenGraphImage}}'
```

`false` → never set, a launch blocker. `true` only means *some* image is set; GitHub exposes no hash or timestamp. Re-upload after any re-render.

### 1. Upload: open the menu first, then attach

On `https://github.com/<owner>/<repo>/settings`, at the "Social preview" card:

1. Click the card's **Edit** button. It opens a menu (`Upload an image…` / `Remove image`).
2. With the menu open, find the hidden `type=file` input and attach the rendered card using the browser driver’s file upload action.

Never click "Upload an image…": it opens a native file picker the browser tool cannot see, and the run stalls. That menu item is a `<label>`, so `file_upload` to it fails with "Element is not a file input".

An upload before opening the menu produced an `openGraphImageUrl` that served `AccessDenied` while `usesCustomOpenGraphImage` read `true`. Keep the order and always run step 2. The control auto-saves; there is no Save button.

### 2. Confirm: hash what GitHub serves

The preview box can stay blank after a good upload, so a screenshot is not the check:

```bash
u=$(gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){openGraphImageUrl}}' --jq .data.repository.openGraphImageUrl)
curl -s -m 30 -o /tmp/og.png -w "%{http_code} %{content_type}\n" "$u"   # want: 200 image/png
shasum /tmp/og.png <local social.png>                                     # want: identical hashes
```

`AccessDenied` XML, a non-200, or a different hash → the upload did not take; repeat step 1 with the menu open. `curl -s https://github.com/<owner>/<repo> | grep 'og:image'` shows the same URL.
