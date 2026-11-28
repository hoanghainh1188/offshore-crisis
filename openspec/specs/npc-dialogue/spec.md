# npc-dialogue Specification

## Purpose

Lets the player question the people in the office with pre-written answers that follow the
run's Truth Sheet, so talking reveals facts, costs time, and works without any network.

## Requirements

### Requirement: NPCs with dialogue open the panel
Interacting with an NPC that has dialogue content SHALL open the dialogue panel for that
NPC, showing the NPC's name and role. In this part only Linh and Trang have content.
Interacting with any other target SHALL NOT open the panel. The interaction log line SHALL
still be written.

#### Scenario: Talk to Linh
- **WHEN** the player stands next to Linh and presses the interact key
- **THEN** the dialogue panel opens with "Linh" and "Dev lead" and
  `[interact] npc:linh "Linh"` is logged

#### Scenario: Object
- **WHEN** the player interacts with the Meeting Room Screen
- **THEN** the dialogue panel does not open

### Requirement: Question list
The panel SHALL list the NPC's unlocked questions in data-file order. A question with an
unlock condition SHALL be hidden until at least one of its listed facts is in the
revealed-facts list, and SHALL then appear in its data-file position. The list SHALL be the
same for every root cause, so it does not hint at the answer.

#### Scenario: Locked question hidden
- **WHEN** a question needs fact `F` to unlock and `F` has not been revealed
- **THEN** the question is not listed

#### Scenario: Unlock by reading
- **WHEN** the player reveals `F` by reading a document and then talks to the NPC
- **THEN** the question is listed

#### Scenario: Unlock while talking
- **WHEN** an answer in the open panel reveals `F`
- **THEN** the question that needs `F` appears in the list without closing the panel

### Requirement: Answer follows the Truth Sheet and attitude
Each question SHALL be about one fact or about none. When this NPC is the fact's holder in
the run's Truth Sheet, the panel SHALL show the question's "holds" answer for the NPC's
attitude this run. Otherwise, or when the question is about no fact, it SHALL show the
"does not hold" answer for that attitude. Every question SHALL have answers for every
attitude in that NPC's attitude pool.

#### Scenario: NPC holds the fact
- **WHEN** the Truth Sheet gives `fact_lit_ticket_calendar` to `npc:linh`, Linh's attitude
  is `defensive`, and the player asks Linh the question about that fact
- **THEN** the panel shows that question's defensive "holds" answer

#### Scenario: Fact held elsewhere
- **WHEN** the Truth Sheet gives `fact_lit_ticket_calendar` to `artifact:ticket` and the
  player asks Linh the same question
- **THEN** the panel shows that question's "does not hold" answer for Linh's attitude and
  nothing is revealed

#### Scenario: Fact not in this case
- **WHEN** the run's root cause is `polite_yes` and the player asks Linh about the chat
  agreement (`fact_coc_chat_agreement`)
- **THEN** the panel shows a "does not hold" answer and nothing is revealed

### Requirement: Asking reveals the fact
When a "holds" answer is shown for the first time, the fact SHALL be revealed through the
revealed-facts list (see `fact-discovery`). "Does not hold" answers SHALL NOT reveal
anything.

#### Scenario: Reveal by asking
- **WHEN** Linh holds `fact_lit_ticket_calendar` and the player asks about it
- **THEN** `fact_lit_ticket_calendar` is in the revealed list

### Requirement: Asking costs in-game time once
Asking a question for the first time in a run SHALL advance the office time by the
question cost from a data file (default 15 in-game minutes). Asking the same question
again SHALL show the same answer, cost nothing and reveal nothing. Asked questions SHALL
be marked in the list. While the panel is open the clock SHALL keep running in real time
as well.

#### Scenario: First ask
- **WHEN** the office time is 10:00 and the player asks a new question
- **THEN** the office time is at least 10:15

#### Scenario: Ask again
- **WHEN** the player asks a question they already asked in this run
- **THEN** the office time does not jump, the answer is the same and no reveal is
  announced

#### Scenario: Marked as asked
- **WHEN** a question has been asked
- **THEN** it is shown as asked in the list, also after closing and reopening the panel

#### Scenario: Question that ends the day
- **WHEN** the office time is 16:50 and the player asks a new question
- **THEN** the run moves to the meeting screen

### Requirement: Panel behaves like the viewer
While the panel is open the player character SHALL NOT move and the interact key SHALL NOT
trigger interactions in the office. Esc or the Close button SHALL close the panel and give
control back. The first listed question SHALL have keyboard focus when the panel opens.

#### Scenario: Frozen player
- **WHEN** the panel is open and the player holds a movement key
- **THEN** the player character does not move

#### Scenario: Close with Esc
- **WHEN** the panel is open and the player presses Esc
- **THEN** the panel closes and the player can walk again

### Requirement: Dialogue content is data
Questions and answers SHALL be read from a dialogue data file. Loading SHALL fail with an
error naming the file and the problem when an NPC id or fact id is not in the case
template, a question id is repeated, or a question lacks an answer for an attitude in that
NPC's pool. All names and events in it SHALL be fictional.

#### Scenario: Shipped content loads
- **WHEN** the shipped dialogue file is loaded against the "Wrong Delivery" template
- **THEN** loading succeeds, and every fact that Linh or Trang can hold has a question for
  that NPC

#### Scenario: Missing attitude answer
- **WHEN** a question for Linh has no answer for `defensive`
- **THEN** loading fails with an error naming the question id and `defensive`

### Requirement: Follow-up questions for git log and spec facts
The shipped dialogue content SHALL include a follow-up question for Linh that unlocks on
`fact_coc_no_ticket` and asks where the un-ticketed export work came from, and a follow-up
question for Trang that unlocks on `fact_lit_jp_spec_closing` and asks whether her tests
checked the closing period. Their answers SHALL follow the same Truth Sheet and attitude
rules as every other question.

#### Scenario: Linh's follow-up when she holds the chat agreement
- **WHEN** Linh's follow-up about commits with no ticket is unlocked, the Truth Sheet gives
  `fact_coc_chat_agreement` to `npc:linh`, and the player asks it
- **THEN** the panel shows the "holds" answer for Linh's attitude and
  `fact_coc_chat_agreement` is revealed

#### Scenario: Linh's follow-up when the chat log holds it
- **WHEN** Linh's follow-up is unlocked and `fact_coc_chat_agreement` is held by
  `artifact:chat_log`
- **THEN** the panel shows a "does not hold" answer for Linh's attitude and nothing is
  revealed

#### Scenario: Trang's follow-up
- **WHEN** Trang's follow-up about 月次締め is unlocked and the player asks it
- **THEN** the panel shows Trang's answer for her attitude, it costs the question time
  once, and it reveals nothing

#### Scenario: Content still loads
- **WHEN** the shipped dialogue file with the follow-ups is loaded against the "Wrong
  Delivery" template
- **THEN** loading succeeds and both follow-ups have answers for every attitude in their
  NPC's pool
