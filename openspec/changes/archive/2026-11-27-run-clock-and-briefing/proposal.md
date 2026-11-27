# Proposal

## Why

The office prototype lets the player walk and interact, but there is no run yet: no start,
no time pressure and no end. The 15-minute countdown to the 5 PM meeting is the core
tension of the game (GDD §4), and every later system (dialogue, artifacts, report) needs a
run that begins with a briefing and ends at the meeting. This change builds that frame so
the next changes can fill it in.

## What Changes

- Add a **briefing screen** that opens when the game starts. It shows the client's
  escalation email (fictional placeholder text for the "Wrong Delivery" case) and a
  **Start** button. The clock reads 09:00 and does not run on this screen.
- Pressing **Start** moves the player into the office room and starts the
  **investigation clock**: a real-time countdown (default 15:00) whose length lives in a
  data file, not in code.
- Show the countdown in the office as an **office clock** (`HH:MM`) that moves linearly
  from 09:00 to 17:00 over the countdown.
- Let other systems **pause and resume** the clock by named reason (for example, waiting
  for an AI reply later). The clock runs only when nothing holds it paused.
- When the countdown reaches 0:00, the game leaves the office and shows a **placeholder
  meeting screen** ("17:00 — meeting with the client"). The report form comes in a later
  change.
- **Modified:** the game no longer opens directly in the office room; it opens on the
  briefing screen.

Out of scope: the real case text (comes from `case-generator`), in-game time cost per
question, pause UI or a pause key, auto-pause when the browser tab is hidden, sound, the
report form, endings, restarting a run, and any art beyond placeholder UI.

## Capabilities

### New Capabilities

- `run-clock`: the investigation countdown, its office-clock display, pausing by other
  systems, and what happens when time runs out.
- `run-flow`: the screens a run moves through (briefing → office investigation → meeting)
  and what starts each transition.

### Modified Capabilities

- `player-movement`: "Game starts in the office room" changes — the game starts on the
  briefing screen, and the player is placed at the office entrance after pressing Start.

## Impact

- New scenes and scripts under `game/run/` (briefing screen, meeting placeholder, run
  clock, clock HUD) and a data file for the countdown length and the briefing email.
- `game/office/office_room.tscn`: gains the clock HUD.
- `game/project.godot`: the main scene changes to the briefing screen, and one Autoload,
  `GameState`, is added (already on the allowed list in AGENTS.md §10). The Godot version,
  renderer and export presets do not change.
- New GUT unit and integration tests for the clock logic and the screen flow.
- No backend, no AI calls, no new environment variables, no new assets.
