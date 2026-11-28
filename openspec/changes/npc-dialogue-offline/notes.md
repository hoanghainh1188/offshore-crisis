# Notes — npc-dialogue-offline (part 1)

## Verification results (2026-11-28)

### GUT (task 5.1)

Full suite headless: 31 scripts, 198 tests, 198 passing, 0 failures, no script warnings.
New tests: clock advance 5, dialogue data 10, dialogue rules 8, shipped content 5 (rules
checked over seeds 1–300), asking 6, panel 10, office dialogue 5.
`test_player_interaction` now also closes the dialogue panel after each target, because
Linh and Trang open it and the panel freezes the player.

### Desktop render (task 4.4)

Seed 42, fact `fact_py_hai_recorded` revealed, Linh's panel after two questions: both asked
questions show "✓ ", the はい follow-up is listed and renders, long questions wrap, the
clock shows 09:30 (2 × 15 minutes) above the panel.

### Web build (task 5.2)

Export exits 0; the game loads and Start works with no console errors.

### Implementation notes

- Content check by an independent code review found five "does not hold" lines that
  denied facts which can be true in a run (each fact has exactly one holder, so a fact
  held by an artifact or another NPC is still true). Rewritten as evasions that never deny:
  `linh_client_changes`, `linh_who_decided`, `linh_release_day`, `linh_spec_followup`,
  `trang_final_run`.
- Also from the review: `unlock_any` must be a list (clean load error instead of a runtime
  error), and the loader and panel handle a missing case template without crashing.
- Found by a test: after an answer reveals a fact the list rebuilds; focus now returns to
  the question just asked.
- No font rebuild needed: the dialogue only adds はい, already in the subset.

### Pending

- Task 2.4: Harry's content check of `game/dialogue/dialogue_offline.json`.
- Task 5.3: scenario walk-through on a visible web build.

## Devlog

- 2026-11-28: Linh and Trang now answer questions from a dialogue data file that follows
  the Truth Sheet and their attitude; new questions cost 15 in-game minutes.
- One panel path in the office freezes the player for both the viewer and the dialogue;
  198/198 GUT tests pass.
- Review caught non-answers that denied true facts; rewritten as evasions.
