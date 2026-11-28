# Proposal

## Why

The player now finds facts by reading documents and asking NPCs, but the only trace of a
reveal is a one-off announcement. After a few minutes there is nowhere to see what they
already know, so they re-read and re-ask instead of reasoning. The GDD (§9, §13) asks for a
clue board: every revealed fact becomes a card the player can pin and link. The report
screen (#10) and grader (#11) will also need to know which clues were pinned. This change
closes issue #7.

## What Changes

- **Clue cards:** every fact in the revealed list (`fact-discovery`) is shown as a clue
  card with the fact's Truth Sheet text and a source label ("Hana", "Git log", ...). A card
  appears as soon as the fact is revealed, also while the board is open. Red herrings get
  cards too; the board never hints which cards matter.
- **Open anywhere:** a new input action `clue_board` (key **C**) opens and closes the
  board during the investigation, in the office and while the artifact viewer or the
  dialogue panel is open. Esc or a Close button also closes it.
- **Tray and board:** new cards land in a tray. The player pins a card onto the board
  area, drags pinned cards to move them, and can unpin a card back to the tray.
- **Links:** the player draws a link between two pinned cards (select one card, then
  another). Selecting the same pair again removes the link. Links are lines between card
  centres, undirected, no duplicates, no card linked to itself. Unpinning a card removes
  its links.
- **Not scored:** pins and links change nothing else in the run: no clock cost, no reveal,
  no dialogue unlock. Pinned ids are kept in the run state so a later change (report,
  grader) can read them.
- **One run:** the clock keeps running while the board is open, the player character does
  not move, and the whole board (pins, positions, links) is cleared when a new run starts.

Assumptions (recorded here, change on Harry's review):

- "Pin" means moving a card from the tray onto the board; only pinned cards can be linked.
- "Anywhere" means during the investigation screen, including over an open viewer or
  dialogue panel. Not on the briefing or meeting screen.
- Key **C** (Tab is taken by UI focus). The key itself is game feel and can be retuned
  without a spec change.
- Pinning, dragging and linking use the mouse in the MVP. Keyboard-only use of the board
  (open, close, pin, unpin) works; keyboard dragging and linking are left for later.

Out of scope: scoring or bonus insight from linked chains, notes or labels on cards or
links, a wall object in the office that opens the board, card art and styling (art pass),
saving the board between sessions.

## Capabilities

### New Capabilities

- `clue-board`: clue cards for revealed facts, opening and closing the board, the tray,
  pinning and moving cards, drawing and removing links, and the board's run lifetime.

### Modified Capabilities

None. `fact-discovery` already announces each reveal once and owns the revealed list; the
board only reads it. The viewer and dialogue panel keep their behaviour; the board opens
on top of them.

## Impact

- New `game/clue_board/` (board state, card view, board scene) and its GUT tests.
- `game/game_state.gd`: per-run board state (pinned ids, positions, links), reset with the
  rest of the run.
- `game/office/office_room.tscn` / `.gd`: board instance and the freeze/unfreeze path when
  the board opens over the room or a panel.
- `game/project.godot`: one new input action `clue_board` (key C). No other project
  setting, Godot version or export preset change.
- No backend, no AI calls, no new environment variables, no new assets.
