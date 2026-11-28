# Tasks

## 1. Remote Question Cost (Test-First)

- [x] 1.1 Write failing tests in `game/tests/integration/test_asking.gd` for remote question cost (Tanaka-san first ask advances clock by 30 minutes, repeat ask costs 0, asking at 16:35 moves to the meeting screen); verify the new tests fail.
- [x] 1.2 Add `remote_question_cost_minutes = 30`, `remote_npc_ids = [&"tanaka"]`, and `cost_for(npc_id)` to `DialogueTuning` (`game/dialogue/dialogue_tuning.gd` and `dialogue_tuning.tres`) and use `dialogue_tuning.cost_for(npc_id)` in `GameState.ask_question()`; verify `test_asking.gd` passes.

## 2. Dialogue Content, Reachability & Non-Misleading Answers (Test-First)

- [x] 2.1 Update `game/tests/unit/test_dialogue_content.gd` first: include `&"minh"`, `&"hana"`, and `&"tanaka"` in `NPCS`, add the seeds 1–300 fixed-point reachability test for all chain facts, add assertions for Minh/Hana/Tanaka-san follow-ups, and add a check for non-misleading `honest`/`indirect` `not_held` answers; verify the new tests fail before content is added.
- [x] 2.2 Author 6–8 pre-written questions each for `minh` (`nervous`), `hana` (`protective`, `honest`), and `tanaka` (`indirect`) in `game/dialogue/dialogue_offline.json`, covering every fact each NPC can hold in `wrong_delivery.json`, small talk, and 1–2 locked follow-ups per NPC; verify `test_dialogue_content.gd` and `test_jp_font_coverage.gd` pass (rebuilding `noto_sans_jp_subset.ttf` if any new CJK glyph is missing).

## 3. Office Room NPCs, Comtor Desk & Meeting Room Screen (Test-First)

- [x] 3.1 Update `game/tests/integration/test_office_room_targets.gd` (`EXPECTED` includes `npc:minh` and `npc:hana`) and `game/tests/integration/test_office_dialogue.gd` (Minh, Hana, and Tanaka-san via `MeetingScreen` open `DialoguePanel` with expected headers and `[interact]` logs, plus a 640×360 panel render check for `"Client PM, Kazegumo Logistics"`); verify the new tests fail.
- [x] 3.2 Add `Solids/ComtorDesk` (`(480, 288)`, size `88×24`), `ZoneLabels/Label4` (`"Comtor desk"`), `Minh` (`(150, 316)`), and `Hana` (`(422, 288)`) to `game/office/office_room.tscn`, and wire `$Interactables/MeetingScreen.interacted` in `game/office/office_room.gd` to `_open_dialogue(&"tanaka")`; verify `test_office_room_targets.gd`, `test_office_room_walls.gd`, `test_name_labels.gd`, and `test_office_dialogue.gd` pass.

## 4. End-to-End Verification & QA

- [x] 4.1 Run the full GUT test suite and `openspec validate npc-dialogue-offline-part2`; verify all tests pass with zero errors and update `notes.md` with implementation/verification results.
- [x] 4.2 Read-only QA by Claude Code (or Harry): run tests, run the web export build, verify acceptance criteria in `specs/npc-dialogue/spec.md` and `specs/world-interaction/spec.md`, and report findings.
