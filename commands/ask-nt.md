---
description: "Ask your knowledge vault (~/Code/knowledge) a question — search + read the notes, answer in plain language grounded ONLY in the vault, with citations to the notes used. The read-side sibling of /capture-nt; the \"search\" half of your personal Google. Read-only."
argument-hint: "<your question>  [realm: knowledge|personal|work]"
---

Query the **knowledge vault** and answer from it. `/ask-nt` is the read-side sibling of `/capture-nt`: capture writes the substrate, ask reads it back. It answers **only** from what's in the vault and **cites** the notes it used — your personal Google, where the index is your own captured notes.

**Vault location:** `~/Code/knowledge` — call it `$VAULT` below. Conventions in `$VAULT/README.md`.

## Step 1 — Get the question
`$ARGUMENTS` is the question. If empty, ask _"What do you want to know?"_ and use the next message. Note any **realm** the question implies (`personal` / `work` / `knowledge`) — you'll filter on it in Step 2.

## Step 2 — Search the vault (broad → narrow)
The vault is structured for retrieval; use the structure, don't just grep blindly:

1. **Topics first.** `ls "$VAULT/topics/"` and read any MOC matching the question's theme — MOCs are the curated indexes; their linked notes are the high-signal set.
2. **Full-text search** across `sources/` and `notes/` for the question's key terms _and synonyms_:
   ```bash
   rg -l -i -e "term1" -e "term2" "$VAULT"/sources "$VAULT"/notes
   ```
   Look at titles, tags, TL;DRs, and claims — not just bodies.
3. **Realm filter** when the question scopes it: add `rg "^domain: work"` etc., or restrict to the matching notes.
4. **Follow the graph.** From strong hits, follow `[[wikilinks]]` one hop (and their backlinks via `rg "\[\[<slug>\]\]"`) to pull in connected context.

## Step 3 — Read the candidates
Don't answer from grep snippets. **Open the top ~3–8 notes** and read them — their TL;DR + key claims are built to answer fast. Prefer:
- **`notes/` (synthesis)** for "what do I think / conclude" questions,
- **`sources/`** for "what did X say / what's the data" questions,
- the most recent when the topic moves fast (check `captured` / `published`).

## Step 4 — Answer, grounded and cited
- **Lead with the direct answer** — the "Google snippet": 1–3 sentences that actually answer it.
- **Then the support**, with inline citations to the notes used: `[[2026-06-19-glm-5-2-beats-fable-5-design-arena]]`.
- **Keep source vs. synthesis straight** — "the article claims X ([[source]]); you concluded Y ([[note]])." Don't blur them.
- **Ground it ONLY in the vault.** If you draw on anything outside it, label that clearly as outside knowledge — never pass it off as captured.
- **End with `Sources:`** — the notes you actually read, as a short list.

## Step 5 — Be honest about coverage
- If the vault **doesn't** answer it: say so plainly. Show what _is_ there that's adjacent, and offer to fill the gap — _"want me to `/capture-nt` something on this?"_
- If coverage is **thin or stale** (one source, an old `captured` date): flag it, so the answer carries its own confidence.
- If the question spans **realms**, say which realm the answer came from.

`/ask-nt` is **read-only** — it never writes to the vault. Capturing is a separate, deliberate step (`/capture-nt`).

The one rule this command exists to enforce: **answer from the vault, with receipts.** A confident answer with no citation — or one built from outside knowledge dressed up as a captured note — defeats the point. The whole value is that you can trust the answer because you can trace it.
