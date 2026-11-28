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
- Place Minh and Hana in `office_room.tscn` with clear walking clearance and non-overlapping
  interaction areas.

**Non-Goals:**

- Adding a separate video-call UI or portrait frame for Tanaka-san.
- Changing `DialogueData` schema or `DialogueTuning` (15-minute cost stays unchanged).

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

### 2. Placing Minh and Hana in `office_room.tscn`

- **Minh (`npc:minh`)**: placed near the Coffee corner / entrance area (per GDD §12:
  *"Entrance + coffee corner: Minh is often here"*), e.g. around `(140, 316)` to the right of
  `CoffeeCounter` (`(80, 316)`), keeping a clear gap from `CoffeeCounter` and `EntranceSpawn`.
- **Hana (`npc:hana`)**: placed at a Comtor desk area (per GDD §12: *"Comtor desk: Hana"*),
  e.g. near the lower-right or right-side desk area away from `QaDesk` and `MeetingScreen`
  so interaction areas do not overlap.
- Both use the existing `interactable.tscn` scene with `kind = 0` (`NPC`), so `OfficeRoom`'s
  existing loop over `Interactables` wires them automatically.

### 3. Question Pools in `dialogue_offline.json`

Add `minh`, `hana`, and `tanaka` entries under `"npcs"`, each with 6–8 questions:
- One question per fact the NPC can hold in `wrong_delivery.json`.
- 1–2 small-talk / general context questions (`not_held` only).
- 1–2 locked follow-ups (`unlock_any`) referencing facts from artifacts or other NPCs
  (e.g. `fact_coc_chat_agreement` for Minh, `fact_lit_ticket_calendar` / `fact_py_meeting_proposal`
  for Hana, `fact_py_hai_recorded` / `fact_lit_jp_spec_closing` for Tanaka-san).
- Reuse already-covered Japanese terms (`はい`, `月次締め`, `締め`, `締め日`) or rebuild
  `noto_sans_jp_subset.ttf` if any new CJK character is introduced so `test_jp_font_coverage.gd`
  continues to pass.

## Risks / Trade-offs

- **CJK font coverage** -> Check `test_jp_font_coverage.gd` after editing
  `dialogue_offline.json`; rebuild `noto_sans_jp_subset.ttf` via `tools/subset_jp_font.py` if
  any new CJK character is used.
- **Overlapping interaction areas in `office_room.tscn`** -> Verify with `test_office_dialogue.gd`
  and `test_office_room_targets.gd` that standing next to Minh, Hana, or MeetingScreen targets
  the intended interactable.
