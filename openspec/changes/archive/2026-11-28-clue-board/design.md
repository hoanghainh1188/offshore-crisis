# Design

## Context

- `GameState` (autoload) owns `revealed_fact_ids` and emits `fact_revealed(fact_id)` once
  per new reveal. `reset_run()` and `start_case()` clear per-run lists.
- `TruthSheet.chain` and `TruthSheet.red_herrings` hold the fact objects (id, text);
  `TruthSheet.knowledge[fact_id]` is the one holder this run (`npc:<id>` or
  `artifact:<type>`). NPC display names come from `GameState.case_template()`; document
  names from `ArtifactDocument.display_name(type)`.
- `ArtifactViewer` and `DialoguePanel` are `CanvasLayer`s on layer 5 under the office
  clock (layer 10). Each closes on `ui_cancel` in `_unhandled_input` and emits `closed`.
  `OfficeRoom` freezes the player (`process_mode = DISABLED`) on open and unfreezes on
  `closed`. The tree is never paused, so the clock keeps running.
- `Run` swaps screens; the office scene only exists during the investigation, and is freed
  on time up.
- Viewport is 640×360 (stretch `canvas_items`). The JP font subset is set in the viewer
  theme (`viewer_theme.tres`).
- Requirements: `specs/clue-board/spec.md` in this change.

## Goals / Non-Goals

**Goals:**

- Board rules (pin, unpin, move, link) live in a pure `RefCounted` that GUT tests without
  UI; the scene only draws it and forwards input.
- No change to how the viewer and dialogue panel behave on their own.
- Data the report change will need (pinned ids, links) is reachable from `GameState`.

**Non-Goals:**

- Keyboard drag and keyboard linking.
- Zoom, pan or a board larger than the screen.
- Saving the board to disk.

## Decisions

### 1. Board state is a pure object in `GameState`

`ClueBoardState` (`game/clue_board/clue_board_state.gd`, `RefCounted`) holds:

- `pinned: Dictionary[StringName, Vector2]`: fact id → position in board-area
  coordinates (Godot dictionaries keep insertion order, so this is also pin order);
- `links: Array[Vector2i]`-like pairs, stored as sorted `[StringName, StringName]` keys in a
  `Dictionary[String, bool]` so a pair exists once whatever the click order;
- `selected: StringName` for the first end of a link in progress.

Methods: `pin(id, pos)`, `unpin(id)` (also drops its links and selection), `move(id,
pos)`, `select(id) -> StringName` (returns the action taken: selected / linked /
unlinked / cleared), `tray_ids(revealed) -> Array[StringName]` (revealed minus pinned, in
reveal order), `is_linked(a, b)`, `pinned_ids()`. Ids that are not revealed are refused
by `pin`, so the board cannot show a fact the player has not found.

`GameState.clue_board: ClueBoardState` is replaced with a new instance in `reset_run()`
and `start_case()`, next to the other per-run lists.

Why: the whole spec except drawing is testable as unit tests, and the report change can
read `GameState.clue_board.pinned_ids()` without touching UI. Keeping it on `GameState`
avoids a new autoload (AGENTS §10).
Alternative: keep state inside the board scene. Rejected: lost when the office is freed,
and it mixes rules with drawing.

### 2. Card content is a pure function

`ClueCard.from_fact(fact_id, sheet, template) -> {text, source}` looks the fact up in
`chain` + `red_herrings` and turns the holder into a label: `npc:hana` → the NPC's display
name ("Hana"), `artifact:git_log` → `ArtifactDocument.display_name` ("Git log"). An
unknown holder falls back to the raw holder string and logs a warning, so a template typo
shows up in tests instead of an empty label.

### 3. One `ClueBoard` scene on layer 6, the last child of the office

`game/clue_board/clue_board.tscn` is a `CanvasLayer` on **layer 6**: above the viewer
and dialogue panel (5), under the office clock (10) so time stays visible. It is added
to `office_room.tscn` **after** `ArtifactViewer` and `DialoguePanel`. Godot delivers
`_unhandled_input` to later siblings first, so while the board is open it receives Esc
before the panel underneath and marks it handled: one Esc closes only the board.

A full-screen `Control` with `mouse_filter = STOP` covers the panel underneath so clicks
do not reach it. On open the board grabs focus (Close button) and remembers the focused
control; on close it gives focus back, so Enter never presses a hidden viewer button.

Layout at 640×360: header (title, card count, Close) on top; tray on the left (~170 px,
`ScrollContainer` of card buttons, each with a **Pin** button); board area on the right.
Cards are fixed width, auto-wrap and grow in height, so the full fact text is always
shown (spec: text unchanged). The viewer theme is reused for the JP font.

### 4. Input on the board area

- **Pin:** the tray card's Pin button places the card at the next free slot of a simple
  grid in the board area, then the player can drag it. Why: works with keyboard focus too
  and avoids drag-and-drop from a scroll container on web. Drag-from-tray was the
  alternative; it can be added later without a spec change.
- **Drag vs. select:** press on a pinned card, move more than a small threshold → drag
  (`move()` with the position clamped so the card stays inside the board area); release
  without moving → `select()`. The clamp is a static pure function and unit tested.
- **Unpin:** a small × button on each pinned card.
- **Links:** drawn in the board area's `_draw()` as lines between card centres, under the
  cards; redrawn on move, pin, unpin and link changes. The selected card gets a highlight
  border.

### 5. Toggle key and the office freeze path

New input action `clue_board` bound to physical key C in `project.godot`. The board
handles it in its own `_unhandled_input` (open when closed, close when open). Because the
board only exists inside the office scene, the key does nothing on the briefing and
meeting screens without extra checks.

`OfficeRoom` gains one rule: the player is unfrozen only when **no** panel is open.
`_unfreeze_player()` checks `viewer.is_open() or dialogue.is_open() or board.is_open()`
and stays frozen otherwise. Board `opened`/`closed` signals call the same freeze and
unfreeze paths. Opening the board over a panel leaves the panel open and visible beneath.

Why one rule instead of a panel stack: there are only three panels and at most two open
at once (board over one panel); a stack would be more code than the rule it replaces.

### 6. Live reveals

The board connects to `GameState.fact_revealed` and rebuilds the tray when it fires,
also while open. Rebuilding the tray is cheap (at most ~11 facts per template).

## Risks / Trade-offs

- [Long fact text makes tall cards that crowd the board at 640×360] → fixed narrow width
  with small font; cards can be dragged apart; a playtest decides the size (tuning, not
  spec).
- [`_unhandled_input` order depends on child order in the scene] → an integration test
  opens the viewer, opens the board, presses Esc once and checks the viewer is still
  open; a comment in `office_room.tscn` notes the order.
- [Mouse-only pinning drags on touch/web] → pin is a button press; dragging uses
  `InputEventMouse*`, which Godot also emits for single-touch on web by default.
- [Clicks leaking to the panel under the board] → full-screen STOP control, covered by an
  integration test that clicks where a viewer button sits.

## Migration Plan

New files plus one input action; no saved data. Rollback is reverting the branch.

## Open Questions

- Exact card size, colours and link style: decided in playtest and the art pass.
