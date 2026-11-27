# Notes — artifacts-viewer (part 1)

## Verification results (2026-11-28)

### GUT (task 5.1)

Full suite headless: 25 scripts, 149 tests, 149 passing, 0 failures, no script warnings.
New tests: fact discovery 11, run-flow +3, documents 8, font coverage 4, viewer 11, office
viewer 5, run + viewer 2. `test_player_interaction` was updated: it now closes the viewer
after interacting with the shelf, because the shelf freezes the player while reading.

### Desktop render (task 4.4)

Viewer at 640×360 with seed 42 → Meeting notes: はい renders, long text scrolls, the office
clock stays visible above the viewer.

### Web build (tasks 5.2, 5.3)

- Export exits 0. Console after Start: `[case] seed 965593`, no root cause in the log.
- Walking works on web, but the agent's browser pane was hidden, so the game only drew a
  frame per screenshot and walking all the way to the shelf was not practical.
- To check the web-only risks (font, viewer), a temporary build opened the viewer on Meeting
  notes at Start with seed 42 (edits reverted before commit). On web: はい renders as a
  Japanese glyph, a mouse click opens Chat log, Esc closes the viewer and returns to the
  office, the clock stays visible. No console errors (only the known zero-size WebGL
  warnings of a hidden pane).

### Implementation notes

- "Clock keeps running" is tested with a 1 s wait instead of 5 s to keep the suite fast; it
  checks the clock lost the measured wall time (±0.25 s).
- Font: the official source is the variable `NotoSansJP[wght].ttf` (9.6 MB), pinned to
  weight 400 and subset to 303 KB. Output is `.ttf`, not `.otf` (design updated). Rebuild
  script: `tools/subset_jp_font.py`, commands in `game/fonts/README.md`.
- Code review fixes: the viewer disables its documents (instead of crashing on click) if the
  filler file is missing; a test checks the player can interact again after closing the
  viewer; the clock timing test tolerance is 0.25 s. The font's name table said "Thin"
  after pinning weight 400; rebuilt with `updateFontNames=True`, now "Noto Sans JP
  Regular". The OFL reserved name "Source" is not used as a font name (only in the kept
  copyright and trademark notices).
- Filler lines are written in the same prose style as the facts, so line formatting does
  not give away which lines are facts.

### Not done yet (task 5.4)

The scenario walk-through on a **visible** web build (walk to the shelf, read all three
documents, Esc, time up while reading) needs a person watching. Every scenario is covered
by GUT tests.

## Devlog

- 2026-11-28: Start now generates a seeded case; the Document Shelf opens a viewer with
  Ticket / Chat log / Meeting notes built from the Truth Sheet, and reading reveals facts.
- Added a 303 KB Noto Sans JP subset so Japanese renders on web; 149/149 GUT tests pass.
- Visible web walk-through (task 5.4) left for Harry / Antigravity.
