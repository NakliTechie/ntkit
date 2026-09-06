## Phase 6 — Verify + report

Don't ship a guide you haven't looked at:
- **Serve `guide/` and open it.** Confirm image captures load (not blank) and terminal captures render with ANSI colors intact (not raw escape codes), the **inline search** filters correctly (type a feature or command name → only matching cards remain; `Esc` restores), and TOC anchors jump.
- **Exercise the lightbox on image cards** — open a screenshot, arrow through prev/next (`←`/`→`) and section jumps (`↑`/`↓`), confirm the position line updates and `Esc`/backdrop close it, and that navigation skips terminal cards and search-hidden cards.
- **Check it on a phone viewport** — mobile emulation (~375px): guide readable, search usable, lightbox opens on image cards, swipe left/right navigates, swipe down closes, pinch-zoom works on images, terminal cards scroll horizontally without breaking layout.
- **Print:** roles × features covered per surface, total screenshots + transcripts, any `empty`/`fail`/console-error/non-zero-exit routes (the blind spots), and the path to the guide.
- **Shipping:** unlike `plan/`, the guide is meant to be committed. Screenshots can be large — respect `.gitignore`/`.assetsignore` and let the user decide whether to commit images or host them. Don't push; `/windup-nt` ships it.

End by naming where the guide is, which surfaces it covers, what was (re)captured, any broken screens/commands worth a `/walkthrough-nt`, and — for an update — that you edited the generator + regenerated, not the HTML.
