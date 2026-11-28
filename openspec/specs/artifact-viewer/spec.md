# artifact-viewer Specification

## Purpose

Lets the player read the case documents in the office — the first way to find facts —
with document content built from the run's Truth Sheet.

## Requirements

### Requirement: Document Shelf opens the viewer
Interacting with the Document Shelf or the PC Terminal SHALL open the artifact viewer on
top of the office. Both SHALL open the same viewer with the same documents. Interacting
with any other target SHALL NOT open it. The existing interaction log line SHALL still be
written.

#### Scenario: Open from the shelf
- **WHEN** the player stands next to the Document Shelf and presses the interact key
- **THEN** the artifact viewer is shown and `[interact] object:document_shelf "Document Shelf"` is logged

#### Scenario: Open from the PC Terminal
- **WHEN** the player stands next to the PC Terminal and presses the interact key
- **THEN** the artifact viewer is shown with the same document list and
  `[interact] object:pc_terminal "PC Terminal"` is logged

#### Scenario: Other targets
- **WHEN** the player interacts with Linh
- **THEN** the artifact viewer is not shown

### Requirement: Viewer lists the available artifact types
The viewer SHALL list one document for each supported artifact type, always in this order:
Ticket, Git log, Chat log, Spec document, Meeting notes. All five SHALL be listed in every
run, whether or not they hold a fact in this run, so the list does not hint at where the
facts are.

#### Scenario: List on open
- **WHEN** the viewer opens
- **THEN** it lists exactly Ticket, Git log, Chat log, Spec document and Meeting notes, in
  that order

#### Scenario: Same list from both entry points
- **WHEN** the viewer is opened once from the Document Shelf and once from the PC Terminal
- **THEN** both times it lists the same five documents in the same order

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

### Requirement: Git log reads as a commit history
The Git log document SHALL show filler lines written as commits (short hash, date, author,
message) for the fictional project, and SHALL show every fact held by `artifact:git_log`
this run, following the same Truth Sheet rules as the other documents.

#### Scenario: Fact held by the git log
- **WHEN** the run's Truth Sheet gives `rh_timezone_config` the holder `artifact:git_log`
  and the player opens Git log
- **THEN** the document contains that fact's text and at least one commit filler line

#### Scenario: Git log holds nothing
- **WHEN** no fact in the Truth Sheet is held by `artifact:git_log` and the player opens
  Git log
- **THEN** the document shows only commit filler lines and reveals nothing

### Requirement: Spec document has revision history, Japanese original and translation
The Spec document SHALL show three titled sections in this order: Revision history,
Japanese original (日本語原文), English translation. Each section SHALL hold filler lines
from the data file. Each fact held by `artifact:spec_doc` SHALL appear in the section the
data file assigns to it, and nowhere else in the document.

#### Scenario: Sections in order
- **WHEN** the player opens Spec document
- **THEN** the headings Revision history, Japanese original and English translation
  appear in that order, each followed by at least one line

#### Scenario: Unchanged spec in the revision history
- **WHEN** the Truth Sheet gives `fact_coc_spec_unchanged` the holder `artifact:spec_doc`
  and the player opens Spec document
- **THEN** that fact's text appears between the Revision history heading and the Japanese
  original heading

#### Scenario: Closing period in the Japanese original
- **WHEN** the Truth Sheet gives `fact_lit_jp_spec_closing` the holder `artifact:spec_doc`
  and the player opens Spec document
- **THEN** that fact's text appears between the Japanese original heading and the English
  translation heading, and 月次締め is drawn as Japanese glyphs

#### Scenario: Same case, same sections
- **WHEN** the Spec document is opened twice in one run
- **THEN** both times it shows the same sections and lines in the same order

### Requirement: Reading can unlock follow-up questions
A fact revealed by opening a document SHALL count for NPC question unlocks in the same way
as a fact revealed by talking (see `npc-dialogue`). Reading SHALL NOT cost in-game time;
the clock only keeps running in real time.

#### Scenario: Git log unlocks a question for Linh
- **WHEN** the Truth Sheet gives `fact_coc_no_ticket` to `artifact:git_log`, the player
  opens Git log and then talks to Linh
- **THEN** Linh's question list includes the follow-up about commits with no ticket

#### Scenario: Spec unlocks a question for Trang
- **WHEN** the Truth Sheet gives `fact_lit_jp_spec_closing` to `artifact:spec_doc`, the
  player opens Spec document and then talks to Trang
- **THEN** Trang's question list includes the follow-up about testing against 月次締め

#### Scenario: Not read yet
- **WHEN** the player has not opened any document that reveals `fact_coc_no_ticket`
- **THEN** Linh's follow-up about commits with no ticket is not listed

#### Scenario: Reading is free in game time
- **WHEN** the office time is 10:00 with the clock paused and the player opens Git log
- **THEN** the office time is still 10:00
