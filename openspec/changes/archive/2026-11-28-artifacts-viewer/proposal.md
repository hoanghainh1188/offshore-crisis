# Proposal

## Why

The Truth Sheet exists but nothing in the game uses it: every run is the same and the
player cannot find a single fact. Reading documents is the first way to investigate
(GDD §8) and needs no AI. This change is **part 1 of 2** of `artifacts-viewer` (issue #6):
it connects the Truth Sheet to the run, adds the shared list of revealed facts that the
clue board and dialogue will also use, and makes the Document Shelf open readable
documents for three artifact types.

## What Changes

- **Case per run:** pressing Start generates a Truth Sheet from the "Wrong Delivery"
  template with a random seed and logs the seed (`[case] seed <n>`), so a playtester can
  report and reproduce a case. The root cause is never logged.
- **Revealed facts:** the run keeps one ordered list of revealed fact ids, with no
  duplicates, and announces each newly revealed fact. Nothing shows it yet (clue board,
  issue #7).
- **Artifact viewer:** interacting with the Document Shelf opens a viewer that lists the
  artifact types available in this part — **ticket**, **chat log**, **meeting notes**.
  Opening one shows a document generated from the Truth Sheet: the facts that artifact
  holds this run, mixed with fixed filler lines so a document never gives away which
  lines matter. Opening a document reveals its facts.
- While the viewer is open the **clock keeps running** and the player cannot walk or
  trigger interactions. Closing the viewer (Close button or Esc) returns to the office.
  If time runs out while reading, the run still moves to the meeting screen.
- **Japanese text on web:** add a subset of Noto Sans JP (SIL OFL) as the viewer's font so
  terms like はい and 月次締め show on the web build, recorded in `assets/CREDITS.md`.

Decisions taken (agreed with Harry before proposing):

- Part 1 only: **git log** and the **JP+EN spec with revision history** come in part 2.
  Facts held by those two artifact types cannot be found until then.
- Unlocking NPC questions from documents is **not** in this change; `npc-dialogue-offline`
  (issue #8) reads the revealed-fact list to do that.

Out of scope: the clue board UI, pinning, NPC dialogue, part 2 artifact types, art, sound,
and a debug option to choose the seed in the build.

## Capabilities

### New Capabilities

- `artifact-viewer`: opening the viewer from the Document Shelf, which documents it lists,
  how a document's content is built from the Truth Sheet, and how the viewer behaves while
  the run clock keeps going.
- `fact-discovery`: the run's shared list of revealed facts — how facts are added, kept
  unique and announced to other systems.

### Modified Capabilities

- `run-flow`: "Start begins the investigation" also generates the run's Truth Sheet with a
  random, logged seed.

## Impact

- New `game/artifacts/` feature folder (viewer scene, document builder, filler data) and
  new tests.
- `game/game_state.gd`: holds the run's Truth Sheet and revealed facts; `reset_run()`
  clears both.
- `game/run/run.gd`: generates the case on Start.
- `game/office/office_room.tscn` / `.gd`: the Document Shelf opens the viewer; the player
  is frozen while it is open.
- New asset: Noto Sans JP subset (`game/fonts/`), entry in `assets/CREDITS.md`, used by
  the viewer's own theme. No change to `project.godot`, the Godot version, renderer or
  export preset.
- No backend, no AI calls, no new environment variables.
