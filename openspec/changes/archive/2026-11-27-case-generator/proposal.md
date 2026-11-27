# Proposal

## Why

Every investigation system still to come — artifacts, NPC dialogue, the clue board, the
5 PM report, grading and endings — reads from one hidden source: the Truth Sheet (GDD §5).
Without it those systems have no content and no "right answer". Building the generator
first, as pure logic with tests, also gives us the roguelike core (a different case each
run) and a seed to reproduce any case during playtests.

## What Changes

- Add the **"Wrong Delivery" case template** as a data file: the 3 root cause variants
  (A. Lost in translation, B. Chat-only change, C. The polite "yes"), each with a 2–4 fact
  chain, the possible holders of each fact, a fix space; plus the 5 MVP NPCs with their
  attitude pools and a pool of red herrings. All text is fictional.
- Add a **template loader** that checks the data and refuses an invalid template with a
  clear error.
- Add a **case generator** that turns a template and a seed into a **Truth Sheet**:
  `root_cause`, `chain`, `knowledge` (who or which artifact holds each fact), `attitudes`,
  1–2 `red_herrings`, and `fix_space`.
- Generation is **seedable**: the same seed and template always give the same Truth Sheet.
- GUT unit tests for the loader, the generator rules and the shipped template.

Decisions taken for this change (Harry can override):

- Content for **all 3 variants** is written now, kept short (one line per fact). Wording
  polish happens with the dialogue and artifact changes.
- The generator is **not wired into the run yet**: no Truth Sheet in `GameState`, and the
  briefing email stays the fixed placeholder. The first change that reads the sheet
  (artifacts or dialogue) wires it in.

Out of scope: any UI or debug screen, artifact documents, NPC dialogue, question pools,
more case templates, saving a case, and difficulty tuning.

## Capabilities

### New Capabilities

- `case-generation`: the case template data, how a Truth Sheet is generated from it and a
  seed, and the rules every generated Truth Sheet must follow.

### Modified Capabilities

_(none)_

## Impact

- New code and data under `game/case/` (template JSON, loader, generator, Truth Sheet
  types) and new unit tests under `game/tests/unit/`.
- No change to `project.godot`, scenes, Autoloads, the run flow or the export preset.
- No backend, no AI calls, no new dependencies, no new environment variables.
