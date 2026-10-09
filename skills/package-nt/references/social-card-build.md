## Building the social card

One template, two cards: the repo's and the deployed app's.

```bash
"$SKILL/references/render-social-card.sh" \
  --name "<ProductName>" \
  --tagline "<one sentence, the same pitch as the README's bold line>" \
  --facts '<b>the one fact worth bolding</b> &nbsp;&#183;&nbsp; clause two &nbsp;&#183;&nbsp; clause three' \
  --accent "<#hex, the project's own accent token>" \
  [--accent-text "<#hex, only when the contrast gate asks for one>"] \
  --out <path>
```

- `--facts` is literal HTML, not markdown: bold the one phrase yourself.
- `--accent` defaults to ntkit's own `#0891b2`. Always pass the project's own token (a `colors.ts`, a CSS custom property).
- On a contrast miss the script exits 1 and prints the nearest passing shade. Pass that shade as `--accent-text`, and keep the bright accent on the bar with `--accent`.

Run it once per surface, same params except `--out`:
- Repo: `--out marketing/social.png`, or the repo's existing card path (ntkit uses `assets/social.png`); do not add a second folder.
- App: `--out marketing/social-app.png`.

### The app's card and tags: a finding, not an edit

You never edit the app's `<head>` or its static assets. When the deployed page lacks the card, the gate's blocker gives the user the exact change:
- render the card with the command above (absolute script path), `--out` the app's static-asset root as `social.png` (check what the deployed origin serves at `/`);
- add to the page's `<head>`, with absolute URLs: `og:title` and `og:description` (the README's one-sentence pitch), `og:image` and `twitter:image` (`https://<deployed-host>/social.png`), `og:url` (the canonical deployed URL), `og:type` = `website`, `twitter:card` = `summary_large_image`;
- after the deploy, check the live host, not localhost: `curl -s https://<deployed-host>/ | grep -i 'og:\|twitter:'`, and `curl -s -o /dev/null -w '%{http_code} %{content_type}\n' https://<deployed-host>/social.png` prints `200 image/png`.
