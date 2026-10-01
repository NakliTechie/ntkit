## Phase 5 — Build the single-file guide

The builder reads the captures and caption data and emits one self-contained `guide/index.html`:
- **Structure**: header and intro · a **TOC** · one section per surface (only if `mixed`) · one **role section** per role · **feature subsections** inside each, every feature = capture + caption (title + one-line "what this is"). A single-role app drops the role wrapper.
- **Card type follows the capture, not the backend.** A PNG (`browser`, `native-macos`) renders as an **image card** with the lightbox. A transcript (`cli`) renders as a **terminal card**: `<pre>` with ANSI SGR codes converted to inline spans by a small vanilla-JS parser, styled as a terminal window (traffic-light dots, monospace, dark by default).
- **Theme from the app's own design tokens** where they exist: for a `browser` surface, build the guide's chrome from the app's `:root` custom properties and font stack, so it reads as part of the product. A pure-CLI guide uses the terminal theme.
- **Relative asset paths**: reference `screenshots/<role>/…` and `transcripts/<role>/…`, and link back into a `browser` app via a `../`-style base, so the guide works opened as a file or served from any host.
- **Inline search.** A sticky search box that filters live:
  - Give each card a `data-search` attribute = lowercased `role + feature title + caption + slug`; a terminal card also folds in the command text.
  - On input: lowercase the query, toggle a `.hidden` class per card by `data-search.includes(query)`, hide sections left empty, show a "no matches" note when nothing matches.
  - `/` focuses the box, `Esc` clears it.
- **Lightbox, image cards only.** Every screenshot opens full-size in an in-page overlay with its caption below, never a bare `<a href="img">` that navigates away. Terminal cards expand to full width in place instead.
  - **Open/close**: click or tap opens; `Esc`, a visible `×` button, and a click on the backdrop close it. Closing restores scroll position.
  - **Navigation**: `←`/`→` step to the previous/next screenshot in guide order (skipping search-hidden and non-image cards); `↑`/`↓` jump to the first screenshot of the previous/next feature section. On-screen prev/next arrows mirror the keys, with a `role · feature — N/M` position line.
  - **Mobile**: swipe left/right = prev/next, swipe down = close, pinch-zoom on the image not blocked, on-screen controls ≥44px, image letterboxed to the viewport (`max-width/max-height: 100%`, `object-fit: contain`).
- **Responsive**: usable at 375px.

Inline all CSS and JS, with no dependencies and no remote scripts: the guide is one portable file plus its `screenshots/` and `transcripts/` folders.
