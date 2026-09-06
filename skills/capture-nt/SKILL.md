---
description: "Save a URL, file, PDF or chat share into the knowledge vault; commits and pushes."
argument-hint: "<url | file path>  [realm: knowledge|personal|work]"
entry: "knowledge vault present at the configured path"
exit: "schema'd source note written, linked, committed + pushed; idempotent on re-run"
writes: "the knowledge vault"
---

Capture something into the **knowledge vault** and wire it into the web of notes. Turns a raw link / file into a schema'd **source note** (what _they_ said), linked into the right **topic MOC**, with an optional **evergreen note** (what _you_ concluded) promoted on top.

**Vault location:** `~/Code/knowledge` — call it `$VAULT` below. (Edit this line if you move the vault.) Its conventions live in `$VAULT/README.md` and `$VAULT/CAPTURE.md`; this command implements that flow.

## Step 1 — Resolve the input
`$ARGUMENTS` is a **URL** or a **file path** (optionally followed by a realm word — see Step 5). If empty, ask _"What am I capturing — a URL or a file path?"_ and use the next message. Classify:
- starts with `http(s)://` → **URL**. A `claude.ai/share/<id>` URL is a **chat session** — the chat-session rules in Steps 3–6 apply on top of the normal flow.
- otherwise → **file path** (expand `~`; confirm it exists). It may already live **inside** the vault — a PDF / doc dropped into `$VAULT/inbox/` or `$VAULT/assets/`. That's fine; capture it in place. A markdown file whose frontmatter declares `capture_mode: capture-file` — or that the user says is a chat's own capture/distillation — is a **pre-distilled chat session**: file it as `source_type: chat-session` (Step 6) and see the promote offer in Step 8.

If `$VAULT` doesn't exist, stop and say so — this command captures _into_ an existing vault, it doesn't create one.

## Step 2 — Orient (before fetching — this is the cheap step that saves the expensive one)
**Run this before you fetch anything.** Its job is to answer three questions in one shot: do we already have this, what is it near, and what should it be labelled. Skipping it is how the same source gets fetched twice and filed under a fresh tag nobody else uses.

If `$VAULT/bin/vaultdb.py` exists, use it — it rebuilds its index from the markdown on every run, so it is never stale:
```bash
"$VAULT/bin/vaultdb.py" orient "<the url, path, or title>"
```
It prints three blocks, and you act on each:

1. **`== idempotency ==`** — if it says **ALREADY CAPTURED**, this is an **update**, not a new capture. Read the named note first and refresh it in place: keep its filename, its `captured` date, its `domain`, and every hand-written line of synthesis. Never write a second note for a source the vault already holds. If it reports no match, it is a new capture.
2. **`== nearby in the vault ==`** — the notes this one will sit beside. Read the top 2–3 before writing; they tell you what the vault already knows, so the new note can link to them (Step 7) and say what is genuinely *new* rather than restating a neighbour. Neighbours also catch the subtler duplicate: the same paper captured earlier under a different URL.
3. **`reuse these tags`** — the tags the neighbours already carry. **Reuse from this list before coining anything new.** A tag used once is nearly useless for retrieval; the whole point of the list is to stop tag cardinality drifting up. Coin a new tag only when nothing offered fits, and prefer an existing broader tag over a novel narrow one.

It also names **candidate topic MOCs** — that is your Step 7 target, decided before you write rather than after.

**Fallback when the index isn't installed** (no `bin/vaultdb.py`), do it by hand:
```bash
rg -l -F "<the url or filename>" "$VAULT/sources/" 2>/dev/null
rg -il -e "<key term 1>" -e "<key term 2>" "$VAULT"/sources "$VAULT"/notes "$VAULT"/topics
```
Also try a normalized URL (strip `utm_*`, fragments, trailing slash). A match ⇒ update in place; none ⇒ new capture.

## Steps 3–8 — fetch, follow, file, link

