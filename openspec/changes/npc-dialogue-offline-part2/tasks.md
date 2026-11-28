# Tasks

## 1. Dialogue Content for Minh, Hana, and Tanaka-san

- [ ] 1.1 Author 6–8 pre-written questions each for `minh` (`nervous`), `hana` (`protective`, `honest`), and `tanaka` (`indirect`) in `game/dialogue/dialogue_offline.json`, covering every fact each NPC can hold in `wrong_delivery.json`, small talk, and 1–2 locked follow-ups per NPC; verify `DialogueData.load_from()` succeeds.
- [ ] 1.2 Update `game/tests/unit/test_dialogue_content.gd` so `NPCS` includes `&"minh"`, `&"hana"`, and `&"tanaka"` and add targeted assertions for their follow-up questions; run GUT unit tests (`test_dialogue_content.gd` and `test_jp_font_coverage.gd`) and rebuild `noto_sans_jp_subset.ttf` if any new CJK character is missing.

## 2. Office Room NPCs and Meeting Room Screen

- [ ] 2.1 Add `Minh` (`npc:minh`, "Minh") and `Hana` (`npc:hana`, "Hana") interactable NPCs to `game/office/office_room.tscn` with non-overlapping collision/interaction areas, and update `game/tests/integration/test_office_room_targets.gd` `EXPECTED` targets; verify `test_office_room_targets.gd` and `test_office_room_walls.gd` pass.
- [ ] 2.2 Wire `$Interactables/MeetingScreen.interacted` in `game/office/office_room.gd` to open `DialoguePanel` for `&"tanaka"` while preserving `[interact] object:meeting_screen "Meeting Room Screen"` logging, and update `game/tests/integration/test_office_dialogue.gd` to test Minh, Hana, and Tanaka-san via the Meeting Room Screen; verify `test_office_dialogue.gd` passes.

## 3. End-to-End Verification

- [ ] 3.1 Run the full GUT test suite and verify all unit and integration tests pass with zero errors, and verify `openspec validate npc-dialogue-offline-part2` passes.
- [ ] 3.2 Run the web export build and verify it runs with no console or runtime errors (QA by Antigravity against acceptance criteria).
