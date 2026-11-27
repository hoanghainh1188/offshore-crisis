# Tasks

## 1. Project setup

- [x] 1.1 Add input actions `move_left/right/up/down` (WASD + arrows) and `interact` (E) to `game/project.godot`; verify with `grep -A3 'interact=' game/project.godot` and by opening the project headless with no errors
- [x] 1.2 Set display to 640×360 base / 1280×720 window, stretch `canvas_items`, aspect `keep`, and name 2D physics layers `world`, `player`, `interaction`; verify `godot --headless --path game --editor --quit` exits with no errors and the Godot version and renderer lines are unchanged
- [x] 1.3 Create the feature folders `office/`, `player/`, `interaction/`, `tests/unit/`, `tests/integration/` under `game/`; verify they exist

## 2. Test framework

- [x] 2.1 Vendor GUT 9.7.1 from the `v9.7.1` tag into `game/addons/gut/` and add `game/.gutconfig.json` pointing at `res://tests/`; verify `godot --headless --path game -s addons/gut/gut_cmdln.gd` runs and reports 0 tests, 0 failures
- [x] 2.2 Add the GUT entry (name, author, URL, MIT) to `assets/CREDITS.md`; verify the row is present
- [x] 2.3 Add one trivial smoke test in `tests/unit/`; verify the GUT command reports 1 passing test

## 3. Player movement

- [x] 3.1 Create the `PlayerTuning` Resource script and `player_tuning.tres` with a first `move_speed` value; verify the resource loads in a unit test
- [x] 3.2 Implement static `compute_velocity(direction, speed)` in `player.gd`, with unit tests for: zero input gives zero velocity, a straight input gives full speed, and a diagonal input has the same length as a straight one; verify the GUT tests pass
- [x] 3.3 Build `player.tscn` (`CharacterBody2D`, placeholder shape, collision layer `player`, mask `world`) that moves with `move_and_slide()` using the tuning resource; verify by running a test scene and walking with WASD and the arrow keys

## 4. Office room

- [x] 4.1 Build `office/office_room.tscn` at 640×360: outer walls, a few desks, an entrance spawn point, all solids on layer `world`; verify visually with a Godot MCP run of the scene
- [x] 4.2 Set `office_room.tscn` as the main scene with the player at the entrance spawn; verify that running the project opens the room with the player at the entrance
- [x] 4.3 Add a GUT integration test that pushes the player into an outer wall for a fixed number of physics frames and asserts it stays inside the room; verify the test passes
- [x] 4.4 Manual check: walk the full edge of the room and slide along a wall diagonally; verify there are no gaps and no sticking (note any tuning in `playtest/tuning-log.md`)

## 5. Interaction

- [x] 5.1 Implement `InteractionLog.format()` with unit tests for an NPC line and an object line (exact strings from the spec); verify the GUT tests pass
- [x] 5.2 Implement `InteractionTargetPicker.pick_nearest()` with unit tests for: empty list returns null, nearest wins, and a tie returns the earlier entry; verify the GUT tests pass
- [x] 5.3 Build `interactable.tscn` / `Interactable` (solid `StaticBody2D` on `world`, `InteractionArea` on `interaction`, exported `kind`/`id`/`display_name`, name `Label`, `interacted` signal); verify the scene opens without errors
- [x] 5.4 Add the `InteractionSensor` to the player: track areas in entry order, handle `interact` press without echo, pick the nearest target, `print()` the log line, emit `interacted` and `interaction_triggered`; verify with the integration test in 5.6
- [x] 5.5 Place Linh, Trang, Document Shelf and Meeting Room Screen in the room with the spec ids; verify with a GUT integration test that the room has these four targets with unique kind+id pairs
- [x] 5.6 Add GUT integration tests: an interact press next to a target emits exactly one `interaction_triggered`, and a press with no target in range emits none; verify the tests pass
- [x] 5.7 Manual check in the desktop run (Godot MCP): interact with each of the 4 targets, hold E, and stand between two targets; verify the console output matches the spec lines exactly

## 6. Web export

- [x] 6.1 Install the Godot 4.7.2 export templates on this machine (outside the repo); verify the `4.7.2.stable` templates folder contains the web templates
- [x] 6.2 Add the "Web" preset to `game/export_presets.cfg` (thread support off, path `../build/web/index.html`); verify the file has no credentials and `build/` stays git-ignored
- [x] 6.3 Export with `godot --headless --path game --export-release "Web" ../build/web/index.html`; verify the command exits 0 and `build/web/index.html` exists
- [x] 6.4 Serve `build/web/` locally and open it in a browser; verify the room loads, the player walks, and `[interact] ...` lines appear in the browser developer console with no errors
- [x] 6.5 Add a short "Run locally" section to `README.md` (run, test, and export commands, plus the export templates note); verify each command runs exactly as written

## 7. Acceptance check

- [x] 7.1 Walk through every scenario in `specs/player-movement/spec.md` and `specs/world-interaction/spec.md` on the web build and record pass or fail in the change notes; verify all pass
- [x] 7.2 Run the full GUT suite one last time; verify 0 failures

## Workflow follow-up

- Antigravity tests the web build against the acceptance criteria (read-only).
- Open a PR from `change/office-prototype` to `main`. Merge after review.
- Archive the change with `/opsx:archive` after verification passes.
