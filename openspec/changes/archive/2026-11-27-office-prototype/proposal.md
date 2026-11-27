# Proposal

## Why

The repo has an empty Godot project and no gameplay yet. Every system in the GDD (dialogue,
artifacts, clue board, 5 PM report) starts from the same action: the player walks up to a
person or object in the office and interacts with it. This change builds that foundation as
the smallest playable slice, so later changes can plug real behavior into the interaction
without touching movement or the room again. It also sets up the test and web-export
pipeline that the Definition of Done requires.

## What Changes

- Add one office room (GDD §12) built from placeholder shapes: outer walls, a few desks,
  two NPCs and two objects. No art assets yet.
- Add a player character that walks in 8 directions and is blocked by walls and furniture.
- Add an interaction rule: when the player is close enough to an NPC or object and presses
  the interact key, the game logs one interaction line to the console. If several targets
  are in range, the nearest one is used.
- Make the room the main scene, so the game starts in the office.
- Add the GUT test framework (v9.7.1, the release for Godot 4.7.x) and unit tests for the
  interaction rule.
- Add a "Web" export preset and confirm the web build runs in a browser.

Out of scope: dialogue UI, on-screen interaction prompt, clock, camera follow, sprites and
animation, sound, NPC movement, more than one room.

## Capabilities

### New Capabilities

- `player-movement`: how the player moves around the office and how walls and furniture
  block movement.
- `world-interaction`: how the player selects and triggers an interaction with a nearby NPC
  or object, and what the game reports when an interaction happens.

### Modified Capabilities

_(none — there are no existing specs)_

## Impact

- New code and scenes under `game/` (room scene, player, interactable component).
- `game/project.godot`: main scene, input actions (`move_*`, `interact`), display size.
  The Godot version and the Compatibility renderer do not change.
- New dependency: GUT 9.7.1 vendored in `game/addons/gut/` (MIT, recorded in
  `assets/CREDITS.md`).
- New file `game/export_presets.cfg` with a "Web" preset (no secrets in it).
- Local machine: Godot 4.7.2 export templates must be installed to build for web. They live
  outside the repo.
- No backend, no AI calls, no new environment variables.
