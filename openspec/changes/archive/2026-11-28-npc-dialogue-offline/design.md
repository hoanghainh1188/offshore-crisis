# Design

## Context

- `GameState` holds the run's `clock`, `truth_sheet` and `revealed_fact_ids` with
  `reveal_fact()` / `fact_revealed`. The case template is loaded privately in
  `start_case()`.
- `RunClock` has `start`, `tick`, `pause`/`resume`, one-shot `time_up`; office time is
  09:00–17:00 (480 in-game minutes) mapped linearly onto the countdown.
- `OfficeRoom` opens `ArtifactViewer` from the Document Shelf and freezes the player with
  `process_mode = DISABLED` until the viewer's `closed` signal.
- The viewer theme (`artifacts/viewer_theme.tres`) carries the Noto Sans JP subset; the
  font coverage test and `tools/subset_jp_font.py` scan only the case template and filler.
- Which facts the two NPCs can hold (from `wrong_delivery.json`):
  - Linh: `fact_lit_ticket_calendar`, `fact_coc_chat_agreement`,
    `fact_py_meeting_proposal`, `rh_timezone_config`.
  - Trang: `fact_coc_spec_unchanged`, `rh_late_regression_run`, `rh_csv_encoding`.
- Requirements: `specs/npc-dialogue`, `specs/run-clock`.

## Goals / Non-Goals

**Goals:**

- Answer choice is a pure function of (question, NPC id, Truth Sheet) so every rule is
  unit-tested across many seeds.
- The data format is what the AI backend change needs as fallback: per question, a fact
  link and answers per attitude.
- One "panel open → player frozen" path in the office for both panels.

**Non-Goals:**

- Typewriter text, portraits, sound.
- Questions changing NPC attitude or trust.

## Decisions

### 1. `RunClock.advance_minutes(minutes: int)`

Moves time forward by `minutes * total_seconds / 480` seconds of countdown, clamped at 0,
then expires (one-shot `time_up`) if it reached 0. Ignored before `start()` and after
expiry; applied even while paused (a pause is for waiting on AI, not a time freeze for
game actions). For the default 900 s run, 15 minutes = 28.125 s, and `office_minutes()`
lands exactly on 09:15 (the existing epsilon covers float error).

### 2. Dialogue data file

`game/dialogue/dialogue_offline.json`:

```json
{
  "npcs": {
    "linh": {
      "questions": [
        {
          "id": "linh_ticket_wording",
          "text": "What did the ticket say about the monthly export?",
          "fact": "fact_lit_ticket_calendar",
          "holds":    { "defensive": "...", "honest": "..." },
          "not_held": { "defensive": "...", "honest": "..." }
        },
        {
          "id": "linh_chat_ok",
          "text": "You wrote 'OK, will do' in chat. What happened next?",
          "fact": "fact_coc_chat_agreement",
          "unlock_any": ["fact_coc_chat_agreement"],
          "holds": { ... }, "not_held": { ... }
        },
        { "id": "linh_role", "text": "What do you work on?", "not_held": { ... } }
      ]
    }
  }
}
```

- `fact` optional; without it only `not_held` is needed. `unlock_any` optional.
- Answers are keyed by attitude; every attitude in that NPC's template pool is required.
- About 6–8 questions per NPC: one per fact the NPC can hold, small talk, and 1–2 locked
  follow-ups. A follow-up may name a fact the NPC can hold; in runs where it is already
  revealed, asking it again reveals nothing new (the revealed list ignores repeats).

Why JSON: same reasons as the case template (nested authored text, readable diffs), and
the backend will read the same file for fallback lines.

### 3. Loader and pure rules

- `DialogueData.load_from(path, template: CaseTemplate) -> DialogueData` (null on error,
  static `last_error`, `push_error`), validating every rule in the spec's "Dialogue content
  is data" requirement plus: `fact` and `unlock_any` ids exist in the template, question
  text is non-empty.
- `DialogueRules` (static, pure):
  - `visible_questions(npc, revealed_ids) -> Array[Question]`
  - `answer(question, npc_id, sheet) -> DialogueAnswer` (`text`, `reveals: StringName` or
    empty). "Holds" only when `sheet.knowledge[question.fact] == "npc:<id>"`.

### 4. Per-run asked state in `GameState`

`GameState.asked_question_ids: Array[StringName]`, cleared by `reset_run()` and
`start_case()`, plus `ask_question(npc_id, question) -> DialogueAnswer`:

1. Compute the answer with `DialogueRules`.
2. If not asked before: record it, reveal the fact (if any), then
   `clock.advance_minutes(tuning.question_cost_minutes)`. Reveal first, so a question that
   ends the day still counts what the player learned.
3. Return the answer (same text when asked again).

Why `GameState`: the asked state must survive closing the panel, and part 2 (other NPCs)
and the backend change will call the same entry point. `GameState` also exposes
`case_template()` so the panel can show the NPC's display name and role.

`DialogueTuning` Resource (`dialogue/dialogue_tuning.tres`, `question_cost_minutes = 15`).
Balance value: changes go in `playtest/tuning-log.md`.

### 5. Dialogue panel

`dialogue/dialogue_panel.tscn` / `DialoguePanel`: `CanvasLayer` 5 (same as the viewer,
under the clock on layer 10), viewer theme for the Japanese font. Header: NPC name and
role. Left: question buttons (asked ones prefixed with "✓ "). Right: the last answer in a
scrolling label. Close button and Esc; first question focused on open. It listens to
`GameState.fact_revealed` while open to refresh the list, so a follow-up unlocked by an
answer appears at once.

### 6. One panel path in `OfficeRoom`

`OfficeRoom._open_panel(panel)` freezes the player and remembers the open panel; each
panel's `closed` unfreezes. The shelf calls it with the viewer; each NPC `Interactable`
whose id has dialogue content calls it with the dialogue panel after `open(npc_id)`. Only
one panel can be open: while frozen the player cannot interact, so a second can't start.

### 7. Font coverage

`DATA_FILES` in `test_jp_font_coverage.gd` and the globs in `tools/subset_jp_font.py`
include `game/dialogue/*.json`. If the dialogue text adds kanji, the font is rebuilt with
the documented command in the same commit.

## Risks / Trade-offs

- [Too little time pressure or too much: 15 min × ~14 questions = 3.5 of 8 office hours]
  → `question_cost_minutes` is data; tune in playtests.
- [Answer text gives away the root cause through wording] → Content check by Harry
  (task), and the same question list in every run.
- [A "does not hold" answer contradicts a fact another holder states] → Non-answers are
  written as deflections ("Not my area", "Ask the team"), never as claims.
- [Questions about facts held by part-2 NPCs are not in this part] → Expected; part 2 adds
  them.

## Open Questions

- Should a locked follow-up cost less time than a fresh question? Decide after the first
  playtest; it would only add a per-question cost field.
