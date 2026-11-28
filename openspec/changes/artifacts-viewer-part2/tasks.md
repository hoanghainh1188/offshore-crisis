# Tasks

## 1. Builder and filler data

- [ ] 1.1 Write failing GUT tests for the new type order and seed index: `TYPES` is Ticket, Git log, Chat log, Spec document, Meeting notes; for seeds 1–300 the ticket, chat log and meeting notes documents are line-for-line the same as before the change (capture expected output from `main` into a fixture first); verify they fail (RED)
- [ ] 1.2 Add `git_log` and `spec_doc` to `TYPES` / `DISPLAY_NAMES` and add `SEED_INDEX` (Decision 1); verify the tests in 1.1 pass (GREEN)
- [ ] 1.3 Write failing GUT tests for sections in `ArtifactFiller` and `ArtifactDocument.build()`: a fixture with `sections` loads; missing heading, duplicate section id, both `lines` and `sections`, and an unknown `fact_sections` target each fail with an error naming the file and problem; facts land only inside their assigned section; unassigned facts land in the first section; headings come out in order; same sheet → same lines; verify they fail (RED)
- [ ] 1.4 Implement sections in the loader and builder (Decision 2), keeping flat `lines` entries unchanged; verify the tests in 1.3 and all part 1 artifact tests pass (GREEN)
- [ ] 1.5 Write the `git_log` (6–8 fictional commit lines) and `spec_doc` (title, three sections with JP and EN filler, `fact_sections`) entries in `artifact_filler.json`; add a content test that the shipped file loads, every `fact_sections` key is a fact the "Wrong Delivery" template lets `artifact:spec_doc` hold, and for seeds 1–300 Git log and Spec document show exactly the facts the Truth Sheet gives them; verify it passes
- [ ] 1.6 Run `tools/subset_jp_font.py` if `test_jp_font_coverage.gd` fails after 1.5; verify the coverage test passes and the font stays under 1 MB

## 2. Viewer and PC Terminal

- [ ] 2.1 Update viewer GUT tests: five buttons in the new order, Spec document text matches `ArtifactDocument.build()` including headings, reveal on opening Git log and Spec document, `open("PC Terminal")` shows that heading; verify they fail, then add the `source_name` parameter to `ArtifactViewer.open()` and verify they pass
- [ ] 2.2 Add `Interactables/PcTerminal` (object, id `pc_terminal`, "PC Terminal") at the far end of the dev desks and connect it to the viewer in `OfficeRoom`; verify GUT tests: the terminal opens the viewer with the same five documents and logs `[interact] object:pc_terminal "PC Terminal"`, the shelf still opens it, Linh does not, from a spot next to the terminal only the terminal is in range, and the existing room target and wall tests still pass
- [ ] 2.3 Add a GUT test that opening Git log with the clock paused at 10:00 leaves the office time at 10:00; verify it passes
- [ ] 2.4 Desktop render check at 640×360 of Git log and Spec document with Japanese in the JP section; verify text fits, scrolls, headings are readable, Japanese glyphs show and the clock stays visible

## 3. Follow-up questions

- [ ] 3.1 Write failing GUT tests: `linh_no_ticket_followup` unlocks on `fact_coc_no_ticket` and is about `fact_coc_chat_agreement`; `trang_closing_followup` unlocks on `fact_lit_jp_spec_closing` and is about no fact; both have answers for every attitude in their NPC's pool; verify they fail (RED)
- [ ] 3.2 Add both questions to `dialogue_offline.json` (fictional, last in each NPC's list, wording from Decision 5); verify the tests in 3.1 and the existing dialogue content tests pass, and the font coverage test still passes
- [ ] 3.3 Add an integration test with fixed seeds: a run where the git log holds `fact_coc_no_ticket` — open Git log, talk to Linh, the follow-up is listed; a run where the spec holds `fact_lit_jp_spec_closing` — open Spec document, talk to Trang, the follow-up is listed; before reading, neither is listed; verify it passes

## 4. Integration checks

- [ ] 4.1 Run the full GUT suite headless; verify 0 failures and no new warnings
- [ ] 4.2 Export with `mkdir -p build/web && godot --headless --path game --export-release "Web" ../build/web/index.html`; verify exit 0
- [ ] 4.3 Web walk-through in a browser: open the viewer from the shelf and from the PC Terminal, read Git log and Spec document (Japanese visible), unlock one follow-up by reading, close with Esc; verify no console errors and record the result in `notes.md`
