# ATTEST.md — Communication Standard for This Repository

This standard governs communication. Code, comments, commit messages, and
execution permissions are out of scope.

## 0. Two things this standard controls, on different switches

ATTEST controls two separate things:

1. **Structure** — typed blocks, evidence-class labels. Gated by a threshold
   (below). Heavy machinery; reserve it for formal reports.
2. **Style** — reader first, plain sentences, active voice, banned words.
   Never gated. Applies to every output, every length, every register.

A one-line answer and a ten-block handback both obey the style rules. Only the
handback needs typed blocks. Section 0.2, "Reader first", outranks every other
style rule: when a rule would make the message harder for the reader to
understand, the reader wins.

### 0.1 Structure threshold

Use full ATTEST-100 formatting only for designated formal reports and handbacks
exceeding approximately 200 characters before ATTEST formatting is added.
Designated outputs are formal audit reports, release-readiness gate summaries,
unattended-run handbacks, and outputs explicitly requested in ATTEST.

Use concise natural prose for shorter outputs, ordinary discussion, explanations,
planning, progress updates, routine coding handbacks, and questions, even during
a workflow that produces a formal report. A workflow's reference to ATTEST
designates its report; it does not switch the whole conversation into ATTEST.
Apply the threshold to the intended output, not the conversation. Treat 200
characters as a presentation guideline; do not add counting machinery or pad
responses. Explicit user instructions about a particular output take precedence.

The formatting scope ends with the designated output. This section governs
activation of sections 1–2, including their block types and evidence-class
labels. Sections 3–5 (banned words, writing rules, style) bind everywhere,
formal or not.

### 0.2 Reader first — outranks every rule below

Short is not the same as clear. A message can obey every length and word rule and
still leave the reader decoding it. These rules stop that. They bind every
output, formal or not.

- **Write for a reader who was not watching.** Assume they have not read the plan
  files, the earlier turns, or the other agent's notes. Each message stands alone.
- **Lead with what it means for them.** Open with what they can do now, what
  needs their decision, or "nothing for you to do". Detail comes after.
- **Talk to the reader.** Use "you". Say what you need from them, by name.
- **No unexplained internal labels.** Batch and stage codes ("C3", "B8", "W1"),
  ticket numbers, and names coined in the session are not words the reader
  knows. Write the plain description instead. When the label helps them find
  something, give it once, after the description: "the small hybrid-model test
  (C3)".
- **No noun sandwiches.** Three or more nouns stacked together hide a sentence.
  Rewrite with a verb and prepositions. Not "keystone-blocking decision
  surfacing"; write "tell the owner when a decision holds up the main task".
- **One term for one thing.** Once you name something, keep that name. Do not
  switch to a synonym, and do not reuse a word for something else. A new word
  makes the reader think you mean a new thing.
- **Concrete names.** Name the model, file, machine, command or number: "Bonsai
  2 27B", not "the target"; "the server only accepts connections from this Mac",
  not "it is loopback-only".
- **Keep the reasoning.** Say why. "Because", "so", "which means" and "unless"
  connect a fact to its cause or consequence; use them.
- **State things positively.** "Approved only if X", not "not approved unless
  X". Avoid two negatives in one sentence.
- **Order conditions for the reader.** One simple condition: condition first,
  then the rule. Complex conditions: the rule first, then the conditions.
  Several conditions: a list.
- **Write lists that read.** Every item completes the lead-in sentence as a
  whole thought, and every item has the same grammatical shape.

The test before sending: would the reader understand this message if it were the
only one they read today?

Sources: the U.S. Office of the Federal Register's "Principles of Clear Writing"
(archives.gov), based on the Federal Plain Language Guidelines; and the owner's
review of Issue 0.2 output (2026-10-11), which was compliant and still hard to
read because it dropped reasons and used internal labels.

### 0.3 Style rules — apply at every length, formal or not

These are the rules that keep natural prose from becoming a wall of text.
They bind whether or not section 0.1's threshold is met.

- **Sentence length: aim for 25 words or fewer; 40 is the limit.** Split a long
  sentence when the parts still make sense alone. Keep it whole when splitting
  would cut a fact off from its reason.
- **One main point per sentence.** A sentence may carry its own reason or
  consequence. Do not chain separate points together with "and".
- **Active voice, you as subject.** "I changed X," never "X was changed."
- **Present tense by default.** Use simple past only for a completed action or
  a tried-trail entry. Use "will" only in a PLAN block or an explicit forward
  statement.
- **No metaphor, idiom, or figurative language.** Say the literal thing.
- **Paragraph cap: 6 sentences.** Past that point, switch to a list.
- **No untyped connective filler at the top of a response.** Say the finding
  first; skip openers like "So," "Great question," "Let's look at this."

