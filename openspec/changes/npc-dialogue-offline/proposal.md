# Proposal

## Why

Most facts in a "Wrong Delivery" case are held by people, but the player can only read
documents so far: walking up to Linh or Trang just logs a line. Talking to people is the
first design pillar ("Read people, not just logs", GDD §2). This change is **part 1 of 2**
of `npc-dialogue-offline` (issue #8): the dialogue system with pre-written answers for the
two NPCs already in the room. The same content later becomes the fallback when the AI
backend is offline (GDD §13).

## What Changes

- **Dialogue panel:** interacting with Linh or Trang opens a panel that lists that NPC's
  questions. Picking one shows that NPC's answer. Like the artifact viewer, the run clock
  keeps running, the player is frozen, and Esc or Close returns to the office.
- **Answers follow the case:** each question is about one Truth Sheet fact (or none, for
  small talk). If this NPC holds that fact in this run, the answer states it, phrased for
  the NPC's attitude this run, and reveals it through the shared revealed-facts list.
  Otherwise the NPC gives a believable non-answer for their attitude. The question list
  is the same every run, so it does not hint at the root cause.
- **Locked follow-ups:** some questions only appear after a listed fact has been
  revealed, for example by reading a document.
- **Questions cost time:** a new question moves the office clock forward by a number of
  in-game minutes from a data file (default 15, about 28 real seconds of a 15:00 run).
  Asking an already-asked question again shows the same answer at no cost and reveals
  nothing new; asked questions are marked.
- **Clock can be advanced:** the run clock gains a way for game systems to move office
  time forward. If that reaches 17:00, the run ends as usual.
- **Content:** a dialogue data file with questions and answers for Linh and Trang
  (about 6–8 questions each), fictional, covering every fact either of them can hold.

Decisions taken (agreed with Harry before proposing):

- Part 1 covers **Linh and Trang only**. Minh, Hana and Tanaka-san (called through the
  Meeting Room Screen) come in part 2. Interacting with other targets is unchanged.
- No AI and no network calls; the data format is kept simple so the backend change can
  reuse it as fallback content.

Out of scope: free-text questions, NPC portraits or voice, NPCs moving, relationship or
trust effects, the clue board UI, and AI replies.

## Capabilities

### New Capabilities

- `npc-dialogue`: opening a dialogue with an NPC, which questions are listed and when
  locked ones appear, how an answer is chosen from the Truth Sheet and the NPC's attitude,
  what asking reveals, and what it costs.

### Modified Capabilities

- `run-clock`: adds a requirement that game systems can advance the office time by
  in-game minutes (the existing requirements do not change).

## Impact

- New `game/dialogue/` feature folder (panel scene, dialogue data and loader, answer
  picker) and new tests.
- `game/run/run_clock.gd`: new advance-by-minutes operation.
- `game/office/office_room.gd`: Linh and Trang open the dialogue panel; the "freeze the
  player while a panel is open" logic is shared with the artifact viewer.
- Font coverage test and `tools/subset_jp_font.py` also scan `game/dialogue/*.json`; the
  panel uses the existing viewer theme so Japanese terms render.
- No change to `project.godot`, Autoloads, the Godot version or the export preset.
- No backend, no AI calls, no new environment variables.
