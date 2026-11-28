# Design

## Context

- Part 1 (archived `2026-11-28-artifacts-viewer`) built `ArtifactDocument.build(sheet,
  type, filler)`, a pure function. `ArtifactDocument.TYPES` drives both the viewer's
  button order and the per-type RNG seed (`sheet.seed * 16 + TYPES.find(type)`).
- `ArtifactFiller` loads `game/artifacts/artifact_filler.json`: per type a `title` and a
  flat `lines` list, checked for every entry in `TYPES`.
- `ArtifactViewer.open()` sets the heading to "Document Shelf" and focuses the first
  button. `OfficeRoom` connects only `Interactables/DocumentShelf` to it.
- `npc-dialogue` already unlocks questions through `unlock_any` against
  `GameState.revealed_fact_ids`, whatever revealed the fact. `GameState.reveal_fact()` is
  the only way in, and the viewer already calls it.
- Template holders for the new types: `artifact:git_log` can hold `fact_coc_no_ticket`,
  `rh_junior_null_fix`, `rh_timezone_config`; `artifact:spec_doc` can hold
  `fact_lit_jp_spec_closing`, `fact_coc_spec_unchanged`.
- Requirements: `specs/artifact-viewer`, `specs/npc-dialogue` in this change.

## Goals / Non-Goals

**Goals:**

- Adding the two types is mostly data; the builder stays pure and testable without UI.
- Part 1 documents keep exactly the same text for the same seed.
- One viewer, two entry points.

**Non-Goals:**

- Visual styling per type (monospace commits, JP/EN side by side). Plain text now.
- Changing fact text per document. Facts read the same everywhere, which the clue board
  will rely on.
- A time cost for reading (still an open question from part 1).

## Decisions

### 1. Display order is separate from the seed index

`TYPES` becomes the display order: `ticket, git_log, chat_log, spec_doc, meeting_notes`.
A new constant `SEED_INDEX: Dictionary[StringName, int]` keeps the part 1 values
(`ticket 0, chat_log 1, meeting_notes 2`) and adds `git_log 3, spec_doc 4`. The RNG seed
uses `SEED_INDEX[type]`.

Why: reordering `TYPES` alone would move every part 1 fact to a new line position for
the same seed, which breaks reproducing a reported seed across builds and the existing
known-seed tests for no gain.

### 2. Optional sections in the filler data

A filler entry has either `lines` (part 1 shape, unchanged) or `sections`:

```json
"spec_doc": {
  "title": "Spec KZ-EXP-01: Monthly accounting export (v1.2)",
  "sections": [
    { "id": "revisions", "heading": "Revision history", "lines": ["v1.0 ...", "..."] },
    { "id": "jp", "heading": "Japanese original (日本語原文)", "lines": ["..."] },
    { "id": "en", "heading": "English translation", "lines": ["..."] }
  ],
  "fact_sections": {
    "fact_coc_spec_unchanged": "revisions",
    "fact_lit_jp_spec_closing": "jp"
  }
}
```

- Builder: for each section in order, output the heading line, then that section's filler
  lines with its facts inserted at RNG positions inside the section only. Facts not listed
  in `fact_sections` go to the first section. One RNG per document, seeded as above,
  drawn in section order then Truth Sheet order, so the result stays deterministic.
- Loader checks: exactly one of `lines` / `sections`; each section has a unique `id`, a
  non-empty `heading` and non-empty `lines`; every `fact_sections` value names a section
  in that entry. Errors use the existing `"<path>: <problem>"` form. Fact ids in
  `fact_sections` are not checked against the template here (the filler loader does not
  know the template); a GUT content test checks them against "Wrong Delivery".
- Headings are plain lines in `ArtifactDocument.lines`; the viewer shows them as they are.
  A separate `headings` list on the document lets tests find section bounds without
  string matching.

Alternative: put section tags inside fact data in the template. Rejected: the template is
the case logic; where a fact sits on a page is presentation, which belongs with filler.

### 3. Git log is flat lines in commit form

Filler lines look like `e41b07d  2026-10-29  Minh  Add invoice number column to export`
(fictional hashes and dates). Fact lines stay prose (see Non-Goals). 6–8 filler commits so
up to three facts do not dominate the page.

### 4. PC Terminal as a second entry point

- `office_room.tscn`: new `Interactables/PcTerminal` (kind object, id `pc_terminal`,
  display name "PC Terminal") at the dev desks, on the side away from the shelf so the two
  entry points do not compete for "nearest target". Exact position chosen in the editor
  and checked by the room target test (reachable, no overlap with walls or desks).
- `OfficeRoom._ready()` connects both the shelf and the terminal `interacted` to
  `_open_viewer` with the source display name.
- `ArtifactViewer.open(source_name: String = "Document Shelf")` uses it as the idle
  heading. Everything else in the viewer is the same; the default keeps existing callers
  and tests working.

### 5. Follow-up questions are content only

Two entries added to `game/dialogue/dialogue_offline.json`, no code change:

- `linh_no_ticket_followup`: "No ticket was ever made for the closing-period change. So
  where did that request come from?" — `fact: fact_coc_chat_agreement`,
  `unlock_any: [fact_coc_no_ticket]`. Worded so it makes sense whether the ticket or the
  git log revealed the missing ticket.
- `trang_closing_followup`: "The Japanese spec says 月次締め. Did your tests check the
  closing period?" — no `fact` (Trang cannot hold `fact_lit_jp_spec_closing`), `unlock_any:
  [fact_lit_jp_spec_closing]`. Honest answer: she tested against the English ticket's
  calendar month. It can only unlock in the "lost in translation" case, so its wording may
  support that case without lying in the others.

Both placed last in their NPC's list. `test_dialogue_content.gd` gets checks that they
exist with these unlocks.

### 6. Font

Run `tools/subset_jp_font.py` after writing the JP filler; `test_jp_font_coverage.gd`
already scans `game/artifacts/*.json` and fails if a kanji is missing. Size stays well
under 1 MB.

## Risks / Trade-offs

- [Prose fact lines stand out among commit-style filler in the git log] → Accepted for the
  MVP; the art pass can format fact lines per type with a presentation map. Noted in
  `notes.md` for playtest feedback.
- [Two viewer entry points close together confuse "nearest target wins"] → Place the
  terminal at the far end of the dev desks; the room target test checks a spot where
  only the terminal is in range.
- [`fact_coc_no_ticket` held by Minh means Linh's follow-up never unlocks that run] →
  Accepted; Minh's dialogue comes later and can reveal it.
- [JP filler text with new kanji shows boxes on web] → Covered by the font coverage test
  and the rebuild script.

## Migration Plan

None: no saved data. Part 1 document text for a given seed is unchanged (Decision 1).

## Open Questions

- Should reading cost in-game time? Still a playtest question; not in this change.
