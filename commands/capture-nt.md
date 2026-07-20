---
description: "Capture a URL / file / PDF into your knowledge vault (~/Code/knowledge) — fetch + extract (full text, OCR scanned PDFs), follow & summarise embedded links (esp. listicles), write a schema'd source note in sources/, tag its realm (knowledge|personal|work), link it into the right topics/ MOC with backlinks, and optionally promote a distilled insight to notes/, then commit + push automatically. Idempotent on re-run."
argument-hint: "<url | file path>  [realm: knowledge|personal|work]"
entry: "knowledge vault present at the configured path"
exit: "schema'd source note written, linked, committed + pushed; idempotent on re-run"
writes: "the knowledge vault"
---

Capture something into the **knowledge vault** and wire it into the web of notes. Turns a raw link / file into a schema'd **source note** (what _they_ said), linked into the right **topic MOC**, with an optional **evergreen note** (what _you_ concluded) promoted on top.

**Vault location:** `~/Code/knowledge` — call it `$VAULT` below. (Edit this line if you move the vault.) Its conventions live in `$VAULT/README.md` and `$VAULT/CAPTURE.md`; this command implements that flow.

## Step 1 — Resolve the input
`$ARGUMENTS` is a **URL** or a **file path** (optionally followed by a realm word — see Step 5). If empty, ask _"What am I capturing — a URL or a file path?"_ and use the next message. Classify:
- starts with `http(s)://` → **URL**
- otherwise → **file path** (expand `~`; confirm it exists). It may already live **inside** the vault — a PDF / doc dropped into `$VAULT/inbox/` or `$VAULT/assets/`. That's fine; capture it in place.

If `$VAULT` doesn't exist, stop and say so — this command captures _into_ an existing vault, it doesn't create one.

## Step 2 — Idempotency check (before fetching)
Don't duplicate. Search existing source notes for this input:
```bash
rg -l -F "<the url or filename>" "$VAULT/sources/" 2>/dev/null
```
Also try a normalized URL (strip `utm_*`, fragments, trailing slash). If a matching note exists → this is an **update**: read it and refresh in place (keep its filename, `captured` date, `domain`, and any hand-written synthesis). If none → it's a **new** capture.

## Step 3 — Fetch / extract
Pick the tool by source type — the goal is the readable text + key media, not raw HTML:

| Input | Tool |
|-------|------|
| Open web page / article | **WebFetch** |
| Login-gated (x.com, paywalled, LinkedIn, …) | **Chrome MCP** (`mcp__Claude_in_Chrome__*`) — drives the user's logged-in browser: navigate, then `get_page_text` / `read_page` |
| PDF (link or local file) | the **`pdf`** skill — extract the **full text**; if it's a **scanned / image PDF** (no text layer), **OCR it** so it's searchable. Capture tables + figure captions where present. |
| `.docx` / Word (link or local file) | the **`docx`** skill — full text + structure (headings, tables) |
| Video (YouTube, …) | fetch the page for title + description, plus transcript if present; else summarize from what's available and note the gap |
| GitHub repo | `gh repo view <owner>/<repo>` for stars / desc / license; WebFetch the README for detail |