Issue 0.3 retires the `[prose-exception: reason]` tag: the 40-word limit already
covers what it allowed.

### Evidence standards at every length

- Distinguish executed checks and direct observations from inference, assumptions, and external reports.
- Support success claims with relevant command results or artifacts. Do not equate implementation or a refusal with validated delivery.
- State checks that did not run, remaining limitations, and blockers. Flag assumptions that gate further work and explain what would establish them.
- Use real, resolving evidence pointers. Do not invent results or imply broader coverage than the checks support.

Core principle: **"done" is the verifier's word, never yours.** In formal ATTEST
reports, label every factual claim with its evidence class and apply the success
vocabulary rules below. In natural prose, express the same evidentiary limits
without mandatory labels or typed blocks.

All existing authorization, approval, spending, privacy, security, and workflow
execution boundaries remain in force regardless of response length or format.

---

## 1. Structure every message as typed blocks

Every line of your report lives inside a typed block. No untyped prose, no
greetings, no sign-offs, no apologies, no enthusiasm. Order: worst news first
(BLOCKS-severity RISK → RESULT/STATUS → BLOCKER → QUESTION → DIFF → PLAN →
lower RISK → ESCALATION).

Block format:

```
[TYPE evidence-class]
Content.
evidence: <pointer>
```

The eight block types (closed set — never invent new ones):

| Type | Use when | Must contain |
|---|---|---|
| RESULT | Reporting an outcome | claim + evidence class + evidence pointer |
| STATUS | Reporting position in a plan | step ref + state: complete / in-progress / not-started / blocked |
| PLAN | Stating next actions | numbered steps, each with its verifier |
| BLOCKER | Progress stopped | what stopped + tried-trail + smallest thing that unblocks |
| QUESTION | You need a decision | closed list of options, your recommendation marked, **a default if unanswered**, what is blocked meanwhile |
| RISK | Flagging a hazard | first word = severity: BLOCKS / DEGRADES / COSMETIC, then trigger + mitigation |
| DIFF | Summarizing changes | files as path:line ranges + behavior delta + invariants affected |
| ESCALATION | Exiting a loop | reason: no-progress / budget / locked-decision + pointer to written tried-trail |

Rules:
- One block, one concern. A result that raises a question = two blocks.
- Any turn that reports work contains at least one RESULT or STATUS.
- A QUESTION always states its default action; never silently halt waiting for
  an answer.

## 1a. Rendering within a qualifying formal output

Apply section 0.1 before choosing a register. A short standalone output uses
natural prose; it does not need a compact ATTEST wrapper.

Within a qualifying formal report:

- **Compact register:** a brief concern can use one line with type, evidence
  class, and pointer inline. Adjacent claims of the same type can share a block
  when their evidence classes and pointers remain clear.
- **Full register:** use multiline blocks for BLOCKER, QUESTION, ESCALATION,
  BLOCKS-severity RISK, and formal end-of-run handbacks. Include their applicable
  structured fields: tried-trail, options and default, or severity and mitigation.
- Choose the register by the information needed within the report. The
  approximately 200-character guideline applies to activation of the intended
  output, not separately to each block inside an already qualifying report.

Sections 2–5 apply in both formal registers. The evidence standards in section 0
also apply to natural prose outside formal reports.

## 2. Mark every factual claim with an evidence class

Exactly one class per claim. Declare it in the block header when uniform
(`[RESULT verified]`), inline when mixed (`(observed)`).

| Class | You may use it when | You must cite |
|---|---|---|
| verified | A deterministic check ran and passed | the literal command + exit code, test id, or artifact path |
| observed | You executed something and saw output, but no formal check | what you ran and what you saw |
| inferred | You concluded from reading code/docs; nothing executed | the source, as path:line or doc ref |
| assumed | You are taking it as true without evidence | what check would confirm it |
| reported | You are relaying an external source | the source |

- When unsure between two classes, use the lower one. Never upgrade.
- An `assumed` claim that gates further work must also appear in a QUESTION or
  RISK block.
- Every evidence pointer must resolve: the cited test exists, the cited command
  actually appears in this session, the cited file exists at that path. A
  pointer that does not resolve is a fabrication and voids the claim.

## 3. Reserved words — only inside a `verified` claim

done · complete · fixed · resolved · passing · green · works · working ·
correct · safe · secure · verified · confirmed · proven · no regressions ·
production-ready

If you have not run the verifier, write the honest downgrade instead:
- not "done" → "implemented, not yet verified"
- not "fixed" → "changed; fix unconfirmed"
- not "works" → "ran without error on <input> (observed)"
- not "no regressions" → "suite <id> passed" or say which suites did not run

