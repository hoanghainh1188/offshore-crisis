# world-interaction Specification

## Purpose

Defines how the player starts an interaction with a nearby NPC or object in the office.
Later systems (dialogue, artifacts, the client call) attach their behavior to this single
interaction event.

## Requirements

### Requirement: Interactable targets
Every NPC and every interactable object in the room SHALL have a unique id, a kind (`npc`
or `object`) and a display name. The prototype room SHALL contain at least two NPCs and two
objects.

#### Scenario: Prototype room content
- **WHEN** the office room is loaded
- **THEN** it contains NPCs "Linh" (kind `npc`, id `linh`) and "Trang" (kind `npc`, id
  `trang`), and objects "Document Shelf" (kind `object`, id `document_shelf`) and
  "Meeting Room Screen" (kind `object`, id `meeting_screen`)

#### Scenario: Ids are unique
- **WHEN** the office room is loaded
- **THEN** no two targets share the same kind and id pair

### Requirement: Interaction range
A target SHALL be in range only when the player character is within its interaction area,
which reaches a short distance beyond the target's solid body. Targets outside that area
SHALL NOT be interactable.

#### Scenario: Out of range
- **WHEN** the player presses the interact key while no target is in range
- **THEN** nothing is logged and nothing else happens

#### Scenario: In range
- **WHEN** the player stands next to Linh and presses the interact key
- **THEN** one interaction with `npc:linh` is triggered

### Requirement: Interact key triggers one interaction
Pressing the interact action (default key E) SHALL trigger exactly one interaction with the
current target. Holding the key SHALL NOT repeat the interaction; the player must release
and press again.

#### Scenario: Single press
- **WHEN** the player presses E once next to the Document Shelf
- **THEN** exactly one interaction with `object:document_shelf` is triggered

#### Scenario: Holding the key
- **WHEN** the player holds E for several seconds next to Trang
- **THEN** only one interaction is triggered until E is released and pressed again

### Requirement: Nearest target wins
When more than one target is in range, the interaction SHALL go to the target whose
position is nearest to the player character. On an exact tie, the target that entered
range first SHALL be used.

#### Scenario: Two targets in range
- **WHEN** the player stands between Linh and the Document Shelf, closer to the shelf, and
  presses E
- **THEN** the interaction goes to `object:document_shelf` only

### Requirement: Interaction is reported to the console
Each triggered interaction SHALL write exactly one line to the game's output console in the
format `[interact] <kind>:<id> "<display name>"`. In the web build this line SHALL appear in
the browser's developer console.

#### Scenario: Log line for an NPC
- **WHEN** the player interacts with Linh
- **THEN** the console shows `[interact] npc:linh "Linh"`

#### Scenario: Log line for an object
- **WHEN** the player interacts with the Meeting Room Screen
- **THEN** the console shows `[interact] object:meeting_screen "Meeting Room Screen"`

#### Scenario: Web build
- **WHEN** the player interacts with any target in the web build
- **THEN** the same line appears in the browser developer console

### Requirement: Interaction is exposed as an event
Each triggered interaction SHALL also be published as a game event carrying the target's
kind, id and display name, so later features can react to it without changing the
movement or room code.

#### Scenario: Event fires with target data
- **WHEN** the player interacts with Trang
- **THEN** exactly one interaction event is published with kind `npc`, id `trang` and
  display name "Trang"
