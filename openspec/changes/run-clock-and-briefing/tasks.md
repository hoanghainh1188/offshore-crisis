# Tasks

## 1. Clock logic

- [x] 1.1 Create `RunTuning` (`run/run_tuning.gd`, `investigation_seconds: float = 900.0`) and `run/run_tuning.tres`; verify a GUT unit test loads the resource and reads 900.0
- [x] 1.2 Implement `RunClock` start / tick / clamp-at-zero / one-shot `time_up` with GUT unit tests for: not running before `start()`, 10 s tick removes 10 s, overshoot ends at exactly 0, `time_up` emitted once and later ticks change nothing; verify the tests pass
- [x] 1.3 Add pause reasons to `RunClock` with GUT unit tests for every pause scenario in `specs/run-clock/spec.md` (pause stops time, resume continues, two reasons, same reason twice, unknown resume, paused with < 1 s left, pause/resume after time up); verify the tests pass
- [x] 1.4 Implement `office_minutes()` and static `format_office_time()` with GUT unit tests for 09:00 at start, 13:00 at half, 09:53 after 100 s of 900 s, 17:00 at zero, and a 60 s tuned countdown; verify the tests pass

## 2. GameState Autoload

- [x] 2.1 Add `game/game_state.gd` (`GameState`, holds `clock: RunClock`, ticks it in `_process`, `reset_run()`) and register it under `[autoload]` in `project.godot`; verify `godot --headless --path game --editor --quit` exits with no errors and only the `[autoload]` section is added
- [x] 2.2 Add a GUT integration test that starts `GameState.clock` with 0.3 s, waits a few process frames past it, and sees `time_up` once; call `GameState.reset_run()` in `before_each`; verify the test passes

## 3. Briefing screen

- [x] 3.1 Create `BriefingEmail` (`sender`, `subject`, `body`) and `run/briefing/wrong_delivery_email.tres` with fictional placeholder text for the "Wrong Delivery" case; verify a GUT unit test loads it and all three fields are non-empty
- [x] 3.2 Build `briefing_screen.tscn` (sender, subject, scrolling autowrapped body, Start button with focus on open, `start_pressed` signal) that reads the email resource; verify GUT integration tests: labels match the resource, Start has focus, pressing the button emits `start_pressed` once
- [x] 3.3 Manual check with a Godot MCP run of the briefing scene at 640×360; verify the whole email is readable (scrolls if long) and Enter and Space both press Start

## 4. Office clock HUD

- [x] 4.1 Build `run/hud/office_clock.tscn` (`CanvasLayer` + `Label`, top-right) that shows `format_office_time(GameState.clock.office_minutes())` each frame, and add it to `office_room.tscn`; verify a GUT integration test shows `09:00` before start and `13:00` after the clock is ticked to half
- [x] 4.2 Run the existing office test suite; verify all earlier tests still pass with the HUD in the room

## 5. Run flow

- [x] 5.1 Build `run/meeting/meeting_placeholder.tscn` (shows `17:00` and "The meeting with the client has started."); verify a GUT test instances it and finds that text
- [x] 5.2 Build `run/run.tscn` / `Run` (exports `tuning`, shows briefing first, on `start_pressed` swaps to the office and starts the clock, on `time_up` swaps to the meeting placeholder); verify GUT integration tests with a 0.5 s tuning: briefing first with no `Player` in the tree, after Start the office is shown with the player at `EntranceSpawn` and the clock running, after time up only the meeting screen remains and the clock is not running
- [x] 5.3 Add a GUT integration test that holds a movement key through time up; verify the meeting screen is shown and no `Player` node exists
- [x] 5.4 Set `run/run.tscn` as `run/main_scene` in `project.godot`; verify running the project opens the briefing screen
- [x] 5.5 Add a "Run clock" note to `playtest/tuning-log.md` saying where `investigation_seconds` lives; verify the entry is present

## 6. Integration checks

- [x] 6.1 Run the full GUT suite headless; verify 0 failures
- [x] 6.2 Export with `godot --headless --path game --export-release "Web" ../build/web/index.html`; verify the command exits 0
- [x] 6.3 Serve `build/web/` and play one run with `investigation_seconds` set to 60 locally (not committed): briefing → Start → clock moves 09:00 → 17:00 → meeting screen; also hide the tab for ~10 s and record what the clock does; verify no console errors and record results in the change notes
- [ ] 6.4 Walk through every scenario in `specs/run-flow/spec.md`, `specs/run-clock/spec.md` and the modified `specs/player-movement/spec.md` on the web build (the default 15:00 run at least once); verify all pass and record pass or fail in the change notes

## Workflow follow-up

- Link issue #4: PR body starts with `Closes #4`; update the issue's PR line.
- Antigravity tests the web build against the acceptance criteria (read-only).
- Open a PR from `change/run-clock-and-briefing` to `main`. Merge after review.
- Archive the change with `/opsx:archive` after verification passes.
