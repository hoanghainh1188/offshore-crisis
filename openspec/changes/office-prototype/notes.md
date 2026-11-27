# Change Notes — office-prototype

## Acceptance check (task 7.1)

Build: Godot 4.7.2, web export (single-threaded), Chromium via Playwright, 2026-11-27.
GUT: 26 tests, 26 passing.

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
| Two targets in range | **Not checked on web** (needs pixel-exact standing) | `test_between_linh_and_shelf_nearest_wins` | Pass (GUT) — web check open |
| Log line for an NPC | Exact line in browser console | `test_npc_line` | Pass |
| Log line for an object | `[interact] object:meeting_screen "Meeting Room Screen"` | `test_object_line` | Pass |
| Web build | All lines appear in the browser console, 0 errors, 0 warnings | — | Pass |
| Event fires with target data | — | `test_press_next_to_npc_triggers_once` | Pass (GUT) |

**Open for a human / Antigravity check on the web build:** "Two targets in range" (stand
in the gap between Linh and the Document Shelf, closer to the shelf, press E → only the
shelf line). Also a general feel check of walking (speed, sticking at corners).

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
