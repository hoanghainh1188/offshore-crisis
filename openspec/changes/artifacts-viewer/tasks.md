# Tasks

## 1. Case per run and revealed facts

- [x] 1.1 Write failing GUT tests for `fact-discovery` (first reveal order, reveal again, unknown id, one announcement per new fact, empty after `reset_run()`) and for `GameState.start_case()` (sheet set, seed recorded, same seed regenerates the same `to_dict()`); verify they fail (RED)
- [x] 1.2 Add `truth_sheet`, `revealed_fact_ids`, `fact_revealed`, `start_case()`, `reveal_fact()` to `GameState` and clear them in `reset_run()`; add `CaseLog.format(seed)`; verify the tests in 1.1 pass and a unit test checks `CaseLog.format(42) == "[case] seed 42"`
- [x] 1.3 Call `GameState.start_case()` from `Run._on_start_pressed()` with `case_seed` (export, `-1` = random); verify run-flow GUT tests: no sheet on the briefing, a sheet right after Start, a fixed `case_seed` gives that seed, and all existing run-flow tests still pass

## 2. Document content

- [x] 2.1 Write `game/artifacts/artifact_filler.json` (title and 5–7 fictional filler lines for ticket, chat log, meeting notes, consistent with the briefing story) and its loader with checks; verify a GUT test loads it and refuses a fixture with a missing type
- [x] 2.2 Write failing GUT tests for `ArtifactDocument.build()` across seeds 1–300: every fact held by the type is shown, no fact held elsewhere is shown, filler-only when the type holds nothing, same sheet → same lines, `fact_ids` match the shown facts; verify they fail (RED)
- [x] 2.3 Implement `ArtifactDocument.build()` (facts in Truth Sheet order, deterministic insertion with an integer-seeded local RNG); verify the tests in 2.2 pass (GREEN)

## 3. Japanese font

- [x] 3.1 Download Noto Sans JP Regular from the official `google/fonts` repository, subset it with `pyftsubset` in a throwaway venv (Latin, punctuation, kana, and every CJK character in the template and filler JSON), and add `game/fonts/noto_sans_jp_subset.ttf`, `OFL.txt` and `README.md` (with the exact subset command); verify the font is under 1 MB and the row is added to `assets/CREDITS.md` in the same commit
- [x] 3.2 Add a GUT test that every CJK character in `game/case/templates/*.json` and `game/artifacts/artifact_filler.json` has a glyph in the subset font; verify it passes, and fails if a new kanji is added to a fixture copy

## 4. Viewer

- [x] 4.1 Build `artifact_viewer.tscn` / `ArtifactViewer` (CanvasLayer 5, document buttons in order Ticket / Chat log / Meeting notes, scrolling document text, Close button, Esc closes, first button focused, `viewer_theme.tres` with the subset font, `closed` signal); opening a document calls `GameState.reveal_fact()` for its `fact_ids`; verify GUT tests: list order, document text matches `ArtifactDocument.build()`, reveal on open, no new announcement on reopen, Esc and Close both close
- [x] 4.2 Wire the viewer into `office_room`: the Document Shelf's `interacted` opens it, the player is disabled while open and enabled on close; verify GUT integration tests: shelf opens the viewer and still logs, Linh does not open it, a held movement key does not move the player while open, the player walks again after Esc
- [x] 4.3 Add run-level GUT tests: the clock loses 5 s while the viewer is open for 5 s (short tuning), and time up while the viewer is open shows the meeting screen with no viewer left; verify they pass
- [x] 4.4 Desktop render check at 640×360 of the viewer with a document that contains Japanese; verify text fits, scrolls when long, Japanese glyphs show and the office clock stays visible

## 5. Integration checks

- [x] 5.1 Run the full GUT suite headless; verify 0 failures and no new warnings
- [x] 5.2 Export with `mkdir -p build/web && godot --headless --path game --export-release "Web" ../build/web/index.html`; verify exit 0
- [x] 5.3 Web check: Start (console shows `[case] seed <n>` and no root cause), walk to the shelf, open all three documents, confirm Japanese glyphs render, Esc returns to walking, clock keeps moving, no console errors; record results in the change notes
- [ ] 5.4 Walk through every scenario in `specs/artifact-viewer`, `specs/fact-discovery` and the modified `specs/run-flow` on a visible web build; verify all pass and record pass or fail in the change notes

## Workflow follow-up

- Open a PR from `change/artifacts-viewer` to `main`. The PR body says `Part of #6` (not `Closes`): issue #6 stays open for part 2 (git log, JP+EN spec). Update the PR line in issue #6.
- Antigravity tests the web build against the acceptance criteria (read-only).
- Archive the change with `/opsx:archive` after verification passes.
