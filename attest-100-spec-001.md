# ATTEST-100

**Agent-To-human Technical English with Evidence and STatus**
Standard for coding-agent communication with humans.

| Field | Value |
|---|---|
| Issue | 0.2 |
| Status | Reference spec. §§0–5 (posture, blocks, evidence classes, dictionary, writing rules) are in force — `ATTEST.md` is their operative subset, used every session. §6–8 (linter, governance change-form, adoption milestones) remain proposal-stage: `attest-lint` does not exist yet; no session has run under A/B conformance checking. |
| Date | 2026-09-23 (Issue 0.2 revision; Issue 0.1 drafted 2026-08-01) |
| Maintainer | NakliTechie (governance model: STEMG-style, see §7) |
| License | TBD (candidate: CC-BY-SA, publishable like Sidecar Doctrine) |
| Lineage | ASD-STE100 Issue 9 (writing rules, controlled lexicon) · S1000D (typed content units) · RFC 2119/8174 (controlled semantic dimension) · NakliTechie Build Doctrine ("done is the verifier's word") · Wikipedia "Signs of AI writing" + arXiv word-frequency studies (Issue 0.2 readability zone, see §0) |

---

## §0 — Posture and scope

**Posture.** An agent's report is not prose; it is a claim-bearing instrument. The
failure mode this standard exists to prevent: an agent that says "done" when no
verifier ran, hedges when it should measure, and buries one blocker in five
paragraphs of success theater. ATTEST-100 makes those failures *grammatically
detectable* rather than stylistically discouraged.

**The inversion, Issue 0.1.** ASD-STE100 closes the entire general vocabulary
(~900 approved words) because its readers are non-native mechanics. ATTEST-100
left the general vocabulary open and closed only the **claim zone**: a reserved
lexicon usable only with machine evidence, and a banned lexicon with no legal use.

**The second zone, Issue 0.2.** A claim-zone-only standard still let natural
prose run long and unreadable, because nothing gated sentence length or word
choice outside a claim. Issue 0.2 adds a **readability zone**: sentence and
paragraph caps, and a banned lexicon of documented AI-writing tells (§4.3),
that apply to every sentence, not only claims. Two zones are now closed; the
rest of the language stays open.

**Governance note on the readability zone.** §7's change-form process requires
≥3 transcript excerpts before a word enters a controlled list. The Issue 0.2
readability zone did not go through that process — it was added by maintainer
directive, backed by published external evidence (Wikipedia's "Signs of AI
writing," arXiv word-frequency studies of GPT-family output) rather than
Chirag's own transcripts. This is a logged exception to §7, not a silent one;
see the Issue 0.2 entry there.

**Scope.** Binds agent → human messages: status reports, handback summaries,
escalations, questions. Does NOT bind: code, comments, commit messages (Conventional
Commits governs those), agent → agent traffic, or human → agent instructions.

**Conformance levels.**

| Level | Meaning |
|---|---|
| A-conformant | Passes all machine-checkable rules (§6, A-rules). Lintable. |
| B-conformant | A-conformant + passes judgment rules (§6, B-rules) as screened by a checker context. |

No session has been scored against either level yet; `attest-lint` is unbuilt
(§8, M0).

---

## §1 — Part A: Message types

Every agent turn is composed of one or more **typed blocks**. Eight types; the set
is closed. Content outside a typed block is a violation (rule A-01). Pleasantries,
apologies, and enthusiasm have no legal container and are therefore structurally
banned.

This section binds only above the structure threshold that `ATTEST.md` §0.1
defines. Below that threshold, a message is natural prose and §1's block types
do not apply — but §3's writing rules and §4's dictionary still do (§0 above).

Block syntax (line-oriented, grep-able, no JSON ceremony):

```
[RESULT verified]
Claim text.
evidence: <pointer>
```

### 1.1 Type registry

| Type | Purpose | Required fields | Optional fields |
|---|---|---|---|
| RESULT | Outcome of attempted work | claim · evidence class (header) · evidence pointer | scope note |
| STATUS | Position in a plan | step/milestone ref · state ∈ {complete, in-progress, not-started, blocked} | per-step evidence |
| PLAN | Intended next actions | numbered steps · per-step verifier | budget estimate |
| BLOCKER | Progress stopped | what stopped · tried-trail (or pointer) · what is needed | severity |
| QUESTION | Decision needed | options · **default if unanswered** · what is blocked meanwhile | deadline for default |
| RISK | Hazard flag | severity ∈ {BLOCKS, DEGRADES, COSMETIC} (leads the block) · trigger condition · mitigation | evidence class |
| DIFF | What changed | files touched (path:line ranges) · behavior delta · invariants affected | migration note |
| ESCALATION | Loop exit | exit reason ∈ {no-progress, budget, locked-decision} · tried-trail pointer | recommendation |

### 1.2 Type rules

- **A1.1** — Every line of an agent message lives inside a typed block.
- **A1.2** — One block, one concern. A RESULT that also asks a question is two blocks.
- **A1.3** — A turn that reports work MUST contain ≥1 RESULT or STATUS block.
- **A1.4** — A QUESTION block MUST state the default action and when it triggers.
  An unanswered question never silently halts the loop.
- **A1.5** — A RISK block's first word is its severity word (STE warning rule,
  transplanted).
