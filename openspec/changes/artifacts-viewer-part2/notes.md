# Notes — artifacts-viewer-part2

## Verification results (2026-11-28)

- GUT (4.1): full suite headless, 33 scripts, 230/230 passing, no GUT warnings.
- Part 1 documents unchanged: ticket, chat log and meeting notes hash the same for seeds
  1–300 as on `main` (`tests/fixtures/artifacts/part1_document_hashes.json`).
- Font (1.6): subset rebuilt from the official Noto Sans JP for the new JP spec filler;
  308 KB (was 303 KB).
- Render check (2.4): desktop 640×360, Spec document (seed 4, JP fact in the Japanese
  original section) and Git log; text fits, scrolls, 月次締め and 日本語原文 draw as
  glyphs, the clock stays visible. Headings show as plain lines (styling left to the art
  pass).
- Web export (4.2): exit 0.
- Found while running the suite: `test_run_viewer.gd` stopped parsing after
  `_open_viewer()` gained a parameter, and GUT only printed "does not extend GutTest" and
  skipped it. Fixed the call; its 2 tests run again.

- Code review: no critical/high findings; fixed two vague loader messages and a magic
  seed fallback. Kept as known LOW: the terminal log-line test checks the format, not a
  printed line (same as the shelf in part 1).
- Web walk-through (4.3): pending; the build runs and shows the PC Terminal, but the
  Browser pane was hidden so the game loop paused before the walk-through.

## Devlog

- 2026-11-28: Proposed part 2 of `artifacts-viewer` (issue #6): Git log and Spec document
  (revision history, JP original, EN translation), PC Terminal as a second entry point.
- Spec document uses data-driven sections; display order is split from the RNG seed index
  so part 1 documents keep the same text per seed.
- Two follow-up questions (Linh, Trang) unlock from part 2 facts; waiting for Harry's review.
- 2026-11-28 (apply): Git log and Spec document (three sections) are readable from the
  shelf and the new PC Terminal; part 1 documents keep their text per seed.
- Two follow-ups (Linh, Trang) unlock from reading; 232 GUT tests pass, web export OK.
- A renamed helper had silently disabled `test_run_viewer.gd`; fixed and noted.