**Extract completely.** The goal is the _whole_ readable text, not an abstract or first page — so the note (and any future full-text search) sees everything. For a long PDF / doc, also **save the extracted (OCR'd) text to `$VAULT/assets/<slug>.txt`** alongside the binary, so the full text is grep-able, not just your summary.

If a fetch fails (login wall, JS-only page), fall back to the Chrome MCP before giving up. If even that fails, capture a **stub** (`status: inbox`) with the URL and what you know — and say so. Never fabricate content.

## Step 4 — Follow & summarise embedded links (esp. listicles)
Many captures are **pointers, not destinations** — a listicle ("10 repos that…"), a link roundup, a resource thread, or an article (or **PDF / doc**) whose argument rests on a few cited links. The value is the **followed** content, not the framing. Follow links found in **any** captured content — web page, PDF, or doc — not just web articles. After the main extract:

- **Detect the shape.** Is this a **listicle / link-roundup** (its substance _is_ the list of links) or an **article that merely cites a few**?
- **Listicle → follow every item** (one hop, no recursion). For each, fetch it and record a **verified one-line summary** that replaces the author's framing with first-hand facts:
  - **GitHub repo:** `gh repo view <o>/<r> --json nameWithOwner,stargazerCount,description` + `gh api repos/<o>/<r> --jq '.license.spdx_id'`. Record real **stars + license + one-liner** — listicle star counts are routinely rounded or stale.
  - **Open page / article:** WebFetch → one-line gist.
  - **PDF / doc:** the `pdf` / `docx` skill → one-line gist.
  - **Login-gated:** Chrome MCP, or skip and mark `(not followed — gated)`.
- **Article citing links → follow only the load-bearing ones** (the 1–3 the argument depends on), not every nav link.
- **Repo or paper → _full-capture_ it, don't just summarise.** Whenever captured content — a **tweet**, article, PDF, or doc — points at a **GitHub repo** or an **arXiv / academic paper**, that target is a destination, not a footnote. Fetch it in **full** and give it **its own indexed source note** in `sources/`, then `[[wikilink]]` the capturing note to it — so the vault is full-text-searchable on the repo/paper itself, not just a one-liner about it.
  - **Repo:** `gh repo view` for stars/license **+** the full README (key files, usage, claims). New note `source_type: repo`.
  - **arXiv / paper:** run the **`pdf` skill** on the PDF (`arxiv.org/pdf/<id>`) for the **full text**; save the extract to `assets/<slug>.txt`. New note `source_type: pdf` (abstract + claims + numbers + figure captions).
  - Still respect the **~15-link bound**: if one source cites more repos/papers than that, full-capture the load-bearing ones and **`log` the deferred rest** (one-line those) — never silently drop. The one-line summary is the *floor* for incidental listicle items; a repo or paper that the content actually rests on gets the *full treatment*.
- **Bound it.** Cap at ~15 followed links; beyond that, follow the most important and **`log` what you skipped** — never silently truncate. Dedupe; skip chrome (login / share / home links).
- **Flag discrepancies.** When a followed fact contradicts the source, record both: _"claimed 51K → verified 69K (at capture)"_.

The followed summaries become part of `## Key claims & data` (e.g. one enriched bullet per listicle item).

## Step 5 — Derive metadata
- **slug** — kebab-case from the title (drop stopwords; short and recognizable; avoid a leading number right after the date prefix).
- **date prefix** — the source's **publish date** (`YYYY-MM-DD`) if discoverable, else today. Filename: `sources/<date>-<slug>.md`.
- **source_type** — `article|tweet|pdf|video|repo|doc`, inferred (x.com `/status/` → `tweet`; `/i/article/` → `article`; `.pdf` → `pdf`; `github.com` → `repo`; `.docx` → `doc`).
- **domain** — which **realm** this belongs to: **`knowledge`** (general learning — the default), **`personal`** (your own life: health, money, home, family), or **`work`** (a job / client / employer). If the user named a realm in the invocation, use it; else infer from the content. Set it when it's clearly personal or work; default `knowledge` when unsure — and if the content looks **sensitive** (a statement, a contract, medical), ask before filing. (Absent ⇒ `knowledge`.)
- **tags** — reuse existing tags first:
  ```bash
  rg -ohI 'tags: \[.*\]' "$VAULT"/{sources,notes,topics} | tr ',[]' '\n' | sed 's/tags://; s/ //g' | sort | uniq -c | sort -rn
  ```
  Coin a new tag only when nothing fits.
- **author**, **published** — from the page metadata when present.

## Step 6 — Write the source note
Write (or rewrite, if updating) `sources/<date>-<slug>.md` using the vault's source schema:
```yaml
---
title:
url:
author:
source_type: article|tweet|pdf|video|repo|doc
captured: <today>
published:
domain: knowledge        # knowledge | personal | work
tags: []
status: processed        # 'inbox' if it's only a stub
rating:
---
```
Then the body, in order — **record what the source said, not your opinion of it:**
- `## TL;DR` — ≤3 lines.
- `## Key claims & data` — bullets; preserve concrete numbers; fold in the **followed-link summaries** from Step 4.
- `## Quotes` — short, verbatim, attributed. If you couldn't get the full text, say so here rather than inventing quotes.
- `## Why it matters / connections` — `[[wikilinks]]` to related notes / sources / topics.
- `## Open questions`.
- Raw link(s) at the bottom.

For a **dropped PDF / doc / image**, keep the file under `$VAULT/assets/` and point the note at it with a relative link (`[paper.pdf](../assets/paper.pdf)`); the note carries the TL;DR + claims, so the vault stays searchable without opening the binary.

## Step 7 — Link it into the graph
- Pick the right **topic MOC(s)** in `$VAULT/topics/`. Reuse an existing one (`ls "$VAULT/topics/"`); create `topics/<theme>.md` only if the theme is genuinely new (MOC frontmatter: `title`, `type: moc`, `tags`, `updated`). Add a **one-line annotated link** to the new source under the MOC's `## Sources`.
- Make sure the source's _"Why it matters / connections"_ section links back (`[[...]]`) to those topics and any related notes — backlinks are just `rg "\[\[<slug>\]\]"`.
- Bump the MOC's `updated:` date.

## Step 8 — Optional: promote a synthesis
If the source genuinely shifts the user's thinking, or combines with existing notes into a reusable insight, offer to write an **evergreen note** in `notes/` — in the _user's_ voice, `status: evergreen`, same `domain`, linking down to the source(s). Don't force it: most captures are just sources. Ask before creating, unless the user already said to.

## Step 9 — Commit & push (automatic)
Capture isn't done until it's saved. Stage exactly what this capture wrote — the source note, any new / updated topic MOC, a promoted note, any saved `assets/` file — then commit and push, no prompt:
```bash
git -C "$VAULT" add sources notes topics assets
git -C "$VAULT" commit -m "Capture: <title>"
git -C "$VAULT" push
```
- Add **only the content dirs** — `plan/` is gitignored and stays local.
- If there's **no `origin`** or the **push fails** (offline / auth), keep the local commit and say so — never lose the capture.
- Pushes to the **private** remote regardless of realm — by design, no waiting. To keep a realm **off** the remote, exclude it structurally (gitignore a path, or a separate local-only repo — the realm-privacy item in `plan/workplan.md`); then it's skipped automatically without a prompt.

## Step 10 — Confirm
Short echo:
```
Captured → sources/<date>-<slug>.md  (<new|updated>)
  realm:  <knowledge|personal|work>
  topic:  topics/<theme>.md
  links:  <N followed / M flagged>     (for listicles)
  note:   notes/<slug>.md              (if promoted)
  status: <processed|inbox>
  pushed: <short-sha> → origin         (or "local only — <reason>")
```
Note any gaps honestly (couldn't reach a paywall, no quotes extracted, links not followed, stub only).

The one rule this command exists to enforce: **keep the source (what they said) separate from your synthesis (what you concluded).** Sources go in `sources/`, conclusions in `notes/`. Don't blur them.
