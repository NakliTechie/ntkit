## Phase 1 — Identify the roles

**Read the feature map first, if one exists.** A prior walkthrough leaves `verify/features/` next to the harness (Phase 4.5) — an index plus one file per feature area: what exists, how a user reaches it, how to drive it, what usually lies. Start from it and verify it against the code, instead of re-deriving the whole cast; where the map and the code disagree, that drift is a finding to fix in the map, never silently absorbed.

Derive the cast of users from the **code**, not from guesses. Look for:
- **Auth / RBAC** — role enums, permission/policy tables, route guards and middleware, `if (user.role === …)` / `can?()` / `@requires_role`, plan/tier feature flags.
- **UI that forks by role** — role-gated nav, menus, components, admin-only screens.
- **Seed data, fixtures, test users** — and any existing logins you can reuse.
- **Docs** — README / handoff personas.

Always include two roles the code rarely names explicitly but every real user passes through:
- **Anonymous visitor** — unauthenticated; landing, signup, public pages, and the auth wall itself.
- **Brand-new user with zero data** — the **first-run** path. This is literally a new user's first action and is the least-exercised flow in daily dev (which always runs against existing data), so it's where silent breakage hides.

Produce a **role inventory**: for each role — name · how it authenticates · what it can reach · the credentials or seed to enter as it. Try seed/fixture/test credentials first; if a role still can't be entered, **ask the user** — credentials are an unanswerable, and never invent or hardcode auth. Otherwise announce the inventory and drive — the report's coverage map is the accountability, not a pre-approval.

## Phase 2 — Map each role's journeys

For each role, list the **features/flows to exercise** — entry-points first, following the real flows a user of that role would take. Build a per-role checklist, e.g.:
- *admin*: invite a user → change a setting → read the audit log → revoke access
- *member*: sign up → **create your first <thing>** → edit it → delete it → log out and back in
- *anonymous*: land → sign up → hit a protected URL and get bounced

Mark the **first-run / empty-state** journeys explicitly — they get tested deliberately, not skipped. `$ARGUMENTS` narrows this to one role or one flow.
