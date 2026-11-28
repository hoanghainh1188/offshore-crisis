# Tasks

## 1. Advancing the clock

- [ ] 1.1 Write failing GUT unit tests for `RunClock.advance_minutes()` (09:00 + 15 → 09:15 and 28.125 s gone on 900 s; works while paused and stays paused; 16:50 + 15 → 17:00 with one `time_up`; no effect before start or after expiry); verify they fail (RED)
- [ ] 1.2 Implement `advance_minutes()`; verify the new tests and every existing run-clock test pass (GREEN)

## 2. Dialogue data and rules

- [ ] 2.1 Add `DialogueData` loader with fixtures in `game/tests/fixtures/dialogue/` (valid minimal, unknown NPC id, unknown fact id, repeated question id, missing attitude answer, `holds` without `fact`) and GUT tests that each error names the file and the problem; verify RED then GREEN
- [ ] 2.2 Implement `DialogueRules.visible_questions()` and `DialogueRules.answer()` with GUT tests over seeds 1–300: "holds" exactly when the NPC is the fact's holder, correct attitude line, fact-less questions never reveal, locked questions hidden until any `unlock_any` fact is revealed and then shown in data order, same list for every root cause; verify RED then GREEN
- [ ] 2.3 Write `game/dialogue/dialogue_offline.json` for Linh (attitudes defensive, honest) and Trang (honest): 6–8 questions each, one per fact the NPC can hold, small talk, 1–2 locked follow-ups, all fictional, non-answers written as deflections; verify a GUT test loads it against the template and checks every fact Linh or Trang can hold has a question for that NPC
- [ ] 2.4 Harry content check: read the questions and both answer versions; confirm the "does not hold" lines never contradict the case and no line gives away the root cause; verify Harry's OK is recorded in the change notes

## 3. Asking in the run

- [ ] 3.1 Add `DialogueTuning` (`question_cost_minutes = 15`) and `dialogue_tuning.tres`, `GameState.asked_question_ids`, `GameState.case_template()` and `GameState.ask_question()`; GUT tests: first ask reveals (holds case) and advances 15 minutes, second ask costs nothing and reveals nothing, asked state cleared by `reset_run()` and `start_case()`, a question at 16:50 triggers `time_up`; verify RED then GREEN
- [ ] 3.2 Add a `playtest/tuning-log.md` entry for `question_cost_minutes`; verify the entry is present

## 4. Panel and office

- [ ] 4.1 Build `dialogue_panel.tscn` / `DialoguePanel` (layer 5, viewer theme, NPC name and role, question buttons with "✓ " for asked, scrolling answer, Close and Esc, first question focused, refresh on `fact_revealed`); GUT tests for header text, list order, asked marker after reopen, follow-up appearing while open, Esc and Close
- [ ] 4.2 Refactor `OfficeRoom` to one `_open_panel()` path for the viewer and the dialogue panel, and connect Linh and Trang; GUT integration tests: Linh opens the panel and still logs, the Meeting Room Screen does not, the player is frozen while open and walks after Esc, and all artifact-viewer office tests still pass
- [ ] 4.3 Add `game/dialogue/*.json` to the font coverage test and `tools/subset_jp_font.py`; rebuild the font if a new CJK character appears; verify the coverage test passes
- [ ] 4.4 Desktop render check at 640×360 of the panel with a long answer and a Japanese term; verify text fits, scrolls, the asked marker shows and the clock stays visible

## 5. Integration checks

- [ ] 5.1 Run the full GUT suite headless; verify 0 failures and no new warnings
- [ ] 5.2 Export with `mkdir -p build/web && godot --headless --path game --export-release "Web" ../build/web/index.html`; verify exit 0 and no console errors when the game loads
- [ ] 5.3 Walk through every scenario in `specs/npc-dialogue` and the `run-clock` addition on a visible web build (talk to Linh and Trang, watch the clock jump 15 minutes, ask again, unlock a follow-up by reading a document); verify all pass and record pass or fail in the change notes

## Workflow follow-up

- Open a PR from `change/npc-dialogue-offline` to `main` with `Part of #8` (issue stays open for part 2); update the PR line in issue #8.
- Antigravity tests the web build against the acceptance criteria (read-only).
- Archive the change with `/opsx:archive` after verification passes.
