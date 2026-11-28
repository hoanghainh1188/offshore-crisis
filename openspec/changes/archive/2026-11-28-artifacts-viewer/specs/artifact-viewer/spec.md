# Spec Delta

## Purpose

Lets the player read the case documents in the office — the first way to find facts —
with document content built from the run's Truth Sheet.

## ADDED Requirements

### Requirement: Document Shelf opens the viewer
Interacting with the Document Shelf SHALL open the artifact viewer on top of the office.
Interacting with any other target SHALL NOT open it. The existing interaction log line
SHALL still be written.

#### Scenario: Open from the shelf
- **WHEN** the player stands next to the Document Shelf and presses the interact key
- **THEN** the artifact viewer is shown and `[interact] object:document_shelf "Document Shelf"` is logged

#### Scenario: Other targets
- **WHEN** the player interacts with Linh
- **THEN** the artifact viewer is not shown

### Requirement: Viewer lists the available artifact types
The viewer SHALL list one document for each supported artifact type, always in this order:
Ticket, Chat log, Meeting notes. All three SHALL be listed in every run, whether or not they
hold a fact in this run, so the list does not hint at where the facts are.

#### Scenario: List on open
- **WHEN** the viewer opens
- **THEN** it lists exactly Ticket, Chat log and Meeting notes, in that order

### Requirement: Documents are built from the Truth Sheet
A document SHALL show every fact (chain fact or red herring) whose holder in the run's
Truth Sheet is that artifact type, as its fact text, mixed with filler lines for that type
taken from a data file. A document SHALL NOT show facts held by anyone else. The same
Truth Sheet SHALL always produce the same document text.

#### Scenario: Fact held by the chat log
- **WHEN** the run's Truth Sheet gives a fact the holder `artifact:chat_log` and the player
  opens Chat log
- **THEN** the document contains that fact's text

#### Scenario: Fact held elsewhere
- **WHEN** a fact's holder is `npc:linh` or `artifact:ticket` and the player opens Chat log
- **THEN** the Chat log document does not contain that fact's text

#### Scenario: Artifact with no facts this run
- **WHEN** no fact in the Truth Sheet is held by `artifact:meeting_notes` and the player
  opens Meeting notes
- **THEN** the document shows only filler lines and reveals nothing

#### Scenario: Same case, same text
- **WHEN** the same document is opened twice in one run
- **THEN** both times it shows the same lines in the same order

### Requirement: Opening a document reveals its facts
Opening a document SHALL reveal every fact it shows (see `fact-discovery`). Opening it
again SHALL NOT reveal anything new.

#### Scenario: Reveal on open
- **WHEN** the player opens a document that shows two facts
- **THEN** both fact ids are in the revealed list

#### Scenario: Reopen
- **WHEN** the player opens the same document again
- **THEN** no new reveal is announced

### Requirement: Reading does not stop the clock or the run
While the viewer is open the investigation clock SHALL keep running, the player character
SHALL NOT move, and the interact key SHALL NOT trigger interactions in the office. Closing
the viewer (Close button or Esc) SHALL return control to the player. If time runs out while
the viewer is open, the run SHALL move to the meeting screen as usual.

#### Scenario: Clock keeps running
- **WHEN** the viewer stays open for 5 seconds of a running clock
- **THEN** the remaining time is 5 seconds less

#### Scenario: Frozen player
- **WHEN** the viewer is open and the player holds a movement key
- **THEN** the player character does not move

#### Scenario: Close with Esc
- **WHEN** the viewer is open and the player presses Esc
- **THEN** the viewer closes and the player can walk again

#### Scenario: Time up while reading
- **WHEN** the clock reaches 17:00 while the viewer is open
- **THEN** the meeting screen is shown and the viewer is gone

### Requirement: Japanese text is readable on every platform
Document text that contains Japanese characters SHALL display them as readable glyphs on
the desktop and web builds, not as empty boxes.

#### Scenario: Japanese in the meeting notes
- **WHEN** a document containing はい or 月次締め is opened in the web build
- **THEN** those characters are drawn as Japanese glyphs