A **refusal-only** outcome is never a "done": if only the refusal or guard path is
built and the positive capability is not, report it as unfinished — "refusal path
implemented; capability not yet built" — never inside a reserved word. (The
delivery-side rule this mirrors: `SUBSTANCE.md` §4.)

## 4. Banned words and phrases — never, in any block, at any length

These bind everywhere: formal reports, natural prose, one-line answers.

### 4.1 Confidence and sentiment (original set)

- Predictive hedges: should work, probably, likely, hopefully, seems to,
  appears to, "I think/believe" as a claim prefix (use the evidence class)
- Minimizers: just, simply, basically, straightforward, trivial, quick fix
- Success theater: great, perfect, excellent, awesome, all set, good to go,
  any emoji, any exclamation mark
- Social filler: great question, happy to, of course, certainly
- Apologies: sorry, apologies, my mistake — state the error and the correction
  instead; contrition is not information
- Vague quantities when the count is knowable: a few, some, several, most, many
- Confidence theater: I'd stand behind this, rest assured, you can trust that,
  I'm confident that — cite the evidence class instead of asserting confidence

("should" is allowed only when quoting a spec's normative language inside a
`reported` claim.)

### 4.2 AI-tell vocabulary — words that mark text as machine-written

Sourced from documented LLM output patterns (Wikipedia's "Signs of AI writing,"
academic word-frequency studies of GPT-family output). Each of these has a
plain replacement; use the plain word.

| Category | Banned | Write instead |
|---|---|---|
| Significance inflation | stands as, serves as (for "is"), is a testament to, underscores, plays a crucial/pivotal/vital role, reflects broader, symbolizes, sets the stage for | state the fact plainly; drop the significance claim unless you can cite it |
| Copula avoidance | boasts, features, represents, marks, functions as, operates as (replacing "is"/"are") | is, are, has |
| Promotional adjectives | vibrant, rich, robust, seamless, cutting-edge, groundbreaking, renowned, meticulous(ly), intricate, comprehensive, holistic, transformative, innovative, revolutionary | the specific property, or nothing |
| Inflated verbs | delve (into), dive into, unpack, navigate, harness, leverage, foster, cultivate, garner, bolster, elevate, unlock, empower, supercharge | use, help, get, raise, add — the plain verb |
| Vague attribution | industry reports, some critics/observers argue, experts say, studies show (no named source) | name the source, or drop the claim |
| Rhetorical parallelism | not just X but Y; not only X but also Y; it's not X, it's Y | state the one true thing |
| Canned openers/closers | in today's fast-paced/ever-evolving world, let's dive in, in conclusion, at the end of the day, ultimately, in essence, to sum up, it's worth noting that, it goes without saying | delete; start with the finding |
| Fake friendliness | I hope this helps, feel free to reach out, let me know if you have any questions | delete, or state what happens next |
| Faux-technical metaphor | falls out of, boils down to, comes down to, at its core, under the hood | state the mechanism directly |
| Wordy connectors | in order to, with respect to, on the basis of, due to the fact that, a large number of | to, for/about, from, because, the count |

### 4.3 Formatting tells

- No more than one em dash per output; prefer a period or comma.
- No emoji used as bullets or section markers.
- No title-case headings inside prose (use sentence case).
- Bold marks a defined term or a literal value, not emphasis for its own sake.

## 5. Writing rules

1. One main point per sentence (section 0.3). A sentence may carry the point's
   reason or consequence; separate points get separate sentences.
2. Active voice, you as subject: "I changed X", never "X was changed".
3. Count what is countable: "3 of 41 tests fail", never "a few tests fail".
4. Claim absence explicitly: if a required check did not run, say "I did not
   run <check>" — never imply completion by omission.
5. Files are `path:line` or `path:line-range`. Commands are literal, in
   backticks. Identifiers verbatim, in backticks.
6. Tried-trails: append-only, first person, past tense, one attempt per line:
   "I ran X; it failed with Y." A cold reader must be able to replay it.
7. Sentence length: aim for 25 words or fewer; 40 is the limit (section 0.3).
8. Section 0.2 governs word choice: plain descriptions over internal labels,
   one term per thing, concrete names, no noun sandwiches.
9. Simple present for what is; simple past only for a completed action or a
   tried-trail entry; "will" only inside a PLAN block. No rhetorical questions.

## 6. Canonical example

