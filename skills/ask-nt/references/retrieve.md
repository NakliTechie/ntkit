# Retrieval per round

Read by `/ask-nt` Step 2 when a round runs its query.

The vault is structured for retrieval; use the structure, don't just grep blindly — but don't let a guessed topic narrow your search terms before you've cast a wide net. A note is filed by what it's *about*, not by every term someone might use to ask for it; searching only within an assumed domain is how a real hit gets missed entirely.

**Round 1 — broad.** Cast the wide net deterministically before you narrow.
- **Ranked full-text search, unscoped.** If `$VAULT/bin/vaultdb.py` exists, use it — it returns results **ranked by relevance**, which a `rg` file list cannot do, and it rebuilds from the markdown every run so it is never stale:
  ```bash
  "$VAULT/bin/vaultdb.py" search <the question's key terms> --limit 12
  "$VAULT/bin/vaultdb.py" search <terms> --realm work --since 2026-01-01   # when the question scopes it
  ```
  It ranks notes matching **all** terms first, then fills the remaining slots with **any-term** matches; the header says how many matched all. **Treat the any-term tail as weaker evidence** and lean harder on reading. British and American spellings match each other (`licence` finds `license`). If even the all-term part is off-topic, drop the least specific word and search again in the same round.
- **Pivot on the strongest hit** to pull in what shares its vocabulary and tags, including notes that use different words for the same thing:
  ```bash
  "$VAULT/bin/vaultdb.py" related <best-hit-slug> --limit 8
  ```
  Free text works too when nothing hits cleanly: `related "the idea in your own words"`. Scores from different queries are not comparable; pick the pivot by which note best answers the question, not by its number.
- **Fallback without the index:**
  ```bash
  rg -l -i -e "term1" -e "term2" "$VAULT"/sources "$VAULT"/notes "$VAULT"/topics
  ```
- Either way: look at titles, tags, authors, TL;DRs, and claims — not just bodies. **For a short or ambiguous term** (an acronym, initials, a two-word phrase), try its most likely literal expansions too, before picking a domain and searching only that domain's jargon — "MS" could mean Microsoft, a maturity model, or something else; the wrong first guess silently forecloses the right one.

**Round 2+ — targeted.** Run the follow-up query the last round wrote. Pick the tool that fits the gap:
- **A different term** for the same idea: `vaultdb.py search <new terms>`.
- **Keyword search came back thin** but the vault plausibly covers the theme. Keyword search cannot find a note that uses entirely different vocabulary. Browse the topic MOCs: `ls "$VAULT/topics/"`, then read any MOC that matches the question's theme. MOCs narrow among what round 1 found; don't use topic-guessing to decide what to search for in the first place.
- **Same idea, different words:** if the semantic layer is installed, `"$VAULT/bin/vaultdb.py" semantic "<the gap, in plain words>" --limit 8`. It matches by meaning and shows the matching passage. Any non-zero exit (3 = fastembed not installed) means: treat it as unavailable, skip it, browse MOCs instead. The first run on a machine embeds the whole vault (~20–35 s); later runs take under a second.
- **Connected context:** from a strong hit, follow `[[wikilinks]]` one hop, and backlinks via `rg "\[\[<slug>"`. A `[[source#^claim-id]]` link names the exact passage; read that claim first.
- **Realm filter** when the question scopes it: `--realm`, or `rg "^domain: work"`.

A follow-up query that returns only notes already in the evidence set is a signal for `Final`.
