# Design

## Context

- `game/` holds an empty Godot 4.7.2 project (Compatibility renderer). There are no
  scenes, scripts, addons, input actions or export presets yet.
- The Godot 4.7.2 export templates are not installed on the dev machine, so the web build
  cannot be produced yet.
- Rules that shape this design (AGENTS.md §10): static typing, `snake_case` files,
  `PascalCase` classes, balance values in data files, minimal Autoloads, signals over
  direct cross-scene references.
- Requirements: see `specs/player-movement/spec.md` and `specs/world-interaction/spec.md`.

## Goals / Non-Goals

**Goals:**

- A reusable interactable component, so later changes add an NPC or object by placing a
  node and setting three fields.
- Keep the decision logic (which target is picked, what the log line says) in small pure
  functions that GUT can test without running physics.
- A working test command and web export, so every later change can meet the Definition of
  Done.

**Non-Goals:**

- Final art, the real room size or layout, and movement feel (tuned in playtests and logged
  in `playtest/tuning-log.md`, not specified).
- A global event bus. One event source is enough for now (see Decision 4).
- Camera movement. The whole room fits on one screen.

## Decisions

### 1. Folder layout by feature

```
game/
  office/       office_room.tscn            # the one room, main scene
  player/       player.tscn, player.gd, player_tuning.gd, player_tuning.tres
  interaction/  interactable.tscn, interactable.gd,
                interaction_target_picker.gd, interaction_log.gd
  tests/        unit/, integration/
  addons/gut/   # vendored GUT 9.7.1
```

Why: matches the "organize by feature" rule. Alternative (`scenes/`, `scripts/` by type)
splits one feature across folders.

### 2. Player = `CharacterBody2D` + `move_and_slide()`

- Direction comes from `Input.get_vector("move_left", "move_right", "move_up",
  "move_down")`, which is already normalized. Diagonal speed equals straight speed with no
  extra code.
- Velocity is computed in a static function `compute_velocity(direction, speed)` so a unit
  test can check the diagonal rule.
- Speed lives in `player_tuning.tres` (a `PlayerTuning` Resource with `move_speed`). It is
  a balance value, so it is not in code.
- `move_and_slide()` gives "slide along walls" for free.

Alternative: `RigidBody2D`. Rejected because physics-driven movement drifts and feels
floaty for a top-down office walker.

### 3. Interactable = solid body + larger detection area

`interactable.tscn`:

- Root `StaticBody2D` (blocks the player, as the spec requires) with script
  `Interactable` exporting `kind: Kind` (`NPC`, `OBJECT`), `id: StringName`,
  `display_name: String`.
- Child `Area2D` "InteractionArea" whose shape is the body shape plus a small margin.
  This is the interaction range.
- Placeholder visuals: a colored `Polygon2D` and a `Label` with the display name, so
  testers can tell targets apart.

The player has a small `Area2D` "InteractionSensor". The player keeps the list of
overlapping `InteractionArea`s in the order they entered (needed for the tie-break rule).

Why the player tracks targets, not each target tracking the player: the "nearest wins" rule
needs all candidates in one place.

### 4. Events: signals, no new Autoload

- `Interactable.interacted()` signal is emitted on the target.
- `Player.interaction_triggered(target: Interactable)` signal is emitted once per
  interaction.

Later features (dialogue, artifacts) connect to these signals. An `EventBus` Autoload is
allowed by AGENTS.md, but there is only one producer and no consumer yet. Adding it now
would be speculative. A later change can add it when several systems need to listen.

### 5. Pure logic helpers (unit-tested)

- `InteractionTargetPicker.pick_nearest(origin: Vector2, candidates: Array[Interactable])
  -> Interactable`: returns `null` for an empty list. Uses the smallest
  `distance_squared_to`. On a tie, the earlier element wins (entry order).
- `InteractionLog.format(kind, id, display_name) -> String`: returns
  `[interact] npc:linh "Linh"`. The caller passes the result to `print()`. In the web
  build, Godot forwards `print()` to the browser console.

### 6. Input map in `project.godot`

| Action | Keys |
|---|---|
| `move_left` | A, Left |
| `move_right` | D, Right |
| `move_up` | W, Up |
| `move_down` | S, Down |
| `interact` | E |

The interact key is read with `event.is_action_pressed("interact")` while ignoring echo
events in `_unhandled_input`. This gives one interaction per press, with no repeat while
the key is held. Gamepad bindings come later.

### 7. Display and physics layers

- Base viewport 640×360, window 1280×720, stretch mode `canvas_items`, aspect `keep`.
  The room is drawn to fit 640×360. This size suits pixel-art office packs later.
- Named 2D physics layers: 1 `world` (walls, furniture, interactable bodies),
  2 `player`, 3 `interaction` (interaction areas and the player sensor).

### 8. Tests with GUT 9.7.1 (vendored)

- Copy `addons/gut/` from the v9.7.1 tag (the release for Godot 4.7.x) into
  `game/addons/gut/`. Record it in `assets/CREDITS.md` (MIT).
- `game/.gutconfig.json` points to `res://tests/`.
- Command (already in CLAUDE.md):
  `godot --headless --path game -s addons/gut/gut_cmdln.gd`
- Unit tests: picker, log format, velocity.
- Integration tests: load `office_room.tscn`, check the four targets and unique ids. Run a
  few physics frames with the player pushed into a wall and assert it stays inside. Trigger
  the interact action next to a target and assert exactly one signal.

Alternative: a plugin from the Asset Library. Vendoring was chosen instead because it pins
the exact version in git, and CI or another machine gets the same code.

### 9. Web export preset

- Preset name "Web", export path `../build/web/index.html` (`build/` is git-ignored).
- Thread support off. A single-threaded build runs on itch.io and on a plain local HTTP
  server without special COOP/COEP headers.
- `export_presets.cfg` is committed. It holds no secrets for the Web platform.
- Export templates for 4.7.2 are installed on the machine (outside the repo) via
  Editor → Manage Export Templates, or the official `.tpz` from the Godot GitHub release.

## Risks / Trade-offs

- [Physics-based integration tests can be flaky] → Use fixed physics frames
  (`wait_physics_frames`) instead of wall-clock waits. Keep only one wall test. Collision
  feel is checked by hand and by Antigravity.
- [Export templates are large (~1 GB) and installed per machine] → One-time step, written
  in the README "Run locally" section. Not committed.
- [GUT 9.7.1 has a known 4.7 doubling quirk (issue 842)] → No doubles or mocks are needed
  in this change. Tests use real nodes.
- [The interact log is the only feedback, so testers must open the console] → Accepted for
  the prototype. On-screen prompts come in the dialogue change.
- [Tie-break by entry order depends on signal order] → The picker gets the list in entry
  order, and its unit test pins the rule.

## Open Questions

- Final move speed and interaction margin: set a first value, then tune in playtest and log
  in `playtest/tuning-log.md`.
- Where the other GDD targets go (Minh, Hana, coffee corner, clue board): added in later
  changes using the same component.
