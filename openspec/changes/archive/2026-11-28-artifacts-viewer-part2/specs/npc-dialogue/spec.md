# Spec Delta

## ADDED Requirements

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
