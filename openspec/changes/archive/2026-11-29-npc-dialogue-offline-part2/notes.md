# Notes — npc-dialogue-offline-part2

## 2026-11-28 — Proposal & Review Revisions

- Created `npc-dialogue-offline-part2` to complete offline dialogue for Minh, Hana, and Tanaka-san (via Meeting Room Screen).
- Assigned owner: Antigravity (by Harry); QA will be performed read-only by Claude Code (or Harry).
- Revised proposal, specs, design, and tasks after PR #29 review:
  - Added `remote_question_cost_minutes` (default 30 min) for Tanaka-san per PO decision.
  - Added `world-interaction` spec delta for Minh and Hana in `office_room.tscn`.
  - Specified concrete coordinates for `Minh`, `Solids/ComtorDesk`, `"Comtor desk"` label, and `Hana`.
  - Added reachability (seeds 1–300), non-misleading `honest`/`indirect` answer checks, 640×360 render check, and test-first task ordering.

## 2026-11-28 — Implementation

- Added `remote_question_cost_minutes = 30`, `remote_npc_ids = [&"tanaka"]`, and `cost_for(npc_id)` to `DialogueTuning` (`dialogue_tuning.gd` / `dialogue_tuning.tres`), wired into `GameState.ask_question()`.
- Authored pre-written question pools in `game/dialogue/dialogue_offline.json` for `minh` (6 questions, `nervous`), `hana` (7 questions, `protective`/`honest`), and `tanaka` (6 questions, `indirect`), covering every fact each can hold plus locked follow-ups. No new CJK glyphs were needed; `test_jp_font_coverage.gd` passed without font rebuild.
- Added `Solids/ComtorDesk`, `ZoneLabels/Label4` ("Comtor desk"), `Minh`, and `Hana` to `game/office/office_room.tscn`, and wired `MeetingScreen.interacted` in `game/office/office_room.gd` to `_open_dialogue(&"tanaka")`.
- Added test-first unit & integration tests in `test_asking.gd`, `test_dialogue_content.gd`, `test_office_room_targets.gd`, and `test_office_dialogue.gd`.
- Updated `test_dialogue_panel.gd` (`test_only_npcs_with_content_have_dialogue`) for all 5 NPCs.
- Full GUT suite: 307/307 tests passed across 39 scripts (43787 asserts). `openspec validate npc-dialogue-offline-part2` passed. Ready for read-only QA (Task 4.2).
- Addressed QA findings from PR #29:
  - Replaced `tanaka_hai_followup` `not_held.indirect` so it points to the shared chat / meeting notes without leaking the meaning of `はい`.
  - Added leak-keyword assertions for `tanaka_hai_followup` and a dedicated test for Hana holding `fact_lit_unconfirmed_note` with `protective` attitude.
