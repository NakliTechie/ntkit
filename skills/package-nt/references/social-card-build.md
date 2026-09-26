## Building the social card (both surfaces, one template)

Every launch needs two cards — the repo's and the deployed app's own (see
README-DOCTRINE's "The social card — two surfaces, not one"). Build both from
the same template so they look like the same product, and so nobody hand-codes
an HTML card from scratch per project — that's how the two existing ones
(ntkit's own, and NakliData's) got built before this file existed, and it's
not worth repeating a third time.

### When to reach for the template vs. a real screenshot

The doctrine's default is **text-led** — name, one-sentence pitch, a facts
line — not a screenshot. Use the template (below) unless the project already
has a genuinely good screenshot from `/guide-nt` or a Playwright capture *and*
a designer's eye went into framing it. A stretched, cropped, or dev-chrome-
visible screenshot is worse than clean type; when in doubt, use the template.

### Build it

```bash
skills/package-nt/references/render-social-card.sh \
  --name "<ProductName>" \
  --tagline "<one sentence, the same pitch as the README's bold line>" \
  --facts '<b>the one fact worth bolding</b> &nbsp;&#183;&nbsp; clause two &nbsp;&#183;&nbsp; clause three' \
  --accent "<#hex — the project's own brand/accent token, not a generic color>" \
  [--accent-text "<#hex — a darker shade of the accent, only if the gate asks for one>"] \
  --out <path>
```

**Contrast gate.** Before it renders, the script checks every text colour in the
template's `:root` against the background and exits 1 when one is under 4.5:1
(WCAG AA; the facts line is 16px, so the large-text 3:1 floor does not apply).
The message names the colour, its ratio, and the nearest passing shade. The
usual miss is a bright brand accent used as text: keep it on the bar with
`--accent`, and pass the suggested shade as `--accent-text`. There is no
override flag. A card that fails AA at full size is unreadable as a thumbnail.

Run it **twice**, once per surface, same params except `--out`:
- Repo: `--out marketing/social.png` (or wherever this repo already keeps its
  assets — ntkit uses `assets/social.png`; match the existing convention
  rather than introducing a second folder).
- App: `--out public/social.png` (or the project's actual static-asset root —
  check what already ships at the deployed origin's `/`).

`--facts` is literal HTML, not markdown — write `<b>...</b>` around the one
phrase worth emphasizing yourself, and use `&nbsp;&#183;&nbsp;` between
clauses (a plain `·` character renders fine too; the entity is only needed if
you're passing the string through something that mangles UTF-8). Pull
`--accent` from the project's own token file (a `colors.ts`, a CSS custom
property) — never the generic `#0891b2` above; that's ntkit's own color, not
a default for other projects.

### Wire the app's copy into the deployed page

The render only produces the image. The deployed page still needs the meta
tags in its own `<head>`, absolute URLs (crawlers don't resolve relative
ones):

```html
<meta property="og:title" content="<Name> — <one-line pitch>" />
<meta property="og:description" content="<same or a slightly longer pitch>" />
<meta property="og:image" content="https://<deployed-host>/social.png" />
<meta property="og:url" content="https://<deployed-host>/" />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="<Name> — <one-line pitch>" />
<meta name="twitter:description" content="<same or a slightly longer pitch>" />
<meta name="twitter:image" content="https://<deployed-host>/social.png" />
```

Rebuild, run the project's own verification gates (never skip them for "just
meta tags" — a bundle-size gate or a smoke test can still catch a build step
that silently drops the new `<head>` content), deploy, then verify against the
**live** URL, not localhost:

```bash
curl -s https://<deployed-host>/ | grep -i 'og:\|twitter:'
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' https://<deployed-host>/social.png
```

### If the project isn't a git repo you can push from here

Some surfaces (an unfamiliar codebase, a branch mid-flight with someone else's
work-in-progress) shouldn't get this change committed onto whatever branch
happens to be checked out. Use a throwaway worktree of the branch that
actually deploys (usually `main`) instead of disturbing the working branch:

```bash
git worktree add /tmp/<project>-main-wt main
# apply the index.html/head edit + copy the rendered image into the worktree
# run the project's build + check + test gates there
# commit + push from the worktree
git worktree remove /tmp/<project>-main-wt --force
```
