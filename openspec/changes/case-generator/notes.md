# Notes — case-generator

## Verification results (2026-11-27)

### GUT (task 4.1)

Full suite headless: 19 scripts, 103 tests, 103 passing, 0 failures, no script warnings.
New tests: loader 13, shipped template 6, generator 13 (rules checked over seeds 1–300),
known seeds 2.

### Variant spread

Seeds 1–300 on the shipped template: `lost_in_translation` 99, `chat_only_change` 104,
`polite_yes` 97.

### Web build (tasks 4.2, 4.3)

- Export of the shipped build exits 0.
- Determinism on web: a temporary build (debug print in `GameState._ready`, reverted before
  commit) printed `to_dict()` for seeds 42 and 1234 in the browser console. Both match the
  desktop result field by field. This also confirms `wrong_delivery.json` is packed into
  the web export.
- Same build: briefing → Enter → office still works; no console errors.

### Implementation notes

- Solvability uses up to 20 random redraws, then a fixed valid assignment. The loader only
  accepts chains whose holders together include an NPC and two different holders, which
  guarantees that assignment exists (design §3, updated).
- Template classes are inner classes (`CaseTemplate.Variant`, `.Fact`, `.Npc`) rather than
  separate `CaseVariant` etc. files; design and tasks updated to match.
- The template contains Japanese terms (月次締め, はい). The default Godot font may not show
  them; the first change that displays fact text must check CJK glyphs on web.

### Content check (task 2.2)

Pending Harry's review of the three chains and the red herrings in
`game/case/templates/wrong_delivery.json`.

## Devlog

- 2026-11-27: "Wrong Delivery" template (3 variants, 5 NPCs, 4 red herrings) and a seeded
  case generator built test-first; 103/103 GUT tests pass.
- Seeds 42 and 1234 give identical Truth Sheets on desktop and web.
- Waiting on Harry's content check before PR.
