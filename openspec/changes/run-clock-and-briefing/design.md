# Design

## Context

- The game currently boots straight into `office/office_room.tscn` (the main scene). There
  are no Autoloads, no UI scenes and no notion of a "run".
- Rules that shape this design (AGENTS.md §10): static typing, balance values in data files,
  Autoloads limited to `GameState`, `EventBus`, `AIClient`, signals over direct references
  across scenes.
- GUT runs as the current scene during tests, so code under test must never call
  `get_tree().change_scene_to_file()` — it would replace the test runner.
- Requirements: `specs/run-clock/spec.md`, `specs/run-flow/spec.md`,
  `specs/player-movement/spec.md` (modified start requirement).

## Goals / Non-Goals

**Goals:**

- Keep all clock rules (countdown, pause reasons, time up, office time) in one pure class
  that unit tests drive with explicit time steps — no waiting on real time in tests.
- Give later systems (dialogue, AI client, report) one stable place to reach the clock.
- Make the whole run flow testable in GUT by instancing a single scene.

**Non-Goals:**

- In-game time cost per question (GDD §7). The office time is derived only from real time
  here; see Open Questions.
- Restarting a run, saving, or showing remaining real seconds.
- Final UI styling. Placeholder Godot controls only; the art pass restyles them.

## Decisions

### 1. Folder layout

```
game/run/
  run.tscn, run.gd                    # main scene, swaps the three screens
  run_clock.gd                        # RunClock: pure clock logic (RefCounted)
  run_tuning.gd, run_tuning.tres      # RunTuning: investigation_seconds = 900.0
  briefing/  briefing_screen.tscn, briefing_screen.gd,
             briefing_email.gd, wrong_delivery_email.tres
  meeting/   meeting_placeholder.tscn
  hud/       office_clock.tscn, office_clock.gd
game/game_state.gd                    # GameState Autoload
```

Why: one feature folder for the run frame, matching the existing `office/`, `player/`,
`interaction/` layout.

### 2. `RunClock` is a pure `RefCounted`, ticked from outside

- API: `start(total_seconds)`, `tick(delta)`, `pause(reason: StringName)`,
  `resume(reason: StringName)`, `is_running()`, `remaining_seconds`, `office_minutes()`,
  signal `time_up`.
- Pause reasons are stored as a set (`Dictionary[StringName, bool]`), so the same reason
  twice counts once and an unknown resume is a no-op — exactly the spec rules.
- `tick()` clamps at 0, emits `time_up` once, then ignores all further input.
- `office_minutes()` = `540 + floor(480 * elapsed / total)` (09:00 = 540 minutes,
  8 in-game hours). A static `format_office_time(minutes) -> String` gives `HH:MM`.
- 09:00 and 17:00 are constants in `RunClock`: they are fixed by the spec, not balance.

Why: no `_process`, no scene tree, so every scenario in `specs/run-clock` becomes a
three-line unit test. Alternative: a `Timer` node. Rejected — it cannot hold several pause
reasons, and testing it needs real waiting.

### 3. `GameState` Autoload owns the clock and ticks it

`GameState` (Node, Autoload) holds `var clock: RunClock` and calls `clock.tick(delta)` in
`_process`. Any system pauses the clock with `GameState.clock.pause(&"ai_reply")`.

Why: the clock must be reachable from systems that do not know the scene tree (the future
`AIClient`), and `GameState` is already on the allowed Autoload list and will hold the
Truth Sheet later. `process_mode` stays the default; nothing in this change uses
`get_tree().paused`.

Alternatives: (a) pause through `EventBus` signals — adds a second Autoload for one call
site; can be added later without changing the spec. (b) clock as a node in `run.tscn` —
later systems would need a node path or a reference passed down.

### 4. `run.tscn` swaps child screens instead of changing scenes

`run.tscn` is the new main scene. `Run` instances one screen at a time as a child:
briefing → office room → meeting placeholder, freeing the previous one.

- Briefing emits `start_pressed`. `Run` connects it once (`CONNECT_ONE_SHOT`), frees the
  briefing, adds `office_room.tscn`, and calls `GameState.clock.start(tuning.investigation_seconds)`.
- `Run` connects `GameState.clock.time_up`, then frees the office and adds the meeting
  placeholder. Freeing the office removes the player, so held keys can no longer move
  anything.
- `Run` exports `tuning: RunTuning`, so an integration test can pass a 0.5-second
  countdown and check the full flow in under a second.

Why: works inside GUT (no `change_scene_to_file`), and keeps the transitions in one place
the report and ending changes can extend. Alternative: `change_scene_to_file` from
`GameState` — simpler, but not testable in GUT and spreads flow logic.

`office_room.tscn` stays a standalone scene; existing office tests keep instancing it
directly. It gains an `OfficeClock` HUD instance (a `CanvasLayer` with a `Label`,
top-right) that reads `GameState.clock` every frame. Before the clock starts it shows
`09:00`, so office tests that never start a run are unaffected.

### 5. Data files

- `RunTuning` Resource with `investigation_seconds: float = 900.0` → `run_tuning.tres`.
  Balance value: changes go in `playtest/tuning-log.md`.
- `BriefingEmail` Resource with `sender`, `subject`, `body` → `wrong_delivery_email.tres`,
  fictional placeholder text. `case-generator` will later supply the email instead.

### 6. Briefing screen

`Control` filling the 640×360 viewport: sender and subject labels, the body in a
`ScrollContainer` with an autowrapping `Label` (the email may be longer than the screen),
and a Start `Button` that calls `grab_focus()` in `_ready()`. Enter and Space work through
the built-in `ui_accept` action, so no new input actions are added.

## Risks / Trade-offs

- [Web tab hidden: the browser stops frames, and the next `delta` may cover the whole
  hidden time, so the clock jumps forward] → This matches "real-time countdown". Verify the
  actual behavior in the web check (task 6.3) and record it; auto-pause on hidden tab is a
  separate change if Harry wants it.
- [Large frame `delta` after a hitch skips minutes on the office clock] → Acceptable: the
  clock is clamped at 0 and `time_up` still fires once.
- [`GameState` keeps state across tests] → Add `GameState.reset_run()` (new `RunClock`) and
  call it in `before_each` of every test that touches the clock.
- [Freeing the office while the player is mid-interaction] → No interaction has lasting
  state yet; dialogue changes must handle being freed at time up.

## Migration Plan

- Main scene changes from `office/office_room.tscn` to `run/run.tscn`; `GameState` is added
  under `[autoload]`. Rollback: revert those two lines in `project.godot`.

## Open Questions

- How question time cost (GDD §7, 15 in-game minutes) combines with the real-time
  countdown. Answered by the dialogue change; `RunClock` can add an offset then without
  changing this change's scenarios.
