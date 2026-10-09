## Phase 1 — Identify the roles

**Read the feature map first, if one exists.** A prior walkthrough leaves `verify/features/` next to the harness (Phase 6): an index plus one file per feature area saying what exists, how a user reaches it, how to drive it, and what usually lies. Start from it and verify it against the code instead of re-deriving the cast. Where the map and the code disagree, the drift is a finding to fix in the map, never silently absorbed.

Derive the rest of the cast from the code, not from guesses. Always include two roles the code rarely names:
- **Anonymous visitor**: landing, signup, public pages, and the auth wall itself.
- **Brand-new user with zero data**: the first-run path.

Produce a **role inventory**: for each role, its name · how it authenticates · what it can reach · the credentials or seed to enter as it. Try seed, fixture and test credentials first; if a role still can't be entered, **ask the user**. Never invent or hardcode auth. Otherwise announce the inventory and drive; the report's coverage map is the accountability, not a pre-approval.

## Phase 2 — Map each role's journeys

For each role, list the flows to exercise, entry points first, following the real paths a user of that role takes. Mark the **first-run / empty-state** journeys explicitly; they get tested deliberately, not skipped.
