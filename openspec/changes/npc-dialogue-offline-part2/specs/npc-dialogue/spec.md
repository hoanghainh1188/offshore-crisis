# Spec Delta

## MODIFIED Requirements

### Requirement: NPCs with dialogue open the panel
Interacting with an NPC that has dialogue content, or with the Meeting Room Screen for the
remote client PM, SHALL open the dialogue panel for that NPC, showing the NPC's name and
role. All five "Wrong Delivery" NPCs (Linh, Trang, Minh, Hana, and Tanaka-san via the
Meeting Room Screen) SHALL have dialogue content. Interacting with any other object (such
as the Document Shelf or PC Terminal) SHALL NOT open the dialogue panel. The interaction
log line for the interacted target SHALL still be written.

#### Scenario: Talk to Linh
- **WHEN** the player stands next to Linh and presses the interact key
- **THEN** the dialogue panel opens with "Linh" and "Dev lead" and
  `[interact] npc:linh "Linh"` is logged

#### Scenario: Talk to Minh in the office
- **WHEN** the player stands next to Minh and presses the interact key
- **THEN** the dialogue panel opens with "Minh" and "Junior dev" and
  `[interact] npc:minh "Minh"` is logged

#### Scenario: Talk to Hana in the office
- **WHEN** the player stands next to Hana and presses the interact key
- **THEN** the dialogue panel opens with "Hana" and "Comtor (interpreter)" and
  `[interact] npc:hana "Hana"` is logged

#### Scenario: Call Tanaka-san via the Meeting Room Screen
- **WHEN** the player stands next to the Meeting Room Screen and presses the interact key
- **THEN** the dialogue panel opens with "Tanaka-san" and "Client PM, Kazegumo Logistics"
  and `[interact] object:meeting_screen "Meeting Room Screen"` is logged

#### Scenario: Object
- **WHEN** the player interacts with the Document Shelf
- **THEN** the dialogue panel does not open

### Requirement: Asking costs in-game time once
Asking a question for the first time in a run SHALL advance the office time by the
question cost from a data file (default 15 in-game minutes for NPCs in the room, and a
higher remote cost — default 30 in-game minutes — for calling Tanaka-san via the Meeting
Room Screen). Opening the dialogue panel SHALL NOT cost time. Asking the same question
again SHALL show the same answer, cost nothing and reveal nothing. Asked questions SHALL
be marked in the list. While the panel is open the clock SHALL keep running in real time
as well.

#### Scenario: First ask
- **WHEN** the office time is 10:00 and the player asks an in-room NPC a new question
- **THEN** the office time is at least 10:15

#### Scenario: Remote first ask
- **WHEN** the office time is 10:00 and the player asks Tanaka-san a new question via the
  Meeting Room Screen
- **THEN** the office time is at least 10:30

#### Scenario: Ask again
- **WHEN** the player asks a question they already asked in this run
- **THEN** the office time does not jump, the answer is the same and no reveal is
  announced

#### Scenario: Remote ask again
- **WHEN** the player asks Tanaka-san a question they already asked in this run
- **THEN** the office time does not jump, the answer is the same and no reveal is
  announced

#### Scenario: Marked as asked
- **WHEN** a question has been asked
- **THEN** it is shown as asked in the list, also after closing and reopening the panel

#### Scenario: Question that ends the day
- **WHEN** the office time is 16:50 and the player asks an in-room NPC a new question
- **THEN** the run moves to the meeting screen

#### Scenario: Remote question that ends the day
- **WHEN** the office time is 16:35 and the player asks Tanaka-san a new question
- **THEN** the run moves to the meeting screen

## ADDED Requirements

### Requirement: Content for Minh, Hana, and Tanaka-san
The shipped dialogue data file SHALL include 6 to 8 pre-written questions each for Minh,
Hana, and Tanaka-san, including at least one locked follow-up per NPC, covering every fact
that each NPC can hold in the "Wrong Delivery" case template, with answers for every
attitude in that NPC's pool (`nervous` for Minh; `protective` and `honest` for Hana;
`indirect` for Tanaka-san). All names and events SHALL be fictional, and all replies SHALL
work offline with no network calls.

#### Scenario: Shipped content loads for all five NPCs
- **WHEN** the shipped dialogue file is loaded against the "Wrong Delivery" template
- **THEN** loading succeeds, each of the five NPCs (Linh, Trang, Minh, Hana, Tanaka-san) has
  6 to 8 questions, and every fact any of them can hold has a question for that NPC

#### Scenario: Hana holds a fact with protective attitude
- **WHEN** the Truth Sheet gives `fact_lit_unconfirmed_note` to `npc:hana`, Hana's
  attitude is `protective`, and the player asks Hana the question about her translation note
- **THEN** the panel shows that question's `protective` "holds" answer and
  `fact_lit_unconfirmed_note` is revealed

#### Scenario: Tanaka-san's follow-up on はい
- **WHEN** `fact_py_hai_recorded` is revealed, the player talks to Tanaka-san via the
  Meeting Room Screen, the Truth Sheet gives `fact_py_check_internally` to `npc:tanaka`,
  and the player asks the unlocked follow-up about his reply at the design review
- **THEN** the panel shows Tanaka-san's `indirect` "holds" answer, costs the remote
  question time once, and reveals `fact_py_check_internally`

#### Scenario: Minh's un-ticketed export follow-up
- **WHEN** `fact_coc_chat_agreement` is revealed, the Truth Sheet gives
  `fact_coc_no_ticket` to `npc:minh`, and the player asks Minh why he did not build the
  chat-agreed change
- **THEN** the panel shows Minh's `nervous` "holds" answer and reveals
  `fact_coc_no_ticket`

### Requirement: Chain facts are reachable without lock cycles
For every generated case across seeds 1 to 300, every chain fact in that run's Truth Sheet
SHALL be reachable starting from always-unlocked questions and documents, without deadlocked
unlock cycles between NPCs.

#### Scenario: Every chain fact is reachable across 300 seeds
- **WHEN** reachability is simulated from always-unlocked questions and all artifacts until
  a fixed point for seeds 1 through 300
- **THEN** every fact in the run's `chain` is reached in every seed

### Requirement: Honest and indirect non-held answers do not mislead
When an NPC does not hold a question's fact, an `honest` answer (for Linh, Trang, or Hana)
and an `indirect` answer (for Tanaka-san) SHALL NOT claim or imply that the NPC holds or
knows that fact.

#### Scenario: Non-held answers avoid false claims
- **WHEN** Hana has attitude `honest` or Tanaka-san has attitude `indirect` and the NPC
  does not hold a question's fact
- **THEN** the `not_held` answer does not state the fact as something the NPC did or knows