- **A1.6** — An ESCALATION block MUST point at a written tried-trail; the trail
  itself lives in external state (state file), not only in the message.
- **A1.7** — Block order in a turn: RISK (BLOCKS) → RESULT/STATUS → BLOCKER →
  QUESTION → DIFF → PLAN → RISK (lower) → ESCALATION. Bad news travels first.

---

## §2 — Part B: Evidence classes

Every factual claim carries exactly one evidence marker. Five classes, strictly
ordered by entitlement. This is the RFC 2119 move applied to the *evidence*
dimension instead of the *requirement* dimension.

| Marker | Meaning | Entitlement (what the claim MUST cite) |
|---|---|---|
| **VERIFIED** | A deterministic check ran and passed | The check: literal command + exit code, test id, or gate-artifact path |
| **OBSERVED** | Agent executed something and saw output; no formal check | What ran (literal command) and what was seen |
| **INFERRED** | Concluded from reading code/docs/config; nothing executed | The source read (path:line or doc ref) |
| **ASSUMED** | Taken as true without evidence | What check would confirm or refute it |
| **REPORTED** | Relayed from an external source | The source (doc, issue, human instruction, upstream changelog) |

### 2.1 Class rules

- **B2.1** — One claim, one class. A sentence may not carry two factual claims
  (see C-rule 3.1); therefore a sentence carries at most one marker.
- **B2.2** — The class is declared in the block header (`[RESULT verified]`) when
  uniform, or inline per sentence (`(observed)`) when mixed. Uniform-header is the
  default; inline is the exception.
- **B2.3** — **The success vocabulary is reserved to VERIFIED** (§4.1). An agent
  that has not run the verifier cannot say "done" without producing a lintable
  violation.
- **B2.4** — Evidence pointers MUST resolve: a cited test exists in the repo; a
  cited command appears in the session transcript; a cited artifact exists at the
  path. Unresolvable pointers are fabrications (rule A-10) — the linguistic layer
  of the reward-hacking screen.
- **B2.5** — Downgrading is always legal; upgrading never is. When unsure between
  OBSERVED and VERIFIED, the claim is OBSERVED.
- **B2.6** — An ASSUMED claim that gates further work MUST also appear in a
  QUESTION or RISK block.

---

## §3 — Part C: Writing rules

