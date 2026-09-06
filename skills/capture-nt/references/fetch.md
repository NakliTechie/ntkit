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
| claude.ai chat share (`claude.ai/share/<id>`) | **WebFetch**; fall back to the Chrome MCP if the share page doesn't render. Extract the **full transcript**, strip UI chrome, and **keep the Human/Assistant turn structure** — the alternation is the content. |

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
- **Chat session → don't deep-index its links.** Chats reference many URLs in passing; the repo/paper full-capture rule above does **not** apply to `chat-session` sources. List every substantive URL in a `## References mentioned` section of the source note instead, and deep-index one only if the user asked explicitly in the invocation or confirms when offered.
- **Bound it.** Cap at ~15 followed links; beyond that, follow the most important and **`log` what you skipped** — never silently truncate. Dedupe; skip chrome (login / share / home links).
- **Flag discrepancies.** When a followed fact contradicts the source, record both: _"claimed 51K → verified 69K (at capture)"_.

The followed summaries become part of `## Key claims & data` (e.g. one enriched bullet per listicle item).
