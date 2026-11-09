# Rules panel (optional): a checked model behind a process feature

Use this for a feature that is a process: several steps with rules about their order (a refund, an approval chain, a checkout, a sync with retries). Skip it for a feature that is one screen or one action. It needs Java and `tla2tools.jar` (the TLA+ tools); when either is missing, skip this phase and say so in the verify printout.

## Build the model

1. **States in the reader's words.** Write a small TLA+ module for the feature: one variable per thing the user can see change (`refund`, `parcel`), each with values named as the screen names them ("requested", "parcel back", "paid"), never as code variables.
2. **Actions as the user sees them happen.** One action per arrow: "customer ships the parcel back", "shop confirms receipt". Aim for about 20 arrows; when there are more, make the states coarser before adding arrows.
3. **Rules as invariants.** Each rule the product promises is one invariant with a one-sentence plain form: "No money before the parcel is back."
4. **Read the rules from the code, not from hope.** Each guard in the model points at the `path:line` that enforces it. A rule with no enforcing line is a finding for `/forward-pass-nt`, not a rule for the panel.

## Check it

- Run TLC over every reachable state: `java -cp tla2tools.jar tlc2.TLC -deadlock <Module>.tla` with a `.cfg` listing the invariants. Record the state count and the longest path: "checked 11 states, 9 steps; all 5 rules hold".
- **Break each guard on purpose.** For each rule, remove its guard in a copy of the model and rerun TLC. Record the counterexample length: "take away the parcel-back guard and it breaks in 2 steps". A rule that still holds with its guard removed is guarded by something else, or the guard is dead; find out which.
- A rule that fails on the real model is a bug: replay the counterexample against the running app before blaming the code, because the model is the likelier mistake. A confirmed failure goes to `/walkthrough-nt` as a finding, not into the guide.

## Show it

Add a **Rules** section to the feature's guide entry: each rule's plain sentence, the checked line ("checked: N states, M steps, all K rules hold"), and for each rule the steps to break it without its guard. Draw the flow as a statechart per [`charts.md`](charts.md). Commit the model and its `.cfg` under `guide/models/` and run TLC from `guide/regenerate.sh`, so a regenerated guide re-checks the rules.
