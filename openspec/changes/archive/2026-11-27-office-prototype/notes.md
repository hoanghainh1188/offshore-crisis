# Change Notes — office-prototype

## Acceptance check (task 7.1)

Build: Godot 4.7.2, web export (single-threaded), Chromium via Playwright, 2026-11-27.
GUT: 28 tests, 28 passing (after the QA label fix).

"Web" = checked on the exported web build. "GUT" = covered by an automated test.

### player-movement

| Scenario | Web | GUT | Result |
|---|---|---|---|
| Launch the game | Room shown, player at entrance | `test_player_starts_at_entrance` | Pass |
| Walk in one direction | Walked with W/A/S/D | `test_holding_right_moves_right` | Pass |
| Stop on release | Player stayed put after keys released | `test_release_stops_on_next_frame` | Pass |
| Diagonal is not faster | Not measurable by eye | `test_diagonal_is_not_faster_than_straight` | Pass (GUT) |
| Walk into a wall | Top-left and top-right corners: sprite flush with walls | `test_pushing_into_*_wall_stays_inside` | Pass |
| Slide along a wall | Held W+D along the top wall, reached the top-right corner | `test_slides_along_wall_when_moving_diagonally` | Pass |
| Cannot leave the room | No gap found at the walls visited | `test_walk_full_perimeter_stays_inside` | Pass |
| Walk into an NPC | Walking down onto Linh stopped on top of her | `test_npc_blocks_player` | Pass |

### world-interaction

| Scenario | Web | GUT | Result |
|---|---|---|---|
| Prototype room content | All 4 targets visible with names | `test_room_has_the_four_spec_targets` | Pass |
| Ids are unique | — | `test_kind_and_id_pairs_are_unique` | Pass (GUT) |
| Out of range | E pressed away from targets: no log | `test_press_with_nothing_in_range_does_nothing` | Pass |
| In range (Linh) | `[interact] npc:linh "Linh"` | `test_every_target_is_reachable_and_interactable` | Pass |
| Single press (shelf) | `[interact] object:document_shelf "Document Shelf"` once | `test_held_key_echo_does_not_repeat` | Pass |
| Holding the key (Trang) | Held E 1.5 s: one line | `test_held_key_echo_does_not_repeat` | Pass |
| Two targets in range | x = 252.27 (both in range, nearer shelf): only the shelf line. Control at x = 248.80 (both in range, nearer Linh): only the Linh line | `test_between_linh_and_shelf_nearest_wins` | Pass |
| Log line for an NPC | Exact line in browser console | `test_npc_line` | Pass |
| Log line for an object | `[interact] object:meeting_screen "Meeting Room Screen"` | `test_object_line` | Pass |
| Web build | All lines appear in the browser console, 0 errors, 0 warnings | — | Pass |
| Event fires with target data | — | `test_press_next_to_npc_triggers_once` | Pass (GUT) |

**How "Two targets in range" was checked on web:** walk up the gap between Linh and the
shelf, push against the shelf (x = 256, a fixed collision anchor), then tap left for two
physics frames. The player's x was measured from a device-scale screenshot, using Linh's
right edge and the shelf's left edge as rulers. Range math: sensor radius 4, Linh area
x 214..250, shelf area x 250..290, so both are in range for 246 < x < 254.

**Still open for a human:** a general feel check of walking (speed, sticking at corners).

## Antigravity QA (2026-11-27)

Web build in Chrome (ANGLE Metal), read-only run against both spec files.

- **17 PASS, 0 FAIL, 2 NOT TESTED.** NOT TESTED: "Ids are unique" and "Event fires with
  target data". Neither is observable from the web build; both are covered by GUT
  (`test_kind_and_id_pairs_are_unique`, `test_press_next_to_npc_triggers_once`).
  Note: the QA report calls the event an "EventBus" event. There is no EventBus; the
  event is the `Player.interaction_triggered` signal (design.md, Decision 4).
- "Two targets in range" reproduced with the notes.md method: shelf when nearer the
  shelf, Linh when nearer Linh.
- Holding E for ~2.5 s: one line; release and press again: one more line.
- **0 console errors. 104 WebGL warnings** (`bindBuffer: element array buffers can not be
  bound to a different target`, `bufferSubData: no buffer`). Known Godot GLES3 bug on
  WebGL2, godotengine/godot#124726, fixed by #124764 for 4.8 and not backported to
  4.7.x. Nothing fails to render. Keep the pinned 4.7.2; recheck when moving to 4.8.
- Visual notes (not covered by specs):
  - Player sprite drawn over the "Meeting Room Screen" name label. **Fixed:** name labels
    use `z_index = 1`, so every target name draws above the player.
  - "Trang" label slightly overlaps the bottom edge of the QA desk. **Fixed:** the label
    sits below Trang (`label_offset = (0, 28)`).
  - Guarded by `tests/integration/test_name_labels.gd` (fails on the old layout, checked).
  - Player drawn over the "QA corner" floor label: kept as is (it is floor text).
    Full draw order (y-sort) comes with the `office-art-pass` change.

## Notes for reviewers

- Layout choice: the Document Shelf stands next to Linh at the end of the dev desks, so
  the "two targets in range" rule can happen in the real room.
- Fixed during the web check: the player sprite was drawn over the top wall. See
  `ai-failures/2026-11-27-player-sprite-overlaps-wall.md`.
- Godot MCP was not loaded in this session (needs a Claude Code restart), so desktop
  checks used headless runs and scripted screenshots instead.
- Web export templates: only the `web_*` templates of 4.7.2 were installed locally
  (SHA-512 checked against the official release).

## Devlog

- 2026-11-27: Built the office-prototype room: walking, wall collision, and an interact key
  that logs the nearest NPC or object.
- Added GUT 9.7.1 (26 tests) and a working single-threaded web export.
- Lesson: check screenshots, not only positions — the sprite overlapped a wall while the
  physics tests were green.
