---
description: "Answer a question from the knowledge vault only, with note citations. Read-only."
argument-hint: "<your question>  [realm: knowledge|personal|work]"
entry: "knowledge vault present"
exit: "answer grounded only in the vault, with note citations (read-only)"
writes: "nothing"
---

Query the **knowledge vault** and answer from it. `/ask-nt` is the read-side sibling of `/capture-nt`: capture writes the substrate, ask reads it back. It answers **only** from what's in the vault and **cites** the notes it used — your personal Google, where the index is your own captured notes.

**Vault location:** `~/Code/knowledge` — call it `$VAULT` below. Conventions in `$VAULT/README.md`.

## Step 1 — Get the question
`$ARGUMENTS` is the question. If empty, ask _"What do you want to know?"_ and use the next message. Note any **realm** the question implies (`personal` / `work` / `knowledge`) — you'll filter on it in Step 2.

## Step 2 — Search the vault (broad → narrow)
The vault is structured for retrieval; use the structure, don't just grep blindly — but don't let a guessed topic narrow your search terms before you've cast a wide net. A note is filed by what it's *about*, not by every term someone might use to ask for it; searching only within an assumed domain is how a real hit gets missed entirely.

1. **Ranked full-text search first, unscoped.** Cast the wide net deterministically before you narrow. If `$VAULT/bin/vaultdb.py` exists, use it — it returns results **ranked by relevance**, which a `rg` file list cannot do, and it rebuilds from the markdown every run so it is never stale:
   ```bash
   "$VAULT/bin/vaultdb.py" search <the question's key terms> --limit 12
   "$VAULT/bin/vaultdb.py" search <terms> --realm work --since 2026-01-01   # when the question scopes it
   ```
   It matches all terms first and automatically widens to any-term when that returns nothing — the output says which mode produced the hits, so **treat any-term results as weaker evidence** and lean harder on Step 3's reading.

   Then **pivot on the strongest hit** to pull in what shares its vocabulary and tags, including notes that use different words for the same thing:
   ```bash
   "$VAULT/bin/vaultdb.py" related <best-hit-slug> --limit 8
   ```
   Free text works too when nothing hits cleanly: `related "the idea in your own words"`.

   **Fallback without the index:**
   ```bash
   rg -l -i -e "term1" -e "term2" "$VAULT"/sources "$VAULT"/notes "$VAULT"/topics
   ```
   Either way: look at titles, tags, authors, TL;DRs, and claims — not just bodies. **For a short or ambiguous term** (an acronym, initials, a two-word phrase), try its most likely literal expansions too, before picking a domain and searching only that domain's jargon — "MS" could mean Microsoft, a maturity model, or something else; the wrong first guess silently forecloses the right one.

   **Keyword search has a known ceiling:** it cannot find a note that discusses the same concept in entirely different vocabulary. When the ranked hits look thin but the vault plausibly covers the theme, fall back to browsing the topic MOCs (step 2) rather than concluding the vault is empty.
2. **Topics next, to narrow.** `ls "$VAULT/topics/"` and read any MOC matching the question's theme — MOCs are the curated indexes, and their linked notes are the high-signal set for *narrowing among* what Step 1 already found. Don't use topic-guessing to decide what to search for in the first place.
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
