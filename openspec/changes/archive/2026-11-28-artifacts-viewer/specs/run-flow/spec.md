# Spec Delta

## MODIFIED Requirements

### Requirement: Start begins the investigation
Pressing Start (clicking the button, or pressing Enter or Space while it has focus) SHALL
leave the briefing screen, show the office room with the player at the entrance, generate
the run's Truth Sheet from the "Wrong Delivery" template with a random seed, and start the
investigation clock. The seed SHALL be written to the log as `[case] seed <n>`; the root
cause SHALL NOT be logged. Start SHALL only take effect once per run.

#### Scenario: Click Start
- **WHEN** the player clicks Start on the briefing screen
- **THEN** the office room is shown, the player is at the entrance, and the office clock
  shows `09:00` and is running

#### Scenario: Keyboard Start
- **WHEN** the Start button has focus and the player presses Enter
- **THEN** the same happens as clicking Start

#### Scenario: Start button has focus on open
- **WHEN** the briefing screen opens
- **THEN** the Start button already has keyboard focus

#### Scenario: Case generated on Start
- **WHEN** the player presses Start
- **THEN** the run has a Truth Sheet, the log contains one line `[case] seed <n>`, and the
  log does not contain the root cause id or description

#### Scenario: Logged seed reproduces the case
- **WHEN** a case is generated again from the "Wrong Delivery" template with the logged
  seed
- **THEN** the new Truth Sheet is identical to the run's Truth Sheet

#### Scenario: No case before Start
- **WHEN** the briefing screen is shown and Start has not been pressed
- **THEN** the run has no Truth Sheet yet
