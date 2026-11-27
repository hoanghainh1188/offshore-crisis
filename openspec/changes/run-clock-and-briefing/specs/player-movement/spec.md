# Spec Delta

## MODIFIED Requirements

### Requirement: Game starts in the office room
The office room SHALL be shown after the player presses Start on the briefing screen, with
the player character placed at the room entrance and able to move. The game itself SHALL
open on the briefing screen (see `run-flow`), not directly in the office room.

#### Scenario: Launch the game
- **WHEN** the player starts the game (desktop run or web build) and presses Start on the
  briefing screen
- **THEN** the office room is shown and the player character is at the entrance