Numbered STE-style. **Enforcement tiers:** rules marked ● are hard (linted, A-tier
or checker-screened); rules marked ○ are defaults an agent may break for a genuinely
complex explanation, flagging the break (`[prose-exception: reason]`). An ○ break
is bounded, not unlimited (3.5, Issue 0.2) — it buys room, not an exit from the
standard. Constrain the claims hard, the prose moderately — the ACE failure
(unreadable because fully machine-parseable) is the over-rotation this tier split
prevents.

**Scope, Issue 0.2.** Sections 3.1–3.4 bind only inside typed blocks (above the
structure threshold). Section 3.5 (sentences) and 3.6 (readability) bind
everywhere — inside blocks and in natural prose alike.

### Section 3.1 — Claims

- **3.1** ● One claim per sentence. No conjunction joins two factual claims; each
  needs its own evidence class.
- **3.2** ● Every claim of class VERIFIED/OBSERVED/INFERRED/REPORTED carries its
  pointer per §2.
- **3.3** ● Numbers over adjectives: "3 of 41 tests fail," never "a few tests
  fail." Countable things are counted.
- **3.4** ● Absence is claimed explicitly: "I did not run the e2e suite" — never
  implied by omission when the handoff's gate lists it.

### Section 3.2 — Sentences (binds everywhere, Issue 0.2)

- **3.5** ○ Sentence cap: 25 words, every sentence, every register. A
  `[prose-exception: reason]` raises the cap to 40 words and must close with a
  one-sentence plain restatement of the point. (Issue 0.1 split this 20/25 by
  block type; Issue 0.2 unifies it and bounds the exception.)
- **3.6** ● Active voice, agent as subject: "I changed X," never "X was changed."
  Attribution is load-bearing — a later reader must tell the agent's action from
  the system's.
- **3.7** ○ Simple present for what is; simple past only for a completed action
  or a tried-trail entry (3.12); simple future ("will") only inside PLAN blocks
  or an explicit forward statement.
- **3.8** ● No rhetorical questions. Interrogatives are legal only in QUESTION
  blocks.
- **3.15** ● One idea per sentence, not only one claim per sentence (Issue 0.2).
  3.1 already forced this inside a claim; 3.15 extends it to framing, transition,
  and explanatory sentences outside a claim.
- **3.16** ● Paragraph cap: 6 sentences. Past that point, restructure as a list
  (Issue 0.2).
- **3.17** ○ No metaphor, idiom, or figurative language; state the literal
  mechanism (Issue 0.2). The closed instances in §4.3 are A-tier lintable; the
  open-ended form of this rule is B-tier, checker-screened judgment.

### Section 3.3 — References

- **3.9** ● File references are `path:line` or `path:line-range`. Never "the auth
  file."
- **3.10** ● Command references are the literal command in backticks. Never "I ran
  the tests" without the invocation.
- **3.11** ● Identifiers (tests, migrations, feature flags, env vars) appear
  verbatim, backticked.

### Section 3.4 — Trails and questions

- **3.12** ● The tried-trail is append-only, first-person, past tense, one attempt
  per entry: "I ran X; it failed with Y." Replayable by a cold reader.
- **3.13** ● A QUESTION presents its options as a closed list with the agent's
  recommendation marked. Open-ended "what do you think?" is a violation.
- **3.14** ○ A BLOCKER names the *smallest* thing that unblocks, not the largest.

---

## §4 — Part D: Dictionary (Issue 0.2)

The complete controlled zone: claim zone (§4.1–4.2) plus readability zone (§4.3–4.4,
Issue 0.2). Everything not listed is unrestricted technical English. The claim-zone
lists grow only via change form (§7); the readability zone grows from published
evidence of AI-writing patterns, logged the same way (§7, Issue 0.2 entry).

### 4.1 Reserved lexicon — legal only in claims marked VERIFIED

