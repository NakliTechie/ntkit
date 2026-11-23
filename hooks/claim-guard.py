#!/usr/bin/env python3
"""Claude Code Stop hook: enforce SUBSTANCE item 20 (claim past its evidence).

Blocks the end of a turn when the final reply says "done", "fixed", "passing" or "works" about
files the turn edited, and no check ran after the last edit. Exit 2 sends the message on stderr
back to the agent, which then runs a check or downgrades the claim. Exit 0 lets the turn end.

Input: the hook JSON on stdin ({"transcript_path": ..., "stop_hook_active": bool}).
A check that returned an error does not count, and edits to .md and .txt files are ignored.
Known limits: edits made through Bash (sed -i, cat >) are not seen, and the check pattern is a
heuristic that also matches commands such as `git check-ignore`. Reads the transcript only; writes nothing. One block per turn: when `stop_hook_active` is true
the hook already fired, so it exits 0 and never loops.

Install (optional), in the agent's settings.json:
  "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "python3 -I /path/to/claim-guard.py"}]}]}
"""
import json
import re
import sys

EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
# Prose files need no test, so editing them never requires a check before a claim.
PROSE_SUFFIXES = (".md", ".txt")
# A shell command that can vouch for an edit: a test, build, lint, type-check or run.
CHECK_CMD = re.compile(
    r"\b(test|pytest|jest|vitest|unittest|check|lint|build|make|cargo|tsc|mypy|ruff|verify|"
    r"run\.sh|npm run|npx|pnpm|yarn|go (test|vet|build)|python3? \S+\.py|sh \S+|bash \S+)\b"
)
CLAIM = re.compile(
    r"\b(fixed|done|passing|passes|passed|works|working|verified|resolved|all tests pass|no regressions)\b",
    re.IGNORECASE,
)
# "not yet verified" and "isn't done" state the opposite of a claim, so drop them before matching.
NEGATED = re.compile(
    r"\b(not|never|isn't|aren't|hasn't|haven't|wasn't|n't)\s+(yet\s+)?(been\s+)?(%s)\b" % CLAIM.pattern[3:-3],
    re.IGNORECASE,
)


def blocks(entry):
    msg = entry.get("message")
    content = msg.get("content") if isinstance(msg, dict) else None
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    return content if isinstance(content, list) else []


def main():
    try:
        hook = json.load(sys.stdin)
    except ValueError:
        return 0
    if hook.get("stop_hook_active"):
        return 0
    path = hook.get("transcript_path")
    if not path:
        return 0
    turn = []  # events of the current turn: [kind, payload, tool_use id]; kind is edit, check or text
    check_ids = {}  # tool_use id -> its event, so a failed result can cancel the check
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                kind = entry.get("type")
                if kind == "user":
                    bs = blocks(entry)
                    if any(b.get("type") == "text" for b in bs) and not any(
                        b.get("type") == "tool_result" for b in bs
                    ):
                        turn = []  # a new user message starts a new turn
                        check_ids = {}
                    for b in bs:
                        if b.get("type") == "tool_result" and b.get("is_error"):
                            event = check_ids.get(b.get("tool_use_id"))
                            if event:
                                event[0] = "failed-check"  # a check that errored vouches for nothing
                elif kind == "assistant":
                    for b in blocks(entry):
                        if b.get("type") == "tool_use":
                            name, inp = b.get("name"), b.get("input") or {}
                            if name in EDIT_TOOLS:
                                target = str(inp.get("file_path", ""))
                                if not target.lower().endswith(PROSE_SUFFIXES):
                                    turn.append(["edit", target, b.get("id")])
                            elif name == "Bash" and CHECK_CMD.search(str(inp.get("command", ""))):
                                event = ["check", inp.get("command", ""), b.get("id")]
                                turn.append(event)
                                check_ids[b.get("id")] = event
                        elif b.get("type") == "text":
                            turn.append(["text", b.get("text", ""), None])
    except OSError:
        return 0
    last_edit = max((i for i, (k, _, _) in enumerate(turn) if k == "edit"), default=-1)
    if last_edit < 0:
        return 0
    if any(k == "check" for k, _, _ in turn[last_edit + 1 :]):
        return 0
    final = next((p for k, p, _ in reversed(turn) if k == "text"), "")
    hit = CLAIM.search(NEGATED.sub("", final))
    if not hit:
        return 0
    edited = sorted({p for k, p, _ in turn if k == "edit" and p})
    sys.stderr.write(
        "claim-guard: the reply says '%s', but no check ran after the last edit to %s. "
        "Run a check on the edited state and cite it, or restate the claim as 'changed, not yet verified'.\n"
        % (hit.group(0), ", ".join(edited[:3]) or "the edited files")
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
