# Notes — clue-board

## Verification results (2026-11-28)

- Render check (2.4): desktop window 640×360, seed 1 (all 5 facts of that case revealed;
  the template has at most 5 per run, so "6+ cards" was not reachable). Board opened over
  the viewer: the tray scrolls with a visible scrollbar, cards show their full text and
  source, 月次締め and 締め draw as glyphs, the office clock stays visible above the board.
  With three cards pinned and two links, the links draw as red lines under the cards.
- Test gotcha: GUT's own output panel covers the root viewport, so simulated clicks there
  hit GUT, not the game. The "click does not reach the viewer" test runs its room in a
  SubViewport and has a control case that proves the same click presses the button when
  the board is closed.
- GUT (4.1): full suite headless, 39 scripts (33 before + 6 new), 291/291 passing, no GUT
  warnings, no skipped scripts.
- Web export (4.2): exit 0.
- Web walk-through (4.3): passed in Chrome on a fresh export. C on the briefing did nothing;
  C in the office opened the empty board ("No clues found yet.") and C closed it. Seed
  88818: read all five documents (only the ticket held a fact), C over the viewer showed
  the Ticket card with source "Ticket", one Esc closed only the board and the viewer stayed
  open. Same over Linh's dialogue. Seed 36908: Trang revealed two facts; pinned both,
  dragged one, linked them (red line), clicked the pair again to unlink, relinked, unpinned
  the linked card with × (back to the tray, line gone), Esc returned to Trang's panel.
  "×" draws on web. Console: no errors or warnings. In seed 88818 only one fact was
  reachable because Hana and Minh have no dialogue yet; that is the Truth Sheet, not a
  board bug.
- Found, not in this change: the dialogue panel's asked mark "✓" draws as a missing-glyph
  box on web (the JP font subset has no U+2713 and the web build has no system fallback).
  Pre-existing from `npc-dialogue-offline`.

- Code review: no critical/high. Fixed the three MEDIUM findings (link ends refreshed when
  a pinned card settles its height; a lost mouse release no longer leaves a card stuck to
  the cursor; focus moves to the next Pin button or Close after pin/unpin/reveal) and three
  LOW ones (a new pin reuses a freed grid slot; the pin clamp uses the pinned width; typed
  `links()`). Added 6 tests; full suite 297/297 after the fixes, web export exit 0.
  Kept as known LOW: pinned positions are not re-clamped if the board area resizes (the
  viewport is fixed at 640×360); drag tests call `_gui_input` directly.

- Antigravity QA (2026-11-28): tested the web build against the acceptance criteria in
  `specs/clue-board/spec.md`; passed with no issues (reported by Harry).

## Devlog

- 2026-11-28: proposed and built the clue board: cards for revealed facts, tray, pin, drag,
  link/unlink, unpin; opens with C anywhere in the office, also over the viewer and dialogue.
- Board rules live in a pure `ClueBoardState` on `GameState`, so the report screen can read
  pins later; one Esc closes only the board thanks to sibling order in the office scene.
- Lesson: GUT's output panel covers the root viewport, so click tests need a SubViewport and
  a control case, or they pass without testing anything.
