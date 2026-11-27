# Design

## Context

- No case logic exists yet. The run frame (`run/`, `GameState`) exists but holds only the
  clock; nothing reads a Truth Sheet yet (see proposal: not wired in this change).
- The interaction system already identifies targets as `kind:id` (`npc:linh`,
  `object:document_shelf`). Fact holders reuse that shape so dialogue and artifacts can
  match holders to targets later without a mapping table.
- AGENTS.md §10: static typing, content and balance values in data files (`.tres` or JSON),
  no new Autoloads without an approved change.
- Requirements: `specs/case-generation/spec.md`.

## Goals / Non-Goals

**Goals:**

- Generation is a pure function of (template, seed): no scene tree, no global RNG, so GUT
  can test every rule directly and a playtester can report "seed 1234" to reproduce a case.
- Template mistakes are caught when the file is loaded, with a message that names the
  problem, not as a crash deep inside dialogue later.

**Non-Goals:**

- Weighting variants or difficulty. All variants and pool entries are equally likely.
- Linking facts to questions or artifact documents. Later changes add fields to the
  template for that.

## Decisions

### 1. Template is JSON, not `.tres`

`game/case/templates/wrong_delivery.json`. The template is nested authored text (variants →
facts → holders), and each fact would need its own sub-resource in a `.tres`. JSON is
shorter to write, easy to review in a PR diff, and the GDD already sketches the data as
JSON. Godot parses it with the built-in `JSON` class; no new dependency.

Alternative: `.tres` with typed Resource classes. Rejected for this content: verbose, and
editor-only authoring of long text is slower. Balance numbers elsewhere stay in `.tres`.

Template shape (abridged):

```json
{
  "id": "wrong_delivery",
  "title": "Wrong Delivery",
  "npcs": [{ "id": "linh", "name": "Linh", "role": "Dev lead",
             "attitudes": ["defensive", "honest"] }],
  "variants": [{
    "id": "lost_in_translation",
    "description": "...",
    "chain": [{ "id": "fact_ticket_wording", "text": "...",
                "holders": ["artifact:ticket", "npc:linh"] }],
    "fix_space": { "fixes": ["..."], "prevention": ["..."] }
  }],
  "red_herrings": [{ "id": "rh_junior_bug", "text": "...", "holders": ["npc:minh"] }]
}
```

### 2. Loader validates into typed objects

`CaseTemplateLoader.load_template(path) -> CaseTemplate` (null on failure). It parses the
JSON, checks every rule in the spec's "Invalid template is refused" requirement, and only
then builds typed `RefCounted` objects (`CaseTemplate`, `CaseVariant`, `CaseFact`,
`CaseNpc`). Errors go through `push_error()` with the file path and the problem, and the
loader also keeps the last error string so tests can assert on it.

Why typed objects after validation: later code gets static typing and never sees a raw
`Dictionary` with a missing key.

### 3. Generator uses its own seeded `RandomNumberGenerator`

`CaseGenerator.generate(template: CaseTemplate, seed: int) -> TruthSheet`.

- A local `RandomNumberGenerator` with `rng.seed = seed`; never `randi()` or the global RNG,
  which other code could advance. Godot's PCG32 is the same on every platform, so web and
  desktop give the same case for the same seed.
- Draw order is fixed and documented in the code: variant → holder per chain fact (in
  chain order) → red herring count → red herrings → holder per red herring → attitude per
  NPC (in template order). Changing the order changes every seed's case, so it is covered
  by a "known seed" regression test.
- **Solvability** (spec: not all in one place, at least one NPC): after drawing holders,
  if the rule fails, redraw the chain holders with the same RNG, up to 20 times; the
  loader also rejects a variant that can never satisfy the rule (every chain fact has only
  one possible holder and they are all the same, or no chain fact lists an NPC). So the
  retry always ends, and it stays deterministic.

Alternative: shuffle-free "first valid combination" search. Rejected: it biases towards the
first holders in the file.

### 4. `TruthSheet` is a plain typed object with `to_dict()`

Fields: `seed`, `template_id`, `root_cause` (id + description), `chain: Array[CaseFact]`,
`knowledge: Dictionary[StringName, String]` (fact id → holder), `attitudes:
Dictionary[StringName, StringName]` (npc id → attitude), `red_herrings: Array[CaseFact]`,
`fix_space`. `to_dict()` returns plain data, used by the "same seed, same case" test and
later for the grader prompt and debug logging.

### 5. Folder layout

```
game/case/
  templates/wrong_delivery.json
  case_template.gd          # CaseTemplate, CaseVariant, CaseFact, CaseNpc (inner classes)
  case_template_loader.gd   # CaseTemplateLoader
  case_generator.gd         # CaseGenerator
  truth_sheet.gd            # TruthSheet
game/tests/unit/
  test_case_template_loader.gd, test_case_generator.gd
game/tests/fixtures/case/   # small broken / minimal templates for loader tests
```

Test fixtures live under `tests/` so they never ship as game content. They are JSON, not
`.gd`, so GUT does not try to run them.

## Risks / Trade-offs

- [Template content is wrong for the story (e.g. a chain that does not lead to its root
  cause)] → Harry reviews `wrong_delivery.json` in the PR; this is content, so later wording
  fixes go in `playtest/tuning-log.md` without a new change.
- [Adding a field or reordering draws later changes the case for a given seed] → Seeds are
  for reproducing bugs within one build, not saved games. The known-seed test makes the
  change visible when it happens.
- [JSON `int` values come back as `float`] → The template has no numeric fields that matter;
  the loader checks types for strings and arrays only.
- [NPCs Minh, Hana and Tanaka are not in the office room yet] → The Truth Sheet is data;
  facts held by them become reachable when the dialogue change adds them to the room.

## Open Questions

- Should the seed shown to playtesters be visible in-game (e.g. on the meeting screen)?
  Answered by the first change that shows debug or end-of-run info.
