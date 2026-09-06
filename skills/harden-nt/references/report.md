## Phase 6 — Covered or stopped

**Covered** when every path is hardened, every hardened path's check still goes red on re-run against its defect, and the last adversarial round added no new paths. Write it as what it is — *this map, fully hardened, as of this run* — not a permanent guarantee about a surface.

Otherwise **stopped**: the budget ran out, or three consecutive rounds hardened nothing while paths remain uncovered. Report the uncovered list either way.

## Phase 7 — The report

Write `plan/harden-YYYY-MM-DD.md` in ATTEST form: surface and tenant (Phase 0), the liveness probe (Phase 2), each round typed and dated, the map with every path's state (Phase 5), and the verdict:

```
Harden on <surface> — <N> rounds, <M> agents/round (<families>).
Map: <T> paths — <H> hardened, <E> exercised, <U> uncovered
Verdict: COVERED (map fully hardened, last adversarial round added nothing) | STOPPED (<budget|diminishing returns>)

Hardened this run:
  - <path> — fixed <SHA> — check red on <defect>, green on <fix>

Added by adversarial rounds:
  - <path> — found round <N> — <state>

Reopened:
  - <path> — broke again in round <N> — see prior proof

Uncovered:
  - <path> — <needs a human call | parked after two attempts>

Needs you: <anything a stop-line parked, or a design call Phase 4 couldn't make alone>
```

End by naming whether the surface is ready for `/live-check-nt` (one final deployed-artifact replay) or `/release-nt`, and note that an uncovered list feeds `/autopilot-nt` like any other fix-workplan.