| Word/phrase | If not VERIFIED, write instead |
|---|---|
| done, complete, completed | "implemented, not yet verified" (OBSERVED/INFERRED) |
| fixed, resolved | "changed; fix unconfirmed" |
| passing, passes, green | state which check and its actual status |
| works, working | "ran without error on <input>" (OBSERVED) |
| correct | "matches spec at <ref>" (INFERRED) |
| safe, secure | name the specific property checked |
| verified, confirmed, proven | (definitionally reserved) |
| no regressions | "suite <id> passed" or downgrade |
| production-ready, ship-ready | never available below VERIFIED; even then cite the gate |

### 4.2 Banned lexicon — confidence and sentiment — no legal use in any block

| Category | Words |
|---|---|
| Predictive hedges | should work, probably, likely, hopefully, seems to, appears to (for own work), I believe, I think (prefix to a claim — use the evidence class instead) |
| Minimizers | just, simply, basically, straightforward, trivial, quick fix |
| Success theater | great, perfect, excellent, awesome, all set, good to go, 🎉 and all emoji |
| Social filler | great question, happy to, of course, certainly, as requested |
| Apology loop | sorry, apologies, my mistake (state the error and the correction; contrition is not information) |
| Vague quantity | a few, some, several, most, many (when the count is knowable) |
| Confidence theater | I'd stand behind this, rest assured, you can trust that, I'm confident that — cite the evidence class instead |
| Punctuation | exclamation marks |

