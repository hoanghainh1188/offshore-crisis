# Notes — artifacts-viewer-part2

## Verification results (2026-11-28)

- GUT (4.1): full suite headless, 33 scripts, 232/232 passing, no GUT warnings (final
  count, after the `test_run_viewer.gd` fix and the PR #23 review fixes).
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
  skipped it. Fixed the call; its 2 tests run again. Logged in
  `ai-failures/2026-11-28-test-script-silently-skipped.md`.

- Code review: no critical/high findings; fixed two vague loader messages and a magic
  seed fallback. Kept as known LOW: the terminal log-line test checks the format, not a
  printed line (same as the shelf in part 1).
- Web walk-through (4.3): passed in Chrome on a fresh export. Opened the viewer from the
  Document Shelf and the PC Terminal (heading names the source, same five documents in
  order), read Git log (it held `fact_coc_no_ticket` this run) and Spec document (日本語原文
  and the JP lines draw as glyphs, the body scrolls via the scrollbar), then Linh listed the
  "No ticket was ever made..." follow-up and answered it (holds answer, clock +15 min).
  Esc closed the viewer and the dialogue. Console: the three `[interact]` lines, no errors.
  The in-app Browser pane throttles timers to ~1 fps, so it cannot run the game loop.

- Antigravity QA (2026-11-28): tested the web build against the acceptance criteria in
  `specs/`; no issues found.
- PR #23 review fixes:
  - Linh's honest "does not hold" answer to the no-ticket follow-up no longer points at the
    chat log, since Tanaka-san can hold `fact_coc_chat_agreement`.
  - Linh's follow-up says "that export change" instead of naming the closing period.
  - The chat log artifact is titled "Shared chat: #kazegumo-project" to match the
    "shared chat" wording in facts and dialogue. Fact lines are unchanged, so the part 1
    hash fixture still matches.
  - `tests/tools/regen_part1_hashes.gd` regenerates the part 1 hash fixture; it reproduced
    the committed file exactly. Run it only when part 1 text is changed on purpose.
  - Kept for later (separate issues): per-holder phrasing of fact lines (the git log line
    reads as a conclusion), a CI workflow that fails on unparsed test scripts, and a
    content rule/test for honest "does not hold" answers.

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
- 2026-11-28 (4.3): web walk-through passed in Chrome: both entry points, JP glyphs and a
  follow-up unlocked by reading the git log, no console errors.
- 2026-11-28 (review): fixed Linh's honest answer and follow-up wording, renamed the chat
  log to "Shared chat", added a hash-fixture regen script and logged the silent test skip.
