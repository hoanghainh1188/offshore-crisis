# Design

## Context

- Part 1 (`npc-dialogue-offline`) built `DialogueData`, `DialogueRules`, `DialoguePanel`,
  `DialogueTuning`, and `GameState.ask_question()`, and populated `linh` and `trang` in
  `game/dialogue/dialogue_offline.json`.
- `OfficeRoom` already wires every `Interactable` with `kind == NPC` whose `id` is in
  `DialogueData` to `_open_dialogue(target.id)`.
- `MeetingScreen` in `office_room.tscn` is an `Interactable` with `kind = 1` (`OBJECT`)
  and `id = &"meeting_screen"`.
- `wrong_delivery.json` already defines all five NPCs and their attitudes/facts:
  - `minh` ("Junior dev", `["nervous"]`): `fact_coc_no_ticket`, `rh_junior_null_fix`.
  - `hana` ("Comtor (interpreter)", `["protective", "honest"]`):
    `fact_lit_jp_spec_closing`, `fact_lit_unconfirmed_note`, `fact_py_hai_recorded`.
  - `tanaka` ("Client PM, Kazegumo Logistics", `["indirect"]`):
    `fact_coc_chat_agreement`, `fact_py_check_internally`, `rh_csv_encoding`.

## Goals / Non-Goals

**Goals:**

- Reuse the existing `DialoguePanel`, `DialogueData`, `DialogueRules`, and `GameState`
  architecture without changing the JSON schema or `DialogueData` validation rules.
- Keep `MeetingScreen` as `kind = OBJECT` (`object:meeting_screen`) so `world-interaction`
  logging and specs remain intact while opening `DialoguePanel` for `&"tanaka"`.
- Place Minh and Hana in `office_room.tscn` (with `Solids/ComtorDesk` and `"Comtor desk"`
  zone label) with clear walking clearance and non-overlapping interaction areas.
- Store the remote question time cost in `DialogueTuning` so playtests can tune it.

**Non-Goals:**

- Adding a separate video-call UI or portrait frame for Tanaka-san.
- Changing the `dialogue_offline.json` schema.

## Decisions

### 1. Wiring Meeting Room Screen to Tanaka-san in `OfficeRoom`

In `office_room.gd`, connect `$Interactables/MeetingScreen.interacted` to
`_open_dialogue(&"tanaka")` (when `_dialogue.has_dialogue(&"tanaka")`).

- Why: `MeetingScreen` stays an `OBJECT` (`[interact] object:meeting_screen "Meeting Room Screen"`),
  preserving `world-interaction` contracts while reusing the single `_open_dialogue` +
  `_freeze_player` path.
- Alternative considered: changing `MeetingScreen.kind` to `NPC` with `id = &"tanaka"`.
  Rejected because `world-interaction` explicitly defines `object:meeting_screen "Meeting Room Screen"`
  as an object.

### 2. Remote question cost in `DialogueTuning`

Add `@export var remote_question_cost_minutes: int = 30` and
`@export var remote_npc_ids: Array[StringName] = [&"tanaka"]` (plus `cost_for(npc_id: StringName) -> int`)
to `DialogueTuning` (`dialogue/dialogue_tuning.gd` and `dialogue/dialogue_tuning.tres`).
`GameState.ask_question(npc_id, question)` calls `clock.advance_minutes(dialogue_tuning.cost_for(npc_id))`.

- Why: keeps all dialogue balance numbers in one `.tres` Resource, never hard-coded, so
  playtests can tune both 15 and 30 minutes without code edits.
- Alternative considered: putting a `cost_minutes` field on each NPC in `dialogue_offline.json`.
  Rejected because `DialogueTuning` already owns `question_cost_minutes` and `playtest/tuning-log.md`
  tracks `.tres` balance values.

### 3. Concrete positions for Minh, ComtorDesk, and Hana in `office_room.tscn`

The room is 640×360 (`Solids`: `DevDesks` at `(150, 92)`, `QaDesk` at `(500, 92)`,
`CenterTable` at `(320, 180)`, `CoffeeCounter` at `(80, 316)`; `EntranceSpawn` at `(320, 316)`;
`MeetingScreen` at `(617, 200)`).

- **Minh (`npc:minh`)**: at `(150, 316)` (right of `CoffeeCounter`, clear of `CoffeeCounter`
  right edge at `x = 124` and `EntranceSpawn` at `x = 320`), matching GDD §12 *"Entrance + coffee corner: Minh is often here"*.
- **`Solids/ComtorDesk`**: `CollisionShape2D` + `Polygon2D` at `(480, 288)`, size `(88, 24)`
  (occupying `x: 436..524, y: 276..300`), with `ZoneLabels/Label4` `"Comtor desk"` at `(446, 256)`.
- **Hana (`npc:hana`)**: at `(422, 288)` (immediately left of `ComtorDesk`, well clear of
  `QaDesk`/`Trang` at `y = 92..118`, `MeetingScreen` at `(617, 200)`, and `EntranceSpawn` at `(320, 316)`).

### 4. Question Pools in `dialogue_offline.json` & Reachability

Add `minh`, `hana`, and `tanaka` entries under `"npcs"`, each with 6–8 questions:
- One always-unlocked question per fact the NPC can hold in `wrong_delivery.json` (or if a
  follow-up is locked, an always-unlocked question or artifact also covers the prerequisite,
  preventing any unlock cycle).
- 1–2 small-talk / general context questions (`not_held` only).
- 1–2 locked follow-ups (`unlock_any`) referencing facts from artifacts or other NPCs.
- Keep `honest` and `indirect` `not_held` answers strictly non-misleading (do not imply the
  NPC holds or knows the unheld fact).
- Reuse already-covered Japanese terms (`はい`, `月次締め`, `締め`, `締め日`) or rebuild
  `noto_sans_jp_subset.ttf` if any new CJK character is introduced.

## Risks / Trade-offs

- **6–8 question cap binds Linh too** -> Linh already has 8 questions; any future follow-up
  for Linh will require raising the cap in `specs/npc-dialogue/spec.md` or replacing a question.
- **CJK font coverage** -> Check `test_jp_font_coverage.gd` after editing
  `dialogue_offline.json`; rebuild `noto_sans_jp_subset.ttf` via `tools/subset_jp_font.py` if
  any new CJK character is used.
- **Overlapping interaction areas in `office_room.tscn`** -> Verify with `test_office_dialogue.gd`
  and `test_office_room_targets.gd` that standing next to Minh, Hana, or MeetingScreen targets
  the intended interactable.
