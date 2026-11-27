# run-clock Specification

## Purpose

Defines the investigation clock: the real-time countdown to the 5 PM meeting, how it is
shown as an office clock, how other systems pause it, and what happens when it runs out.

## Requirements

### Requirement: Countdown length comes from data
The investigation countdown SHALL last a fixed number of real-time seconds read from a game
data file. The default value SHALL be 900 seconds (15:00). Changing the value in the data
file SHALL change the countdown length without code changes.

#### Scenario: Default length
- **WHEN** the investigation starts with the shipped data file
- **THEN** the countdown has 15:00 (900 seconds) remaining

#### Scenario: Tuned length
- **WHEN** the data file sets the countdown to 60 seconds and the investigation starts
- **THEN** the countdown reaches 0:00 after 60 seconds of running time

### Requirement: Clock is stopped until Start
The countdown SHALL NOT run before the player presses Start on the briefing screen. While
the briefing screen is shown, the remaining time SHALL stay at its full length and the
office time SHALL read 09:00.

#### Scenario: Waiting on the briefing
- **WHEN** the player stays on the briefing screen for 30 seconds without pressing Start
- **THEN** the remaining time is still the full countdown and the office time is 09:00

#### Scenario: Start begins the countdown
- **WHEN** the player presses Start
- **THEN** the countdown begins running from its full length

### Requirement: Countdown runs in real time
While running, the countdown SHALL decrease by the real time that passes, independent of
frame rate, and SHALL never go below 0:00.

#### Scenario: Ten seconds pass
- **WHEN** the countdown is running and 10 seconds of real time pass
- **THEN** the remaining time is 10 seconds less than before

#### Scenario: No negative time
- **WHEN** more real time passes than the remaining time
- **THEN** the remaining time is exactly 0:00

### Requirement: Office clock display
During the investigation the office SHALL show the time as an office clock in 24-hour
`HH:MM` format. The office time SHALL move linearly from 09:00 (full countdown remaining)
to 17:00 (0:00 remaining), rounded down to the whole in-game minute.

#### Scenario: Investigation begins
- **WHEN** the player enters the office after pressing Start
- **THEN** the office clock shows `09:00`

#### Scenario: Halfway
- **WHEN** half of the countdown has elapsed
- **THEN** the office clock shows `13:00`

#### Scenario: Rounding down
- **WHEN** the default 900-second countdown has run for 100 seconds (53.33 in-game minutes
  elapsed)
- **THEN** the office clock shows `09:53`

#### Scenario: Time runs out
- **WHEN** the remaining time reaches 0:00
- **THEN** the office time is `17:00`

### Requirement: Other systems can pause the clock
Any game system SHALL be able to pause the countdown with a named reason and resume it with
the same reason. The countdown SHALL run only when no reason holds it paused. Pausing with a
reason that already holds it SHALL have no extra effect, and resuming a reason that does not
hold it SHALL do nothing.

#### Scenario: Pause stops time
- **WHEN** a system pauses the clock and 10 seconds of real time pass
- **THEN** the remaining time and the office clock do not change

#### Scenario: Resume continues time
- **WHEN** the system that paused the clock resumes it with the same reason
- **THEN** the countdown runs again from the remaining time it had when paused

#### Scenario: Two pause reasons
- **WHEN** two systems pause the clock with different reasons and only one of them resumes
- **THEN** the clock stays paused until the second reason is also resumed

#### Scenario: Same reason twice
- **WHEN** a system pauses the clock twice with the same reason and then resumes it once
- **THEN** the clock runs again

#### Scenario: Unknown resume
- **WHEN** a system resumes a reason that is not holding the clock
- **THEN** nothing changes

### Requirement: Clock reports when time runs out
When the remaining time reaches 0:00 the clock SHALL stop and report "time up" exactly once.
After that, pausing, resuming or more passing time SHALL NOT change the clock or report
"time up" again.

#### Scenario: Time up is reported once
- **WHEN** the countdown reaches 0:00 and more real time passes
- **THEN** "time up" has been reported exactly once and the remaining time stays 0:00

#### Scenario: Pause at the last moment
- **WHEN** the clock is paused with less than one second remaining
- **THEN** "time up" is not reported until the clock is resumed and the time runs out
