# A test script stopped parsing and GUT skipped it without failing

- Date: 2026-11-28
- Agent / model: Claude Code (Claude Opus 5.5)
- Context: artifacts-viewer-part2, PC Terminal (task 2.2)
- What went wrong: I gave `OfficeRoom._open_viewer()` a `source_name` parameter but did
  not update `tests/integration/test_run_viewer.gd`, which still called it with no
  arguments. The script no longer parsed, so GUT printed only "does not extend GutTest"
  and skipped its 2 tests. The run still reported every test passing, just with 2 fewer
  tests (230 instead of 232 after the fix).
- How it was caught: I read the full GUT output during the full-suite run (task 4.1) and
  saw the warning, not the pass count.
- Fix: updated the call to `_open_viewer("Document Shelf")`; both tests run and pass again.
- Lesson / rule to add: after changing a function signature, grep every caller, tests
  included. A GUT run is green only when it has no "does not extend GutTest" / parse
  warnings and the script count matches the files in `tests/`. A CI step should fail on
  that warning (follow-up from the PR #23 review).
