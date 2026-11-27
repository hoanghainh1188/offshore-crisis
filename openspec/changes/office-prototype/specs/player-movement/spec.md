# Spec Delta

## Purpose

Lets the player walk around the office room so they can reach the people and objects they
want to investigate, while walls and furniture keep them inside a believable space.

## ADDED Requirements

### Requirement: Game starts in the office room
The game SHALL open directly in the office room with the player character placed at the
room entrance and able to move.

#### Scenario: Launch the game
- **WHEN** the player starts the game (desktop run or web build)
- **THEN** the office room is shown and the player character is at the entrance

### Requirement: Player moves with directional input
The player character SHALL move while a direction is held and SHALL stop when no direction
is held. Holding two perpendicular directions SHALL move the character diagonally at the
same speed as straight movement. WASD and the arrow keys SHALL both work.

#### Scenario: Walk in one direction
- **WHEN** the player holds the "right" input (D or Right arrow)
- **THEN** the character moves to the right until the input is released

#### Scenario: Stop on release
- **WHEN** the player releases all direction inputs
- **THEN** the character stops moving on the next frame

#### Scenario: Diagonal is not faster
- **WHEN** the player holds "up" and "right" together
- **THEN** the character moves up-right at the same speed as when holding only "right"

### Requirement: Walls and furniture block the player
The player character SHALL NOT pass through the room's walls, desks or other solid
furniture. When moving into a solid at an angle, the character SHALL slide along it instead
of stopping dead.

#### Scenario: Walk into a wall
- **WHEN** the player holds a direction toward an outer wall
- **THEN** the character stops at the wall and never ends up inside or beyond it

#### Scenario: Slide along a wall
- **WHEN** the player is touching a wall on the left and holds "up" and "left"
- **THEN** the character keeps moving up along the wall

#### Scenario: Cannot leave the room
- **WHEN** the player walks along the full edge of the room in every direction
- **THEN** there is no gap where the character can leave the room

### Requirement: NPCs and objects are solid
NPCs and interactable objects SHALL block the player character the same way furniture
does, so the player stands next to them, not on top of them.

#### Scenario: Walk into an NPC
- **WHEN** the player holds a direction toward an NPC
- **THEN** the character stops next to the NPC and does not overlap it
