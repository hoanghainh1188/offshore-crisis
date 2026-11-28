# Spec Delta

## ADDED Requirements

### Requirement: Systems can advance the office time
Game systems SHALL be able to move the office time forward by a whole number of in-game
minutes. The remaining real time SHALL drop by the same share of the countdown (one
in-game minute = countdown length ÷ 480). Advancing SHALL work while the clock is paused,
SHALL never take the remaining time below 0:00, and SHALL report "time up" once if it
reaches 0:00. Advancing before Start or after time up SHALL do nothing.

#### Scenario: Fifteen minutes on a default run
- **WHEN** the office time is 09:00 on the default 900-second countdown and the time is
  advanced by 15 minutes
- **THEN** the office clock shows `09:15` and 28.125 seconds of real time are gone

#### Scenario: Advance while paused
- **WHEN** the clock is paused and the time is advanced by 15 minutes
- **THEN** the office time moves forward by 15 minutes and the clock stays paused

#### Scenario: Advance past 17:00
- **WHEN** the office time is 16:50 and the time is advanced by 15 minutes
- **THEN** the office clock shows `17:00`, the remaining time is 0:00 and "time up" is
  reported once

#### Scenario: Before Start
- **WHEN** the time is advanced before the player presses Start
- **THEN** nothing changes and the office time stays `09:00`
