## Step 5 — Derive metadata
- **slug** — kebab-case from the title (drop stopwords; short and recognizable; avoid a leading number right after the date prefix).
- **date prefix** — the source's **publish date** (`YYYY-MM-DD`) if discoverable, else today. Filename: `sources/<date>-<slug>.md`.
- **source_type** — `article|tweet|pdf|video|repo|doc|chat-session`, inferred (x.com `/status/` → `tweet`; `/i/article/` → `article`; `.pdf` → `pdf`; `github.com` → `repo`; `.docx` → `doc`; `claude.ai/share/` → `chat-session`).
- **chat-session extras** — title from the shared chat's title if extractable, else the first user message (truncated); **date prefix = the conversation's date**, not the capture date; set `platform` (`claude.ai` for now — the field future-proofs other assistants), `session_date`, and `capture_mode` (`share-url` | `capture-file`) in the frontmatter.
- **domain** — which **realm** this belongs to: **`knowledge`** (general learning — the default), **`personal`** (your own life: health, money, home, family), or **`work`** (a job / client / employer). If the user named a realm in the invocation, use it; else infer from the content. Set it when it's clearly personal or work; default `knowledge` when unsure — and if the content looks **sensitive** (a statement, a contract, medical), ask before filing. (Absent ⇒ `knowledge`.)
- **tags** — reuse existing tags first:
  ```bash
  grep -rhoE 'tags: \[.*\]' "$VAULT/sources" "$VAULT/notes" "$VAULT/topics" | tr ',[]' '\n' | sed 's/tags://; s/ //g' | grep -v '^$' | sort | uniq -c | sort -rn
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
source_type: article|tweet|pdf|video|repo|doc|chat-session
captured: <today>
published:
domain: knowledge        # knowledge | personal | work
tags: []
status: processed        # 'inbox' if it's only a stub
rating:
platform: claude.ai      # chat-session only — which assistant hosted the conversation
session_date: YYYY-MM-DD # chat-session only — date of the conversation, not the capture
capture_mode: share-url  # chat-session only — share-url | capture-file
---
```
The three `chat-session` fields appear **only** on chat-session notes. Never rewrite existing notes to backfill fields — old notes stay untouched.
Then the body, in order — **record what the source said, not your opinion of it:**
- `## TL;DR` — ≤3 lines.
- `## Key claims & data` — bullets; preserve concrete numbers; fold in the **followed-link summaries** from Step 4.
- `## Quotes` — short, verbatim, attributed. If you couldn't get the full text, say so here rather than inventing quotes.
- `## Why it matters / connections` — `[[wikilinks]]` to related notes / sources / topics.
- `## Open questions`.
- Raw link(s) at the bottom.

For a **chat session**, the body keeps the **Human/Assistant turn structure** (condensed is fine — the alternation is the content, so don't flatten it into a summary), and adds `## References mentioned` — the URLs the conversation touched, one line each, not deep-indexed (Step 4).

For a **dropped PDF / doc / image**, keep the file under `$VAULT/assets/` and point the note at it with a relative link (`[paper.pdf](../assets/paper.pdf)`); the note carries the TL;DR + claims, so the vault stays searchable without opening the binary.

## Step 7 — Link it into the graph
- Pick the right **topic MOC(s)** in `$VAULT/topics/`. Reuse an existing one (`ls "$VAULT/topics/"`); create `topics/<theme>.md` only if the theme is genuinely new (MOC frontmatter: `title`, `type: moc`, `tags`, `updated`). Add a **one-line annotated link** to the new source under the MOC's `## Sources`.
- Make sure the source's _"Why it matters / connections"_ section links back (`[[...]]`) to those topics and any related notes — backlinks are just `rg "\[\[<slug>\]\]"`.
- Bump the MOC's `updated:` date.

## Step 8 — Optional: promote a synthesis
If the source genuinely shifts the user's thinking, or combines with existing notes into a reusable insight, offer to write an **evergreen note** in `notes/` — in the _user's_ voice, `status: evergreen`, same `domain`, linking down to the source(s). Don't force it: most captures are just sources. Ask before creating, unless the user already said to.

**Chat capture files are the exception that earns the offer by default:** a capture file is already a distillation — the "what I concluded" side, not raw source material. After filing it as a `chat-session` source, offer to promote it straight to `notes/` in the same pass. Ask; don't assume.
