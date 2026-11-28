# Spec Delta

## Purpose

Gives the player one place to see every fact they have found in this run as clue cards,
and to pin and link those cards while they reason about the case. Pins and links are a
thinking aid only and do not change the run.

## ADDED Requirements

### Requirement: Every revealed fact has a clue card
The board SHALL hold exactly one clue card for each fact in the revealed list
(`fact-discovery`), in reveal order, and no other cards. Red herrings SHALL get cards like
chain facts, with nothing on the card telling them apart.

#### Scenario: Cards follow the revealed list
- **WHEN** facts `A` and `B` have been revealed in that order and the board is opened
- **THEN** the board holds two cards, `A` then `B`

#### Scenario: Nothing revealed yet
- **WHEN** the board is opened before any fact is revealed
- **THEN** the board holds no cards and says that no clues have been found yet

#### Scenario: Repeated reveal
- **WHEN** fact `A` is revealed twice
- **THEN** the board holds one card for `A`

#### Scenario: Red herring looks like any other card
- **WHEN** a red herring fact and a chain fact have both been revealed
- **THEN** both cards show only their text and source, with no mark that sets one apart

### Requirement: Card shows the fact text and its source
A card SHALL show the fact's Truth Sheet text unchanged and a source label naming where
the fact was found this run: the NPC's display name for `npc:<id>` holders, or the
document's display name for `artifact:<type>` holders. Japanese characters in card text
SHALL draw as readable glyphs on desktop and web.

#### Scenario: Fact from an NPC
- **WHEN** a fact held by `npc:hana` is revealed and the board is opened
- **THEN** its card shows the fact text and the source label "Hana"

#### Scenario: Fact from a document
- **WHEN** a fact held by `artifact:git_log` is revealed and the board is opened
- **THEN** its card shows the fact text and the source label "Git log"

#### Scenario: Japanese text on a card
- **WHEN** a fact whose text contains 月次締め is on the board in the web build
- **THEN** those characters are drawn as Japanese glyphs

### Requirement: New reveals reach an open board
A fact revealed while the board is open SHALL get its card in the tray at once, without
closing and reopening the board.

#### Scenario: Reveal while the board is open
- **WHEN** the board is open and a new fact is revealed
- **THEN** a card for that fact appears in the tray while the board stays open

### Requirement: Board key opens and closes the board anywhere in the investigation
During the investigation, the board key SHALL open the board when it is closed and close
it when it is open. This SHALL work in the office and while the artifact viewer or the
dialogue panel is open. The key SHALL do nothing on the briefing and meeting screens.

#### Scenario: Open from the office
- **WHEN** the player is walking in the office and presses the board key
- **THEN** the board opens

#### Scenario: Toggle closed
- **WHEN** the board is open and the player presses the board key
- **THEN** the board closes

#### Scenario: Open over the viewer
- **WHEN** the artifact viewer is open and the player presses the board key
- **THEN** the board opens on top of the viewer

#### Scenario: Open over the dialogue panel
- **WHEN** the dialogue panel is open and the player presses the board key
- **THEN** the board opens on top of the dialogue panel

#### Scenario: Not on the briefing screen
- **WHEN** the briefing screen is shown and the player presses the board key
- **THEN** no board opens

### Requirement: Closing the board returns to what was open before
Esc, the Close button or the board key SHALL close the board. Closing SHALL return to the
viewer or dialogue panel if one was open under it, otherwise give control back to the
player. One Esc press SHALL close only the board, not the panel under it.

#### Scenario: Close with Esc in the office
- **WHEN** the board was opened from the office and the player presses Esc
- **THEN** the board closes and the player can walk again

#### Scenario: Close over a panel
- **WHEN** the board was opened over the artifact viewer and the player presses Esc once
- **THEN** the board closes, the viewer is still open, and the player still cannot move