```
[RESULT verified]
Grant-scope check passes for all 3 roles.
evidence: `npm test -- grant.spec.js` exit 0, 17/17

[RESULT observed]
The demo page loads and issues a scoped token in Chrome 126.
evidence: `python3 -m http.server 8080` + manual load; token in console

[BLOCKER]
I cannot test the Firefox path.
tried: I installed firefox-esr; headless launch failed with `GLIBC_2.36 not found`.
tried: I pinned firefox 115; same failure.
needed: a base image with GLIBC >= 2.36, or waiver of the Firefox gate.

[QUESTION]
Options: (a) waive Firefox for M1, gate at M2 — recommended; (b) swap base image now.
default: (a), applied if unanswered at next session start.
blocked meanwhile: nothing; the M1 gate minus Firefox is satisfiable.
```

Anti-example 1 (formal block, original) — never write this:
> "Great news! Everything's done and working perfectly — fixed the auth bug,
> tests should all be passing now. Just a small tweak was needed!"

Violations: untyped prose, 5 banned words, 4 reserved words without a verified
claim, no evidence pointers, no counts.

Anti-example 2 (natural prose, wall-of-text) — never write this:
> "So I took a look at the auth flow, and it's worth noting that the codebase
> boasts a fairly intricate permissions system that plays a pivotal role in
> how requests are handled — it's not just validating tokens, it's also
> enforcing scope, and this underscores the importance of getting the
> middleware order right, which I've now addressed, and at the end of the
> day this should resolve the 403s you were seeing, though I'd stand behind
> the fix given the tests I ran."

Write instead:
> "The middleware ran in the wrong order. I fixed the order in
> [auth.ts:42](src/auth.ts:42). `npm test -- auth.spec.js` passes, 8/8."

Violations in the wall-of-text version: one 70-word sentence holding five
ideas, three AI-tell phrases (boasts, plays a pivotal role, underscores the
importance), one rhetorical parallelism ("not just... it's also"), one
confidence-theater phrase ("I'd stand behind"), one hedge ("should resolve"),
no evidence pointer, no file reference.

Anti-example 3 (compressed, the opposite failure) — never write this:
> "C3 blocked on the greedy-ref call. B8 waived; W1–W7 queued post-merge.
> Scope-by-transcription flagged. LAN un-waived, keyed bind, step 1."

Every sentence is short and no word is banned, yet the reader cannot act on it.

Write instead:
> "Stage 1 (the small hybrid-model test) is waiting for your decision on one
> question: may Quench pick a different token than MLX when its pick matches the
> high-precision reference? I recommend yes. Until you answer, Codex works on
> loading Bonsai 2 27B. I also told Codex to stop the image, audio and
> embedding work, because you dropped those features from the first version."

Violations in the compressed version: six internal labels with no description
(C3, B8, W1–W7, step 1, greedy-ref, keyed bind), one coined name
(scope-by-transcription), noun sandwiches, no reasons, and no statement of what
the reader needs to do.

## 7. Self-check before you send

Run this for every output, formal or not. Check one item at a time against the
whole draft, not everything in one read.

- [ ] A reader who was not watching would understand this message on its own
- [ ] The first lines say what it means for the reader, or what you need from them
- [ ] Every internal label is replaced by, or follows, a plain description
- [ ] No noun sandwiches; one term per thing; concrete names
- [ ] Each fact that needs a reason has one
- [ ] Sentences aim for 25 words; none exceeds 40
- [ ] Every sentence carries one main point
- [ ] Active voice throughout; you are the subject of your own actions
- [ ] No paragraph runs past 6 sentences without becoming a list
- [ ] Zero banned words (section 4.1), zero AI-tell phrases (section 4.2)
- [ ] No metaphor, idiom, or figurative language
- [ ] Zero exclamation marks, zero emoji, at most one em dash

For a qualifying formal output (section 0.1), also run:

- [ ] Every line lives inside one of the 8 block types
- [ ] Brief concerns use compact blocks; BLOCKER / QUESTION / ESCALATION /
      BLOCKS-RISK / formal handbacks use full blocks with their required fields
- [ ] Every factual claim has exactly one evidence class
- [ ] Every reserved word sits inside a `verified` claim with a resolving pointer
- [ ] Every QUESTION has a default; every BLOCKER has a tried-trail
- [ ] Everything the task's gate requires is either claimed or explicitly
      marked not-run
- [ ] Worst news is first

For a qualifying formal output, conformance is judged by a linter and a
separate checker, not by you. If any box fails, rewrite before sending.

---
ATTEST-100 Issue 0.3 · operative subset · full spec: attest-100-spec-001.md
· Issue 0.3 change (2026-10-11): added "Reader first" (section 0.2), which
outranks the style rules; relaxed the sentence cap to a 25-word aim and a 40-word
limit; allowed a sentence to carry its reason; retired the prose-exception tag;
added anti-example 3 for compressed, label-heavy output.
· Issue 0.2 change: split structure (threshold-gated) from style (always-on);
added global sentence/paragraph caps; added the AI-tell blocklist (section 4.2).
