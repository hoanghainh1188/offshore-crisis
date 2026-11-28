# Proposal

## Why

Part 1 of `artifacts-viewer` (issue #6) shipped three document types. Five facts in the
"Wrong Delivery" template can still be held by `artifact:git_log` or `artifact:spec_doc`,
and in those runs the player cannot find them at all. The GDD (§8) also asks for a PC
terminal next to the shelf and for documents that open up new questions for NPCs. This is
**part 2 of 2** and finishes issue #6.

## What Changes

- **Two new document types:** **Git log** (commit lines with hash, date, author and
  message) and **Spec document** (revision history, the Japanese original and its English
  translation). Both are built from the Truth Sheet like the part 1 types: the facts that
  type holds this run, mixed with filler lines, and opening one reveals its facts.
- **Five types, fixed order:** the viewer always lists Ticket, Git log, Chat log, Spec
  document, Meeting notes, in every run, so the list never hints where the facts are.
- **Sections for the spec:** a document type can have titled sections in its filler data.
  The Spec document uses three (Revision history, Japanese original, English
  translation) and the data file says which section each fact goes into, so
  `fact_coc_spec_unchanged` sits in the revision history and `fact_lit_jp_spec_closing`
  in the Japanese original.
- **PC Terminal:** a new office object "PC Terminal" (id `pc_terminal`) at the dev desks.
  It opens the same viewer as the Document Shelf, with the same five documents.
- **Follow-up questions from reading:** two new pre-written questions that unlock when a
  part 2 document reveals a fact: Linh is asked about commits with no ticket (unlocked by
  `fact_coc_no_ticket`), Trang about testing against 月次締め (unlocked by
  `fact_lit_jp_spec_closing`). This uses the unlock rule that `npc-dialogue` already has.
- **Clock unchanged:** reading still costs no in-game time; the clock keeps running in
  real time while the viewer is open, as in part 1.
- Japanese font subset is rebuilt if the new filler text adds kanji that are not in it.

Assumptions (recorded here, change on Harry's review):

- "Shelf/PC terminal" means two entry points to one viewer, not two different document
  sets.
- Fact lines keep their Truth Sheet text as-is in every document, also in the git log, as
  in part 1. Styling them as commit lines is left to the art pass.

Out of scope: per-type visual styling (commit table, diff view, side-by-side JP/EN), a
time cost for reading, dialogue for Minh, Hana and Tanaka-san, the clue board (#7).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `artifact-viewer`: the PC Terminal also opens the viewer; the list grows to five types
  in a new fixed order; documents can have sections with facts placed by data; reading a
  part 2 document can unlock a follow-up NPC question.
- `npc-dialogue`: the shipped content gains follow-up questions unlocked by facts that
  only the git log or spec document can hold.

## Impact

- `game/artifacts/artifact_document.gd`, `artifact_filler.gd`, `artifact_filler.json`,
  `artifact_viewer.gd` and their tests.
- `game/office/office_room.tscn` / `.gd`: new `PcTerminal` interactable wired to the
  viewer; room target tests.
- `game/dialogue/dialogue_offline.json` and its content test.
- Maybe `game/fonts/noto_sans_jp_subset.ttf` (rebuilt with `tools/subset_jp_font.py`).
- No change to `project.godot`, the Godot version or export presets. No backend, no AI
  calls, no new environment variables.
