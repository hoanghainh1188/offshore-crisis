# case-generation Specification

## Purpose

Builds the hidden Truth Sheet for one run from a case template and a seed, so every run has
a different but solvable case that later systems (artifacts, dialogue, report, grading)
read from.

## Requirements

### Requirement: Wrong Delivery template content
The game SHALL ship a "Wrong Delivery" case template as a data file. It SHALL contain three
root cause variants with ids `lost_in_translation`, `chat_only_change` and `polite_yes`,
the five NPCs `linh`, `minh`, `trang`, `hana` and `tanaka` (each with a non-empty attitude
pool drawn from `honest`, `defensive`, `vague`, `protective`, `nervous`, `indirect`), and a
red herring pool of at least three entries. All names and events SHALL be fictional.

#### Scenario: Shipped template loads
- **WHEN** the shipped "Wrong Delivery" template is loaded
- **THEN** loading succeeds and the template has the three variants, the five NPCs and at
  least three red herrings

#### Scenario: Variant shape
- **WHEN** any variant of the shipped template is inspected
- **THEN** it has a short description, a chain of 2 to 4 facts, and a fix space with at
  least one immediate fix and one prevention measure

### Requirement: Facts and holders
Every fact (chain fact or red herring) SHALL have an id unique within the template, a
one-line text, and one or more possible holders. A holder SHALL be either an NPC
(`npc:<id>`, one of the template's NPCs) or an artifact (`artifact:<type>`, where type is
one of `ticket`, `git_log`, `chat_log`, `spec_doc`, `meeting_notes`).

#### Scenario: Holder ids use the interaction format
- **WHEN** a fact's holders are read
- **THEN** each holder looks like `npc:hana` or `artifact:chat_log`

### Requirement: Invalid template is refused
Loading a template SHALL fail when it is not valid: a required field is missing, a fact id
is repeated, a chain has fewer than 2 or more than 4 facts, a holder or attitude is not
allowed, or the red herring pool is empty. On failure no template SHALL be returned and the
error SHALL name the file and the problem.

#### Scenario: Missing field
- **WHEN** a template without a `variants` field is loaded
- **THEN** loading fails with an error that names the file and `variants`, and no Truth
  Sheet can be generated from it

#### Scenario: Unknown holder
- **WHEN** a fact lists the holder `npc:nobody`
- **THEN** loading fails with an error that names the fact id and `npc:nobody`

#### Scenario: Variant that can never be solved
- **WHEN** a variant's chain facts can only be held by artifacts, or can only be held by
  one and the same holder
- **THEN** loading fails with an error that names the variant id

#### Scenario: Duplicate fact id
- **WHEN** two facts in a template share the same id
- **THEN** loading fails with an error that names the repeated id

### Requirement: Truth Sheet content
Generating a case SHALL produce a Truth Sheet with: the chosen `root_cause` (variant id and
description), the variant's `chain` of facts in template order, `knowledge` that gives each
chain fact and each chosen red herring exactly one holder taken from that fact's possible
holders, an `attitude` for every NPC taken from that NPC's attitude pool, 1 or 2 distinct
`red_herrings` from the pool, and the variant's `fix_space`.

#### Scenario: Complete Truth Sheet
- **WHEN** a case is generated from the shipped template with any seed
- **THEN** the Truth Sheet has a root cause, a chain of 2 to 4 facts, one holder for every
  chain fact and red herring, an attitude for each of the five NPCs, 1 or 2 red herrings
  and a non-empty fix space

#### Scenario: Holders come from the template
- **WHEN** a case is generated
- **THEN** every holder in `knowledge` is one of the possible holders listed for that fact

#### Scenario: Red herrings are not part of the chain
- **WHEN** a case is generated
- **THEN** no red herring id is also a chain fact id, and the red herrings are distinct

### Requirement: Case is solvable
The chain of a generated case SHALL be discoverable: at least one chain fact SHALL be held
by an NPC, and the facts SHALL NOT all be held by the same holder.

#### Scenario: Not all in one place
- **WHEN** a case is generated with any seed
- **THEN** the chain facts have at least two different holders and at least one of them is
  an NPC

### Requirement: Generation is seedable
The same template and the same seed SHALL always produce an identical Truth Sheet, on every
platform the game ships on. Different seeds SHALL be able to produce different root causes.

#### Scenario: Same seed, same case
- **WHEN** a case is generated twice from the shipped template with seed 42
- **THEN** both Truth Sheets are identical in every field

#### Scenario: All variants reachable
- **WHEN** cases are generated from the shipped template with seeds 1 to 300
- **THEN** each of the three root cause variants is chosen at least once

#### Scenario: Seed is recorded
- **WHEN** a case is generated with seed 42
- **THEN** the Truth Sheet records seed 42, so the case can be reproduced later
