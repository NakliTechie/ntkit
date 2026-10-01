## Phase 4 — Map the IA + objective audit (surface-specific)

**IA map.** Enumerate the actual nav tree, its grouping logic (or lack of it), depth and orphans: the menu and settings tree on web and native, the subcommand or screen tree on CLI and TUI. **Only now**, after the cold walk and the flail, read the feature map (`verify/features/`, left by `/walkthrough-nt`) as a completeness check: a feature area the cold journey never surfaced is a discoverability finding. With no such directory, say under blind spots that the completeness check did not run.

**The audit may run earlier, in a throwaway context.** Machine output about contrast and layout shift does not contaminate the newcomer posture; the feature map does, so only the map waits.

**Web: Lighthouse.** Run `npx lighthouse@13 <url> --output=json --preset=desktop`, and again mobile-throttled; the CLI returns Accessibility, Best Practices and Performance in one pass. The Chrome DevTools MCP `lighthouse_audit` is the fallback; it omits Performance, so CLS and LCP then need a separate trace. Capture the scores and the top failing audits, and tie each a11y finding to the journey beat where it bites.
- Add the a11y checks a newcomer hits: keyboard-only traversal of the first-run flow, visible focus, color contrast, tap-target size. Tie each finding to the beat where it bites.
- An a11y score is a floor, never a verdict of "accessible". Report the score and what it doesn't cover (focus order, skip-link targets, traps).
- Measure CLS on a throttled mobile viewport; desktop-unthrottled hides it. Report both when you have both.

**CLI: a scripted health check.** Report the fraction of subcommands that answer `--help` with exit `0` and non-empty output. Judge the responses to canned bad inputs (missing argument, unknown flag, nonexistent path), time `--version` and the first real command, and spot-check exit codes. Report the message-quality call as judgment, not a score.

**TUI: a checklist, not a score.** Quit key shown or discoverable (in how many keypresses), keybinding legend on every screen, live resize and 80 columns without garbling, sane output under `NO_COLOR` and `TERM=dumb`. Report each as yes/no/partial with the screen checked.

**Native: iOS has the one real automated a11y audit outside the browser.** Run `XCUIApplication().performAccessibilityAudit()` through `xcodebuild test` or an XCUITest target. macOS has no equivalent: query the accessibility tree (`mcp__computer-use__app_ax_find`) per screen for real names and roles, and label it a checklist-grade proxy. Performance on either: cold-launch-to-first-interactive time, plus idle memory if the tooling can read it.
