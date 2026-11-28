# fact-discovery Specification

## Purpose

Keeps the one shared record of which Truth Sheet facts the player has found in this run,
so artifacts, dialogue and the clue board agree on what the player knows.

## Requirements

### Requirement: Revealed facts are recorded once, in order
The run SHALL keep a list of revealed fact ids in the order they were first revealed.
Revealing a fact that is already in the list SHALL NOT add it again or change the order.
Only ids of facts in the run's Truth Sheet (chain facts and red herrings) SHALL be
accepted; any other id SHALL be ignored.

#### Scenario: First reveal
- **WHEN** fact `A` is revealed and then fact `B` is revealed
- **THEN** the revealed list is `[A, B]`

#### Scenario: Reveal again
- **WHEN** fact `A` is revealed a second time
- **THEN** the revealed list is still `[A, B]`

#### Scenario: Unknown fact
- **WHEN** an id that is not in the run's Truth Sheet is revealed
- **THEN** the revealed list does not change

### Requirement: New reveals are announced
Each time a fact is added to the revealed list, the game SHALL announce that fact id once,
so other systems can react without polling. Repeated or ignored reveals SHALL NOT be
announced.

#### Scenario: Announce once
- **WHEN** fact `A` is revealed twice
- **THEN** exactly one announcement for `A` is made

### Requirement: Revealed facts belong to one run
The revealed list SHALL be empty when a new run starts and SHALL be cleared together with
the rest of the run state.

#### Scenario: New run
- **WHEN** a new run starts
- **THEN** the revealed list is empty
