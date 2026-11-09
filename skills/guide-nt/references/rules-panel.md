# Rules panel (optional): a checked model behind a process feature

Use this for a feature that is a process: several steps with rules about their order (a refund, an approval chain, a checkout, a sync with retries). Skip it for a feature that is one screen or one action. The checker is `$SKILL/bin/statecheck.py`: Python standard library, nothing to install.

## Build the model

Write `guide/models/<feature>.py` with `init()`, `actions(s, g)`, `RULES` and `GUARDS` (the format is in the checker's docstring):

1. **States in the reader's words.** One key per thing the user can see change (`refund`, `parcel`), each with values named as the screen names them ("requested", "parcel back", "paid"), never as code variables.
2. **Actions as the user sees them happen.** One action per arrow: "customer ships the parcel back", "shop confirms receipt". Aim for about 20 arrows; when there are more, make the states coarser before adding arrows.
3. **Rules as plain sentences.** Each rule the product promises is one `RULES` entry: "No money before the parcel is back".
4. **Guards from the code.** Wrap each condition the code enforces as `g("<guard name>", condition)`, and name the `path:line` that enforces it in a comment. A rule with no enforcing line is a finding for `/forward-pass-nt`, not a rule for the panel.

## Check it

- `python3 $SKILL/bin/statecheck.py guide/models/<feature>.py --break-guards` walks every reachable state and prints "checked: N states, M steps, all K rules hold", then, for each guard switched off alone, the rule that breaks and in how many steps.
- A guard whose removal breaks nothing is covered by another guard, or dead: find out which.
- A rule that breaks on the real model is a bug: replay the printed path against the running app before blaming the code, because the model is the likelier mistake. A confirmed failure goes to `/walkthrough-nt` as a finding, not into the guide.

## Show it

Add a **Rules** section to the feature's guide entry: each rule's plain sentence, the checked line, and for each guard the steps to break its rule without it ("take away the parcel-back guard and it breaks in 1 step"). Draw the flow as a statechart per [`charts.md`](charts.md). Run the checker from `guide/regenerate.sh`, so a regenerated guide re-checks the rules.
