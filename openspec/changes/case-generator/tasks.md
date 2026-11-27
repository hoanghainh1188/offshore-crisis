# Tasks

## 1. Template types and loader

- [x] 1.1 Create `game/case/case_template.gd` with typed `CaseTemplate` (inner classes `Variant`, `Fact`, `Npc`) and the allowed attitude and artifact-type lists; verify `godot --headless --path game --editor --quit` reports no script errors
- [x] 1.2 Add loader fixtures in `game/tests/fixtures/case/` (one minimal valid template, and one broken file per rule: missing `variants`, unknown holder, duplicate fact id, chain of 1 and of 5, unknown attitude, empty red herring pool, unsolvable variant) and write failing GUT tests in `tests/unit/test_case_template_loader.gd`; verify the tests run and fail (RED)
- [x] 1.3 Implement `CaseTemplateLoader.load_template()` (parse, validate every rule, build typed objects, `push_error` + last error naming file and problem); verify all loader tests pass, including that each error message names the field, fact id or variant id from the spec scenarios

## 2. Wrong Delivery content

- [x] 2.1 Write `game/case/templates/wrong_delivery.json`: 5 NPCs with GDD §6 attitude pools, 3 variants (GDD §5 A/B/C) with 2–4 one-line chain facts, holders and fix space, and at least 3 red herrings; all fictional; verify a GUT test loads it and checks the "Shipped template loads" and "Variant shape" scenarios
- [ ] 2.2 Harry content check: read the three chains and confirm each one leads from the symptom to its root cause and the red herrings are believable; verify by Harry's OK recorded in the change notes (wording fixes after this go in `playtest/tuning-log.md`)

## 3. Generator

- [x] 3.1 Create `TruthSheet` (`game/case/truth_sheet.gd`) with the fields from the design and `to_dict()`; verify a unit test builds one and `to_dict()` contains every field
- [x] 3.2 Write failing GUT tests in `tests/unit/test_case_generator.gd` for every scenario under "Truth Sheet content", "Case is solvable" and "Generation is seedable" (seeds 1–300 for the rules and the all-variants check, seed 42 twice for equality and seed recording); verify they fail (RED)
- [x] 3.3 Implement `CaseGenerator.generate(template, seed)` with a local seeded `RandomNumberGenerator`, the fixed draw order and the bounded solvability redraw; verify all generator tests pass (GREEN)
- [x] 3.4 Add a known-seed regression test that pins the root cause and holders for two fixed seeds, with a comment that a draw-order change must update it on purpose; verify it passes

## 4. Integration checks

- [x] 4.1 Run the full GUT suite headless; verify 0 failures and no new warnings
- [x] 4.2 Export with `mkdir -p build/web && godot --headless --path game --export-release "Web" ../build/web/index.html`; verify exit 0 and that the briefing → office → meeting run still works in the browser with no console errors (no gameplay change expected)
- [x] 4.3 Check determinism on web: generate seed 42 in the web build (temporary debug print, removed before commit) and compare its `to_dict()` with the desktop GUT result; verify they are identical and record the result in the change notes

## Workflow follow-up

- Open a PR from `change/case-generator` to `main` with `Closes #5`; update the PR line in issue #5.
- Antigravity reviews the template content and test results against the acceptance criteria.
- Archive the change with `/opsx:archive` after verification passes.
