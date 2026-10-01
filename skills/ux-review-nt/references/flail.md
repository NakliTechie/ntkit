## Phase 3 — The flail

After the scripted walk, from the states it reached:

1. **Misclick as a confused newcomer would, then try to get back** to where you were or to something recognizable. The recovery is the measurement, not the misclick.
2. **Refresh after every state change that should be durable**, and check you land where you left off. An app that reopens on a different document than the one being written is a data-loss story to a newcomer even when the work is recoverable.
3. **Feed every ingest point the wrong artifact.** Wherever the app accepts data (a file picker, a paste target, an import dialog, a URL field), give it the wrong type, an empty file, a binary, something enormous. An importer that accepts a PNG through "CSV file…", invents rows and toasts *"Imported 3 rows"* is worse than a crash.
4. **Deny every permission** the app asks for, then keep going. A denied permission that leaves a broken screen with no re-ask is unrecoverable state.

**The finding class is recoverability, not crashes**: dead ends, lost work, unrecoverable state, traps, errors that don't say what to do. Crashes belong to the Phase 1 invariant set wherever they fire.

**Budget: ~30 interactions for the flail, plus up to 10 more to produce a clean repro of anything it surfaces.** Report both numbers. Expect 20-30 minutes, because each misclick needs a screenshot read and a follow-up probe to rule out a harness artifact. Declare the budget and yield, or the skip reason under the SKILL.md side-effect stop-line, whether or not it found anything.
