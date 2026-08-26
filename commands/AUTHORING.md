# Authoring a command

Every `-nt` command is a prompt with a contract. This file is the standard for
writing a new one — and the checklist for reviewing a change to an existing one.
It exists because twenty commands drifting apart in shape is how a kit rots; one
shape is how they stay composable. (The six-point idea is ported from the
built-in-skill standards in [osolmaz/pi-workflows](https://github.com/osolmaz/pi-workflows),
folded into ntkit's own doctrine.)

The three pillars bind what a command *does*: it transitions state per
[`STATES.md`](../STATES.md), reports per [`ATTEST.md`](../ATTEST.md), and delivers
per [`SUBSTANCE.md`](../SUBSTANCE.md). This file binds how a command is *written*.

## 1. Declare the contract in frontmatter

Non-negotiable — it is STATES guard #1. Every command's frontmatter carries:

- `description` — one line: what it does **and its side effects** (auto-applies? drafts only? pushes?).
- `argument-hint` — the shape of `$ARGUMENTS`, with an example.
- `allowed-tools` — the smallest set the command actually uses. A read-only command lists no `Write`.
- `entry` — the state + artifacts it requires. If they are absent the command says so and stops; it never proceeds politely.
- `exit` — the **machine-checkable** condition that means it finished. Not "did the work" — the check that proves it.
- `writes` — every `plan/` file it touches, or `nothing`.

`entry` / `exit` / `writes` are what make the state table enforceable instead of
decorative. A command that cannot state its exit as a check does not have one yet.

## 2. Document every input that changes behavior

For each input — in `$ARGUMENTS` or an env var — that affects **scope, authority,
safety, routing, or completion**, name it in the body with its **default**. An
input whose default the reader cannot find is a trap. Prefer a safe default the
command *announces and logs* over an input it *polls the user* for (guard #4).

## 3. Authority is opt-in — default-deny

Any power to act irreversibly on the world — **push, merge, release, deploy,
delete, send, post, spend** — is granted per run and **defaults to denied when
unstated**. A command never assumes it. Reversible, in-repo work (edit, commit to
a branch, write `plan/`) needs no grant. This is the authoring face of STATES
guard #4: the safe default for outward-facing power is *off*, and the command asks
or refuses rather than assuming yes. `/maintain-nt` models it — the sweep is
read-only, only the *reversible* safe class auto-applies, and anything that can
break you defers to `/autopilot-nt`.

## 4. One complete, valid example

Give at least one invocation the reader can copy, with obvious placeholders
(`<repo>`, `<message>`), that would actually run start to finish. An example that
omits a required input teaches the wrong shape.

## 5. Assemble input before you act

Gather every required input first, validate, then execute. Do not half-run and
stop in the middle to ask for what you could have checked up front. The one time
to ask is when a required input is missing and *underivable*, or the action is
outward-facing — guard #4.

## 6. Guard the state, don't nest actors

- Declare which states the command is legal in (the STATES table) and refuse on entry-fail **with the reason**.
- Do not launch a second long-running actor (`/autopilot-nt`, `/lab-nt`) inside the same worktree — the actor rule is one run per worktree, mailbox-only. Compose by **handoff artifact**, not by nesting.
- A guard yields only to a logged `/decide-nt` override — bypassed on purpose with a reason, never by drift.

## 7. Keep it lean

The smallest command that fully meets the need, no speculative flags. `/notify-nt`
is the floor — one job, best-effort, never blocks. If a new capability is a
variant of an existing command, **extend it**; a twenty-first command must earn
its slot against the minimal-tooling rule.

## Checklist

- [ ] Frontmatter: `description` · `argument-hint` · `allowed-tools` (minimal) · `entry` · `exit` (a check) · `writes`
- [ ] Every scope / authority / safety / routing / completion input documented with a default
- [ ] Outward-facing authority defaults to denied; reversible work assumed
- [ ] One complete, copyable example with obvious placeholders
- [ ] Required input assembled up front; asks only at the unanswerable or outward-facing
- [ ] Legal states declared; entry-fail refuses; no nested actors
- [ ] Reports in ATTEST, delivers per SUBSTANCE, transitions per STATES
- [ ] Earns its place against minimal-tooling — extend before you add
