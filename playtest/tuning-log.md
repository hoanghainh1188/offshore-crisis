# Tuning Log

Balance numbers, text fixes and asset swaps that do not need an OpenSpec change.

| Date | What changed | Old → New | Why |
|---|---|---|---|
| 2026-11-27 | Run clock: investigation countdown added. Tune `investigation_seconds` in `game/run/run_tuning.tres` | — → 900 s (15:00) | GDD §4 default; real limit (12/15/20 min) decided after the first playtest |
| 2026-11-28 | Dialogue: each new question moves the office clock forward. Tune `question_cost_minutes` in `game/dialogue/dialogue_tuning.tres` | — → 15 in-game minutes (≈28 s of a 15:00 run) | GDD §7 default; check time pressure in the first playtest |
