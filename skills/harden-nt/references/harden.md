## Phase 4 — Harden: fix, then prove the check bites

For each failing path, in order:
1. **Fix it** — the smallest change against the surface's actual contract, same discipline as `/autopilot-nt` Phase 2.
2. **Leave a check behind.** The fix is half the work; the path is not hardened until something will catch its return.
3. **Prove the check can fail — before believing it can pass.** Deliberately reintroduce the defect (revert the fix, or hand-craft the bad input again) and confirm that specific check goes red. Only then run it against the real fix and confirm green. A check green through both is not a check — find the real cause and rewrite it; don't note the anomaly and move on.
4. **Commit it** — one focused commit per path.
5. **Log it** in `plan/harden-<date>.md`: the path, the fix SHA, and the proof (what red looked like, what green looks like now). The path moves to **hardened**.

A path two honest fix attempts cannot close is parked, not forced — `/autopilot-nt` Phase 3 discipline.
