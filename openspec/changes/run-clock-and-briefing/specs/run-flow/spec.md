# Spec Delta

## Purpose

Defines the screens one run moves through — briefing, office investigation, meeting — and
what moves the player from one to the next.

## ADDED Requirements

### Requirement: Run opens on the briefing screen
Starting the game SHALL show the briefing screen first. The briefing screen SHALL show the
client's escalation email with a sender, a subject and a body, plus a Start button. The
office room SHALL NOT be shown and the player SHALL NOT be able to move while the briefing
is shown.

#### Scenario: Launch the game
- **WHEN** the player starts the game (desktop run or web build)
- **THEN** the briefing screen is shown with the email's sender, subject and body and a
  Start button

#### Scenario: Movement keys on the briefing
- **WHEN** the player presses WASD or the arrow keys on the briefing screen
- **THEN** no player character moves and the briefing stays on screen

### Requirement: Briefing email text comes from data
The escalation email text (sender, subject, body) SHALL be read from a game data file, not
written in code. All names and companies in it SHALL be fictional.

#### Scenario: Edit the email
- **WHEN** the subject in the data file is changed and the game is started
- **THEN** the briefing screen shows the new subject

### Requirement: Start begins the investigation
Pressing Start (clicking the button, or pressing Enter or Space while it has focus) SHALL
leave the briefing screen, show the office room with the player at the entrance and start
the investigation clock. Start SHALL only take effect once per run.

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

### Requirement: Time up moves the player to the meeting
When the investigation clock reports "time up", the game SHALL leave the office room and
show the meeting screen, whatever the player was doing. For now the meeting screen is a
placeholder that shows `17:00` and a line saying the meeting with the client has started.
It SHALL have no other interaction.

#### Scenario: Countdown reaches zero
- **WHEN** the office clock reaches 17:00
- **THEN** the office room is no longer shown and the meeting placeholder screen is shown
  with `17:00`

#### Scenario: Interrupted mid-walk
- **WHEN** the clock runs out while the player is holding a movement key
- **THEN** the meeting placeholder screen is shown and nothing moves on it

#### Scenario: Clock is stopped on the meeting screen
- **WHEN** the meeting placeholder screen is shown
- **THEN** the investigation clock no longer runs and "time up" is not reported again
