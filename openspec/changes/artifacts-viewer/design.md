# Design

## Context

- `GameState` (Autoload) owns the run clock and is ticked in `_process`. `Run` swaps
  briefing → office → meeting and starts the clock in `_on_start_pressed()`.
- `CaseGenerator.generate(template, seed)` and `CaseTemplateLoader` exist; nothing calls
  them in the game yet. `TruthSheet.knowledge` maps fact id → holder (`artifact:chat_log`).
  Fact objects are shared with the template and read-only.
- `Interactable` emits `interacted` after logging; the Document Shelf is
  `Interactables/DocumentShelf` in `office_room.tscn` with id `document_shelf`.
- `Player` reads movement in `_physics_process` and the interact key in `_unhandled_input`.
- The web build has no system fonts: Godot's default font has no Japanese glyphs, and
  fact text contains はい, 月次締め, 締め日.
- Requirements: `specs/artifact-viewer`, `specs/fact-discovery`, `specs/run-flow`.

## Goals / Non-Goals

**Goals:**

- Document text is a pure function of (Truth Sheet, artifact type, filler data), testable
  without UI.
- One revealed-fact list with a signal, so the clue board and dialogue only subscribe.
- Opening the viewer never touches the clock.

**Non-Goals:**

- Document styling per type (ticket fields, chat bubbles). Plain titled text now; the art
  pass styles it.
- Part 2 types (`git_log`, `spec_doc`). The builder and filler file are written so adding
  them is data plus one list entry.

## Decisions

### 1. Run state lives in `GameState`

`GameState` gains:

- `truth_sheet: TruthSheet` (null until Start), `revealed_fact_ids: Array[StringName]`,
  signal `fact_revealed(fact_id: StringName)`.
- `start_case(seed: int) -> void`: loads `res://case/templates/wrong_delivery.json` once,
  generates the sheet, prints `CaseLog.format(seed)` = `[case] seed <n>`.
- `reveal_fact(fact_id) -> bool`: ignores ids not in the sheet (`knowledge` keys) and ids
  already revealed; otherwise appends and emits `fact_revealed`. Returns whether it added.
- `reset_run()` also clears the sheet and the list.

Why `GameState`: same reason as the clock — dialogue and the clue board are in other
scenes and should not need a node path. No new Autoload.

`Run._on_start_pressed()` calls `GameState.start_case(_next_seed())` before starting the
clock. `Run` exports `case_seed: int = -1`; `-1` means a random seed from a fresh
`RandomNumberGenerator.randomize()`. Tests set a fixed seed. The export is not a player
option and is not shown in UI.

### 2. Document builder is pure

`ArtifactDocument.build(sheet: TruthSheet, type: StringName, filler: ArtifactFiller) ->
ArtifactDocument` with `title`, `lines: Array[String]`, `fact_ids: Array[StringName]`.

- Facts: every id in `sheet.knowledge` whose holder is `artifact:<type>`, in Truth Sheet
  order (chain, then red herrings) so the result does not depend on dictionary order.
- Mixing: filler lines in file order, each fact inserted at a position drawn from a local
  `RandomNumberGenerator` seeded with `sheet.seed * 16 + type_index`. Deterministic per
  run and per type, different between types and runs. A plain integer seed is used instead
  of `hash()` to stay identical on desktop and web.

### 3. Filler data file

`game/artifacts/artifact_filler.json`: per type, a `title` (e.g. "Ticket OC-142 — Monthly
export") and 5–7 fictional filler lines that fit the "Wrong Delivery" story without
stating a fact. Loaded and checked once (non-empty title and lines for each supported
type); same loader style as `CaseTemplateLoader`. Text, not balance: later wording fixes
go in `playtest/tuning-log.md`.

### 4. Viewer UI and freezing the player

`game/artifacts/artifact_viewer.tscn`: a `CanvasLayer` (layer 5, below the clock HUD on
layer 10 so the time stays visible) with a panel: document buttons on the left (Ticket,
Chat log, Meeting notes), the open document on the right in a `ScrollContainer` with an
autowrapping `Label`, and a Close button. Opening focuses the first document button so the
viewer works with the keyboard; Esc (`ui_cancel`) closes it.

`OfficeRoom` instances the viewer (hidden), connects the shelf's `interacted` to
`open()`, and while it is open sets `_player.process_mode = PROCESS_MODE_DISABLED`, which
stops both movement and the interact key. `closed` restores `PROCESS_MODE_INHERIT`.

Alternative: `get_tree().paused = true`. Rejected: it would also pause `GameState` and
stop the clock, which the spec forbids.

Time up needs no code: `Run` frees the office, and the viewer goes with it.

### 5. Japanese font: Noto Sans JP subset on the viewer theme

- Source: Noto Sans JP Regular from the official `google/fonts` repository (SIL OFL 1.1).
- Subset with `pyftsubset` (fonttools, installed in a throwaway venv, not a project
  dependency) to Basic Latin, Latin-1, general punctuation, hiragana, katakana, and every
  CJK character that appears in `game/case/templates/*.json` and
  `game/artifacts/artifact_filler.json`. Target size well under 1 MB.
- Files: `game/fonts/noto_sans_jp_subset.ttf` + `game/fonts/OFL.txt`. The source is the
  variable `NotoSansJP[wght].ttf`, pinned to weight 400 before subsetting, so the output
  stays TrueType (`.ttf`). The rebuild script is `tools/subset_jp_font.py` (dev tool, not
  in the game build); `game/fonts/README.md` has the exact commands.
- Used as `default_font` of `game/artifacts/viewer_theme.tres`, applied only to the
  viewer. No project setting changes. Other screens get it when they first show Japanese.

Alternative: a global project theme. Rejected for now: it changes project settings and
every screen's look, which this change does not need.

## Risks / Trade-offs

- [New Japanese text later is missing from the subset and shows boxes] → `fonts/README.md`
  has the rebuild command; a GUT test checks that every CJK character in the template and
  filler files exists in the subset font.
- [Facts held by `git_log` / `spec_doc` cannot be found until part 2] → Expected for a
  part-1 build; no report or grading exists yet, so no run can be "lost" because of it.
- [Freezing via `process_mode` misses a future player child that reads input] → The test
  "Frozen player" holds a movement key and checks the position; later player features run
  under the same node and inherit the disabled mode.
- [Seed in the console helps cheating on web] → Only the seed is logged, not the root
  cause; reproducing the case still needs the game code.

## Migration Plan

None: no saved data. `reset_run()` already runs before each test and run.

## Open Questions

- Should reading a document cost in-game time like questions do (GDD §7 only prices
  questions)? Tune in playtests; it would change the clock spec in a later change.
