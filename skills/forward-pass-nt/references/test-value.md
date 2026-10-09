# Test-value lens — hunting classes and the retention bar

Adapted from openclaw's `test-audit` skill (`.agents/skills/test-audit/` in
[openclaw/openclaw](https://github.com/openclaw/openclaw)), paraphrased. Its campaign found 9 real
coverage gaps behind cuts that looked safe, so this lens recommends and never deletes.

Read the whole test and the code it claims to cover, including how CI routes it. Judge a test by its assertions, not its name: a test named for clearing a window can assert the window was *not* cleared.

## Hunting classes

- **Assertion-free** — asserts nothing, or only that nothing threw.
- **Self-fulfilling** — the expected value comes from the code under test; a self-comparison.
- **Mock-as-subject** — the mock or fixture implements the asserted behaviour, or hands the code
  what the real owner should produce; persistence asserted against a store the real path never writes.
  Also any mock of an in-process or local-substitutable dependency (categories below).
- **Mirror tests** — a copied fixture, manifest, or export list, or a source grep that breaks on a
  rename and survives a behaviour change.
- **Implementation-coupled** — asserts private call shape already covered at a real boundary; it
  breaks under a behaviour-preserving refactor.
- **Duplicate proof** — the same contract proved again at another layer with no new risk.
- **Test-only seams** — a production export, flag, hook, or parameter that only tests use. Not an
  injection point for an owned-remote or third-party dependency: production's real adapter is its
  caller, even when production takes the default.
- **Flag restatement** — re-reads a declared capability flag instead of exercising what it promises.
- **Vacuous negative** — a rejection test that passes because a different guard fires or the
  branch is never reached.
- **Regression that never went red** — added with a fix, with no record of failing on the pre-fix
  code (`SUBSTANCE.md` §6.3). Always an `F` (reintroduce the defect, record the red, repair the
  test if it stays green), never a `D`.

## Dependency categories — which stand-in a test may use

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills) `codebase-design/DEEPENING.md`,
MIT. The category of what the code under test depends on decides the legitimate stand-in.

1. **In-process** — pure computation, in-memory state, no I/O. Run the real code; no stand-in.
2. **Local-substitutable** — a dependency with a local stand-in: SQLite or PGlite for a database,
   a temp directory for a filesystem, a local server. Run the stand-in; no mock.
3. **Owned remote** — your own service across a network. Inject it as a port; tests use an
   in-memory adapter.
4. **Third-party** — a service you don't control (payments, mail, a model API), plus the clock and
   randomness. Inject it as a port; tests use a mock adapter.

A mock in categories 1–2 is Mock-as-subject. A port in categories 3–4 is a real seam with two
adapters, never a Test-only seam.

## Retention bar — keep, even when a class above matches

- It independently guards a public API, SDK, protocol, config, migration, storage, security,
  platform default, prompt-byte, package, release, or architecture contract.
- Call order is observable behaviour.
- It is a regression test with a credible failure mode.
- A source inspection is the cheapest independent guard: it breaks when the user-facing key,
  byte, or path changes and survives an identifier-only rename.
- It fails on the current code. That is a possible product bug: file it under Bugs, not as a
  test to delete.

Slow, static, or "E2E probably covers it" is not a removal reason. Coverage elsewhere counts only
when you can name the keeper test and the assertion in it.

## Recording a finding

Each `T` finding carries one recommendation and its evidence:

- `D` delete — name the keeper that still proves the contract; or, when the test guards nothing
  (an assertion-free probe, a self-comparison), state that and name the mutation that leaves it
  green, which is the proof;
- `C` consolidate — name the owner that absorbs the assertion (a table case, a stronger suite);
- `F` fix the assertion — the contract is real, the check is vacuous;
- `seam` — the test-only production seam its removal unlocks.

Add the non-test callers of any seam, and the focused command that runs the keeper. A candidate
missing both a keeper and a guards-nothing mutation, or missing its command, goes to
**Worth a look**, not to `T`.
