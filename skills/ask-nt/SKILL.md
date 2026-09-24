---
description: "Answer a question from the knowledge vault only, with note citations. Read-only."
argument-hint: "<your question>  [realm: knowledge|personal|work]"
allowed-tools: ["Bash", "Glob", "Grep", "Read"]
entry: "knowledge vault present"
exit: "answer grounded only in the vault, with note citations and a `Rounds: n/4` footer (read-only)"
writes: "nothing in the vault (vaultdb.py refreshes its own gitignored caches)"
---

Query the **knowledge vault** and answer from it. `/ask-nt` is the read-side sibling of `/capture-nt`: capture writes the substrate, ask reads it back. It answers **only** from what's in the vault and **cites** the notes it used — your personal Google, where the index is your own captured notes.

**Vault location:** `~/Code/knowledge` — call it `$VAULT` below. Conventions in `$VAULT/README.md`.

## Step 1 — Get the question
`$ARGUMENTS` is the question. If empty, ask _"What do you want to know?"_ and use the next message. Note any **realm** the question implies (`personal` / `work` / `knowledge`) — you'll filter on it in Step 2.

## Step 2 — Search in bounded rounds (budget B = 4)
Retrieval runs as a loop, not a single pass. The shape comes from WFM's self-reflection loop (arXiv:2609.18182, §3.3): the evidence set **grows** across rounds and is never replaced, and each round ends with an explicit stop-or-continue decision. At a budget of 4 the paper's agent used **2.58 rounds on average**; forcing all 4 cost **1.58×** for the same accuracy. So stop as soon as the evidence answers the question.

Keep one running **evidence set**: each note you have opened, with the claim you took from it. A later round adds to it. It never drops what an earlier round found, unless a later note directly contradicts it; then keep both and say so in Step 4.

Each round `r` (1 to 4) is one retrieve → read → reflect cycle. A round may run several searches; it ends when you reflect. It does three things:

1. **Retrieve** with that round's query (round 1: the question itself; round 2+: the follow-up query written at the end of the previous round).
2. **Read** the new candidates (Step 3) and add what they say to the evidence set. A partial read (a grepped line, a MOC entry) joins the set only for what you read; cite it as `(entry line only)`.
3. **Reflect.** State all three in your reasoning (never in a file; the read-only contract holds):
   - **draft answer:** the answer the evidence set supports right now, one or two sentences;
   - **follow-up query:** the exact search you would run next, and the gap it closes (a missing number, the other side of a comparison, a name you saw but have not opened);
   - **decision:** `Final` or `Continue`.

   Choose `Final` when the draft answer is fully supported by notes you have read, or when the follow-up query would only repeat an earlier one. Choose `Continue` only when the follow-up names a specific gap. Before `Final` on a factual claim, run one search for a contradicting note; it can share the round. After round 4, stop regardless and treat the draft as final.

   If the caller asks for a trace, print each round's three lines in the answer; otherwise they stay in your reasoning.

### What each round retrieves
Round 1 is **broad**: an unscoped ranked `vaultdb.py search`, then `related` on the strongest hit (`rg` when the index is absent). Round 2+ is **targeted**: it runs the follow-up query with the tool that fits the gap (new terms, `semantic`, MOCs, one-hop links, a realm filter). Read [`references/retrieve.md`](references/retrieve.md) for the commands and the pitfalls (ambiguous terms, any-term hits, the keyword ceiling) before the first round.

## Step 3 — Read the candidates (inside each round)
Don't answer from grep snippets. **Open the top ~3–8 new notes** each round and read them — their TL;DR + key claims are built to answer fast. Don't reopen a note already in the evidence set. Prefer:
- **`notes/` (synthesis)** for "what do I think / conclude" questions,
- **`sources/`** for "what did X say / what's the data" questions,
- the most recent when the topic moves fast (check `captured` / `published`).

## Step 4 — Answer, grounded and cited
- **Lead with the direct answer** — the "Google snippet": 1–3 sentences that actually answer it.
- **Then the support**, with inline citations to the notes used: `[[2026-06-19-glm-5-2-beats-fable-5-design-arena]]`.
- **Keep source vs. synthesis straight** — "the article claims X ([[source]]); you concluded Y ([[note]])." Don't blur them.
- **Ground it ONLY in the vault.** If you draw on anything outside it, label that clearly as outside knowledge — never pass it off as captured.
- **End with `Sources:`** — the notes you actually read, as a short list. Cite from the whole evidence set, every round, not only the last one.
- **Footer:** one last line, `Rounds: <n>/4 (<Final | budget>)`, e.g. `Rounds: 2/4 (Final)`. It says how hard the vault had to be searched.

## Step 5 — Be honest about coverage
- If the vault **doesn't** answer it: say so plainly. Show what _is_ there that's adjacent, and offer to fill the gap — _"want me to `/capture-nt` something on this?"_
- If coverage is **thin or stale** (one source, an old `captured` date): flag it, so the answer carries its own confidence.
- If the question spans **realms**, say which realm the answer came from.

`/ask-nt` is **read-only** — it never writes to the vault's notes. (`vaultdb.py` rebuilds `.vault.db` and fills `.vault.emb.db` on every run; both are gitignored caches, not vault content.) Capturing is a separate, deliberate step (`/capture-nt`).

The one rule this command exists to enforce: **answer from the vault, with receipts.** A confident answer with no citation — or one built from outside knowledge dressed up as a captured note — defeats the point. The whole value is that you can trust the answer because you can trace it.