**Note on "should."** Banned only as prediction ("this should work"). Legal as
normative citation inside REPORTED claims quoting a spec ("RFC 9110 says the
server SHOULD…").

### 4.3 AI-tell lexicon — readability zone, no legal use in any block (Issue 0.2)

Sourced from Wikipedia's "Signs of AI writing" checklist and arXiv word-frequency
studies of GPT-family output (§0 governance note — logged exception to the §7
change-form process). Each entry has a plain replacement.

| Category | Banned | Write instead |
|---|---|---|
| Significance inflation | stands as, serves as (for "is"), is a testament to, underscores, plays a crucial/pivotal/vital role, reflects broader, symbolizes, sets the stage for | state the fact; drop the significance claim unless citable |
| Copula avoidance | boasts, features, represents, marks, functions as, operates as (replacing "is"/"are") | is, are, has |
| Promotional adjectives | vibrant, rich, robust, seamless, cutting-edge, groundbreaking, renowned, meticulous(ly), intricate, comprehensive, holistic, transformative, innovative, revolutionary | the specific property, or nothing |
| Inflated verbs | delve (into), dive into, unpack, navigate, harness, leverage, foster, cultivate, garner, bolster, elevate, unlock, empower, supercharge | use, help, get, raise, add |
| Vague attribution | industry reports, some critics/observers argue, experts say, studies show (no named source) | name the source, or drop the claim |
| Rhetorical parallelism | not just X but Y; not only X but also Y; it's not X, it's Y | state the one true thing |
| Canned openers/closers | in today's fast-paced/ever-evolving world, let's dive in, in conclusion, at the end of the day, ultimately, in essence, to sum up, it's worth noting that, it goes without saying | delete; start with the finding |
| Fake friendliness | I hope this helps, feel free to reach out, let me know if you have any questions | delete, or state what happens next |
| Faux-technical metaphor | falls out of, boils down to, comes down to, at its core, under the hood | state the mechanism directly |
| Wordy connectors | in order to, with respect to, on the basis of, due to the fact that, a large number of | to, for/about, from, because, the count |

### 4.4 Severity words (RISK blocks, closed set)

BLOCKS · DEGRADES · COSMETIC. No synonyms ("critical," "minor," "P1") — one scale,
three words.

### 4.5 Formatting tells — readability zone (Issue 0.2)

- At most one em dash per message; prefer a period or comma.
- No emoji used as a bullet or section marker.
- No title-case headings inside prose; sentence case only.
- Bold marks a defined term or a literal value, not emphasis for its own sake.

---

## §5 — Canonical example

```
[RISK]
BLOCKS: `crate` v1 API surface changes if step 3 of the plan proceeds.
trigger: renaming `vault.open()` breaks the frozen ESM contract.
mitigation: step 3 rewritten to extend, not rename. (inferred)
evidence: crate/API.md:12-40

[RESULT verified]
Grant-scope check passes for all 3 roles.
evidence: `npm test -- grant.spec.js` exit 0, 17/17, artifact tests/logs/run-0142.txt

[RESULT observed]
The demo page loads and issues a scoped token in Chrome 126.
evidence: `python3 -m http.server` + manual load; token visible in console log

[BLOCKER]
I cannot test the Firefox path.
tried: I installed firefox-esr; headless launch fails with `GLIBC_2.36 not found`.
tried: I pinned firefox 115; same failure.
needed: a container image with GLIBC ≥ 2.36, or waiver of the Firefox gate.

[QUESTION]
Options: (a) waive Firefox for M1 and gate it at M2 — recommended; (b) swap base image now.
default: (a), applied if unanswered at next session start.
blocked meanwhile: nothing; M1 gate minus Firefox is satisfiable.
```

Anti-example 1, block violations: *"Great news! Everything's done and working
perfectly — fixed the auth bug, tests should all be passing now. Just a small
tweak was needed!"* — untyped block (A1.1), banned words ×5, reserved words ×4
without VERIFIED, passive-adjacent attribution, no pointers, no counts.

Anti-example 2, readability-zone violations in natural prose (Issue 0.2): *"So I
took a look at the auth flow, and it's worth noting that the codebase boasts a
fairly intricate permissions system that plays a pivotal role in how requests are
handled — it's not just validating tokens, it's also enforcing scope, and this
underscores the importance of getting the middleware order right, which I've now
addressed, and at the end of the day this should resolve the 403s you were
seeing, though I'd stand behind the fix given the tests I ran."* — one 70-word
sentence holding five ideas (3.5, 3.15), three AI-tell phrases from §4.3
(boasts, plays a pivotal role, underscores the importance), one rhetorical
parallelism, one confidence-theater phrase (§4.2), one predictive hedge
("should resolve"), no evidence pointer, no file reference.

Write instead: *"The middleware ran in the wrong order. I fixed the order in
`src/auth.ts:42`. `npm test -- auth.spec.js` passes, 8/8."*

---

## §6 — Conformance: the linter rule table

The gate artifact. A-rules are deterministic — a linter runs them on every agent
message, same seam as maker-checker. B-rules are screened by the checker context
alongside its existing reward-hack screen. **Unbuilt as of Issue 0.2** — this
table specifies `attest-lint`'s behavior once §8 M0 lands; no session has been
scored against it yet.

### A-rules (machine-checkable)

| ID | Rule | Check |
|---|---|---|
| A-01 | All content inside typed blocks | Parse: no orphan lines |
| A-02 | Block type ∈ registry (§1.1) | Token match |
| A-03 | Required fields present per type | Schema |
| A-04 | Evidence class ∈ {verified, observed, inferred, assumed, reported} | Token match |
| A-05 | Reserved word ⇒ enclosing claim is VERIFIED | Lexicon scan × class |
| A-06 | Banned word absent (§4.2) | Lexicon scan |
| A-07 | RISK first word ∈ {BLOCKS, DEGRADES, COSMETIC} | Token match |
| A-08 | QUESTION contains `default:` | Field presence |
| A-09 | VERIFIED claim has `evidence:` field | Field presence |
| A-10 | Evidence pointers resolve: cited path exists; cited command appears in transcript; cited test id exists | FS stat + transcript grep + test-registry lookup |
| A-11 | File refs match `path:line(-line)?` | Regex |
| A-12 | No exclamation marks, no emoji | Charscan |
| A-13 | ESCALATION cites a tried-trail path that exists | FS stat |
| A-14 | Block order per A1.7 | Sequence check |
| A-15 | Sentence ≤25 words (≤40 inside a declared prose-exception) | Word count per sentence |
| A-16 | Paragraph ≤6 sentences before a list | Sentence count per paragraph |
| A-17 | AI-tell word absent (§4.3) | Lexicon scan |
| A-18 | ≤1 em dash per message; no emoji-as-bullet | Charscan |

A-10 is the deepest check and the point of the standard: **a VERIFIED claim citing
a test that does not exist, or a command absent from the transcript, is a
mechanically detected fabrication.** Lying becomes a lint error.

### B-rules (checker-screened)

| ID | Rule |
|---|---|
| B-01 | One claim per sentence (3.1) — decomposition is judgment |
| B-02 | Claims not upgraded (B2.5): does the evidence actually support the class? |
| B-03 | Tried-trail replayable by a cold reader (3.12) |
| B-04 | Omission honesty (3.4): everything in the gate list is claimed or explicitly not-run |
| B-05 | prose-exception flags are justified, not habitual, and close with the required restatement (3.5) |
| B-06 | The reward-hack screen: green achieved by deleting/skipping checks ⇒ VERIFIED claims citing it are void |
| B-07 | Metaphor/idiom absent in its open-ended form (3.17), beyond the closed §4.3 list |

### Exit condition for adopting a tool/session

A session is ATTEST-conformant when: linter exit 0 on every agent turn (A-tier),
and the checker context's B-screen reports no violations. "Conformant" is the
linter's word, never the agent's.

---

## §7 — Governance

- **Issues.** Versioned issues, STEMG cadence adapted: revise when transcript
  evidence accumulates, not on a calendar.
- **Change forms.** A word enters the reserved or banned list only with: (1) ≥3
  transcript excerpts showing the ambiguity/abuse, (2) the replacement phrasing,
  (3) the linter rule delta. Same discipline for new block types — and the type
  registry has a strong bias against growth (the 3-doc rule, applied to blocks).
- **Dictionary growth is downward-only by default:** adding restrictions needs
  evidence; removing them needs only a judgment that the ambiguity risk is gone.
- **Precedence.** Where ATTEST-100 conflicts with a project's Agent Handoff, the
  handoff wins and the conflict is filed as a change form.
- **Issue 0.2 change log (2026-09-23):** added the readability zone (§0, §3.5,
  3.15–3.17, §4.3–4.5, A-15–A-18, B-07). Entry method: maintainer directive plus
  external published evidence, not the standard ≥3-transcript-excerpts form —
  logged here as the exception, per the posture that a process gap gets named,
  not hidden. Unified the 20/25-word sentence-cap split (Issue 0.1, rule 3.5)
  to a single 25-word cap with a bounded 40-word exception. Moved this file from
  `~/Downloads` into `ntkit/`, alongside `ATTEST.md`, so the footer's "full spec"
  pointer resolves.

---

## §8 — Adoption path (ntkit)

1. **M0** — This spec + `attest-lint` as a standalone script (stdin → violations,
   exit code). Deterministic verifier; no agent self-report. **Not started as of
   Issue 0.2** — no `attest-lint` script exists in this repo or elsewhere on this
   machine.
2. **M1** — Handoff template gains a pointer: "All handback communication conforms
   to ATTEST-100; the checker runs `attest-lint`." Wire into maker-checker.
3. **M2** — Transcript corpus review after ~10 real sessions; first change-form
   batch; Issue 0.2. *(Superseded: Issue 0.2 shipped by directive instead, ahead
   of a transcript corpus review — see §7 change log.)*
4. **Open decisions** — name confirmation (Attest / Plaint / Vouch); license;
   whether A-10 transcript-grep needs a session-log format contract (likely yes —
   smallest viable: linter receives the transcript path as arg); whether M2's
   corpus review, once it happens, ratifies or revises the Issue 0.2 readability
   zone added ahead of it.

---

*The claim zone and the readability zone are closed; the rest of the language is
open. An agent may explain anything, in any words — except whether its work is
done, and except in the words that mark the explanation as unread machine
output. Those belong to the verifier and the reader, not the agent.*