### Requirement: The board does not stop the clock or free the player
While the board is open the investigation clock SHALL keep running, the player character
SHALL NOT move, and the interact key SHALL NOT trigger interactions in the office. If time
runs out while the board is open, the run SHALL move to the meeting screen as usual.

#### Scenario: Clock keeps running
- **WHEN** the board stays open for 5 seconds of a running clock
- **THEN** the remaining time is 5 seconds less

#### Scenario: Frozen player
- **WHEN** the board is open and the player holds a movement key
- **THEN** the player character does not move

#### Scenario: Time up with the board open
- **WHEN** the clock reaches 17:00 while the board is open
- **THEN** the meeting screen is shown and the board is gone

### Requirement: New cards start in the tray
A new card SHALL start unpinned, in the tray. The tray SHALL list unpinned cards in
reveal order and SHALL scroll when they do not fit.

#### Scenario: Fresh card
- **WHEN** a fact is revealed and the board is opened
- **THEN** its card is in the tray and not on the board area

### Requirement: Player can pin a card onto the board
The player SHALL be able to pin a tray card onto the board area. A pinned card SHALL
leave the tray and stay at the place it was pinned, inside the board area.

#### Scenario: Pin a card
- **WHEN** the player pins card `A`
- **THEN** `A` is no longer in the tray and is shown on the board area

#### Scenario: Pins are kept while the board is closed
- **WHEN** the player pins card `A`, closes the board and opens it again
- **THEN** `A` is still pinned at the same place

### Requirement: Player can move a pinned card
The player SHALL be able to drag a pinned card to a new place on the board area. A card
SHALL stay fully inside the board area. Links to the card SHALL follow it.

#### Scenario: Drag a card
- **WHEN** the player drags pinned card `A` to a new place
- **THEN** `A` is shown at the new place and its links end at its new position

#### Scenario: Drag past the edge
- **WHEN** the player drags a pinned card past the edge of the board area
- **THEN** the card stops at the edge, fully visible

### Requirement: Player can unpin a card
The player SHALL be able to unpin a pinned card. An unpinned card SHALL go back to the
tray in its reveal-order place, and every link to it SHALL be removed.

#### Scenario: Unpin a linked card
- **WHEN** pinned cards `A` and `B` are linked and the player unpins `A`
- **THEN** `A` is back in the tray and the link between `A` and `B` is gone

### Requirement: Player can link two pinned cards
The player SHALL be able to link two different pinned cards by selecting one and then the
other. A link SHALL be drawn as a line between the two cards. Links SHALL be undirected;
there SHALL be at most one link per pair, and a card SHALL NOT link to itself.

#### Scenario: Draw a link
- **WHEN** cards `A` and `B` are pinned and the player selects `A` then `B`
- **THEN** a line joins `A` and `B`

#### Scenario: Same pair, either order
- **WHEN** `A` and `B` are linked and the player selects `B` then `A`
- **THEN** the link between `A` and `B` is removed and no second link is made

#### Scenario: No self link
- **WHEN** the player selects pinned card `A` twice
- **THEN** no link is made and `A` is no longer selected

#### Scenario: Tray cards cannot be linked
- **WHEN** card `C` is in the tray
- **THEN** the player cannot select `C` as one end of a link

### Requirement: Pins and links are not scored
Pinning, moving, unpinning and linking SHALL NOT reveal facts, unlock questions, advance
the office time or change any other part of the run. The run SHALL keep the list of
pinned fact ids and the links so later screens can read them.

#### Scenario: No time cost
- **WHEN** the player pins three cards and links two of them
- **THEN** the office time and the revealed list are the same as before

#### Scenario: Pins are readable
- **WHEN** the player has pinned `A` and `B`
- **THEN** the run's pinned list holds `A` and `B`

### Requirement: The board belongs to one run
Pins, card positions and links SHALL be cleared when a new run starts, together with the
rest of the run state.

#### Scenario: New run
- **WHEN** a new run starts after a run where cards were pinned and linked
- **THEN** the board has no cards, no pins and no links
