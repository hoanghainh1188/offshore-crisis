# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