On entering a step, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Step | Outcome | Detail |
|---|---|---|
| 3 Fetch | The **whole** readable text, by source type: WebFetch for open pages; the Chrome MCP for login-gated ones (x.com, LinkedIn, paywalls); the `pdf` / `docx` skills for documents (OCR a scanned PDF; save a long extract to `$VAULT/assets/<slug>.txt`); `gh repo view` plus the README for a repo; the full transcript with its Human/Assistant turns for a `claude.ai/share` chat. Fetch fails → Chrome MCP → a stub note with `status: inbox`. Never fabricate. | `references/fetch.md` |
| 4 Follow | Every item of a listicle gets a verified one-liner (real stars and license for a repo); an article's load-bearing links only; a repo or arXiv paper the content rests on gets its **own full source note**, wikilinked. Cap at ~15 followed; log what you skipped. A chat session lists its URLs under `## References mentioned` instead. | `references/fetch.md` |
| 5 Metadata | slug · publish-date prefix · `source_type` · `domain` (`knowledge` unless clearly personal or work; ask when sensitive) · tags reused from the vault first · author · published. Chat sessions add `platform`, `session_date`, `capture_mode`. | `references/note-schema.md` |
| 6 Source note | `sources/<date>-<slug>.md` with the vault frontmatter and, in order: TL;DR · Key claims & data · Quotes · Why it matters / connections · Open questions · raw link. What they said, not your opinion. | `references/note-schema.md` |
| 7 Link | One annotated line under the right topic MOC's `## Sources` — normally the MOC Step 2 already named (reuse a MOC before creating one); a backlink from the note; the MOC's `updated:` bumped. | `references/note-schema.md` |
| 8 Promote | An evergreen note in `notes/` only when the source shifts the user's thinking, offered by default for a chat capture file. Ask before creating unless already told to. | `references/note-schema.md` |

## Step 9 — Commit & push (automatic)
Capture isn't done until it's saved. Keep an explicit list of the repo-relative file paths changed by this capture — the source note, any new / updated topic MOC, a promoted note, any saved `assets/` file. List individual files, never whole directories or globs. Preserve unrelated worktree and index changes.

Stage and commit only those paths, then push, no prompt. Populate `capture_paths` from the files actually changed; the two paths below are examples:
```bash
capture_paths=("sources/<date>-<slug>.md" "topics/<theme>.md")
git -C "$VAULT" --literal-pathspecs add -- "${capture_paths[@]}"
git -C "$VAULT" --literal-pathspecs commit --only -m "Capture: <title>" -- "${capture_paths[@]}"
git -C "$VAULT" push
```
- `--only` keeps unrelated files already staged in the index out of this commit; leave those staged changes intact.
- Include only capture-owned files under `sources/`, `notes/`, `topics/`, or `assets/` — `plan/` is gitignored and stays local.
- If there's **no `origin`** or the **push fails** (offline / auth), keep the local commit and say so — never lose the capture.
- Pushes to the **private** remote regardless of realm — by design, no waiting. To keep a realm **off** the remote, exclude it structurally (gitignore a path, or a separate local-only repo — the realm-privacy item in `plan/workplan.md`); then it's skipped automatically without a prompt.

## Step 10 — Confirm
Short echo:
```
Captured → sources/<date>-<slug>.md  (<new|updated>)
  realm:  <knowledge|personal|work>
  tags:   <N reused / M newly coined>
  topic:  topics/<theme>.md
  links:  <N followed / M flagged>     (for listicles)
  note:   notes/<slug>.md              (if promoted)
  status: <processed|inbox>
  pushed: <short-sha> → origin         (or "local only — <reason>")
```
Note any gaps honestly (couldn't reach a paywall, no quotes extracted, links not followed, stub only).

The one rule this command exists to enforce: **keep the source (what they said) separate from your synthesis (what you concluded).** Sources go in `sources/`, conclusions in `notes/`. Don't blur them.
