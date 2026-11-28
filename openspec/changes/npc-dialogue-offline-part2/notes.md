# Notes — npc-dialogue-offline-part2

## 2026-11-28 — Proposal & Review Revisions

- Created `npc-dialogue-offline-part2` to complete offline dialogue for Minh, Hana, and Tanaka-san (via Meeting Room Screen).
- Assigned owner: Antigravity (by Harry); QA will be performed read-only by Claude Code (or Harry).
- Revised proposal, specs, design, and tasks after PR #29 review:
  - Added `remote_question_cost_minutes` (default 30 min) for Tanaka-san per PO decision.
  - Added `world-interaction` spec delta for Minh and Hana in `office_room.tscn`.
  - Specified concrete coordinates for `Minh`, `Solids/ComtorDesk`, `"Comtor desk"` label, and `Hana`.
  - Added reachability (seeds 1–300), non-misleading `honest`/`indirect` answer checks, 640×360 render check, and test-first task ordering.
