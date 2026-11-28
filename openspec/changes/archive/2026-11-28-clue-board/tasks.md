# Tasks

## 1. Board state and card content

- [x] 1.1 Write failing GUT unit tests for `ClueBoardState` (design Decision 1): `tray_ids()` follows reveal order and drops pinned ids; `pin()` refuses ids that are not revealed; pin → unpin returns the card to its reveal-order tray place and removes its links and selection; `select(A)` then `select(B)` links, either order again unlinks, one link per pair; `select(A)` twice links nothing and clears the selection; selecting a tray id does nothing; `move()` keeps the new position; pins and links never change `revealed_fact_ids` or the office time; verify they fail (RED)
- [x] 1.2 Implement `game/clue_board/clue_board_state.gd`; verify the tests in 1.1 pass (GREEN)
- [x] 1.3 Add `GameState.clue_board`, replaced in `reset_run()` and `start_case()`; extend `test_game_state.gd` with "new run after pins and links → no pins, no links"; verify it passes
- [x] 1.4 Write failing GUT tests for `ClueCard.from_fact()` (Decision 2): an `npc:hana` holder gives "Hana", `artifact:git_log` gives "Git log", text equals the Truth Sheet text for chain facts and red herrings, an unknown holder falls back to the raw string; for seeds 1–300 every fact in the Truth Sheet gets a non-empty label; then implement it and verify the tests pass
- [x] 1.5 Add the static clamp helper (Decision 4) with unit tests: a card dragged past any edge stays fully inside the board area; verify they pass

## 2. Board scene

- [x] 2.1 Build `game/clue_board/clue_board.tscn` / `clue_board.gd` on layer 6 (Decision 3): header with count and Close, scrolling tray with Pin buttons, board area, "No clues found yet." empty text, viewer theme for the JP font; write GUT tests that with revealed `A`, `B` the tray lists `A` then `B` with their text and source label, the empty run shows the empty text, a reveal while open adds a tray card at once (Decision 6), and Pin moves a card from the tray to the board area; verify they pass
- [x] 2.2 Add pinned-card input (Decision 4): drag past the threshold moves and clamps, click selects/links/unlinks, × unpins, links drawn between card centres; write GUT tests driving these with simulated mouse events (drag moves the card and the link end follows; click A then B makes a link; × on a linked card removes it and its link); verify they pass
- [x] 2.3 Add the `clue_board` input action (physical key C) to `project.godot`; write GUT tests that the action toggles the board, Esc and Close close it, and focus returns to the control focused before opening; verify they pass
- [x] 2.4 Desktop render check at 640×360 with 6+ cards including one with 月次締め: tray scrolls, cards show full text, links are visible, the clock stays visible above the board; verify by screenshot and note the result in `notes.md`

## 3. Office integration

- [x] 3.1 Add the board to `office_room.tscn` as the last child after `ArtifactViewer` and `DialoguePanel`, with a comment on why the order matters; change `OfficeRoom` so the player is unfrozen only when no panel is open (Decision 5); verify the existing office viewer and dialogue tests still pass
- [x] 3.2 Write GUT integration tests: key C in the office opens the board and the player does not move while a movement key is held; board over the viewer → one Esc closes only the board, the viewer stays open and the player stays frozen; board over the dialogue panel → same; a click where a viewer button sits does nothing while the board is open; the interact key does nothing while the board is open; verify they pass
- [x] 3.3 Write GUT integration tests in the run flow: key C on the briefing screen opens nothing; the clock loses 5 s while the board stays open 5 s; time up with the board open shows the meeting screen and no board remains; verify they pass

## 4. Integration checks

- [x] 4.1 Run the full GUT suite headless (`godot --headless --path game -s addons/gut/gut_cmdln.gd`); verify 0 failures, no new warnings, and the script count grew by the new test files (no silently skipped scripts)
- [x] 4.2 Export with `mkdir -p build/web && godot --headless --path game --export-release "Web" ../build/web/index.html`; verify exit 0
- [x] 4.3 Web walk-through in Chrome: reveal facts from a document and an NPC, open the board with C in the office and over the viewer, pin three cards, drag one, link two, unlink, unpin a linked card, close with Esc and C; verify no console errors, Japanese shows on cards, and record the result in `notes.md`

## Workflow follow-up

- Antigravity tests the web build against the acceptance criteria in `specs/clue-board/spec.md`.
- Archive the change after verification passes, then open the PR with `Closes #7`.
