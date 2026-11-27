# Player sprite drawn over the wall

- Date: 2026-11-27
- Agent / model: Claude Code (Claude Opus 5.5)
- Context: office-prototype, task 6.4 (web build check)
- What went wrong: the player's collider was a 12x10 box at the feet, while the
  placeholder sprite was 21 px tall. Collision was correct (tests passed), but against
  the top wall the upper part of the sprite was drawn over the wall, so it looked like
  the player walked into it.
- How it was caught: screenshot of the web build after pushing into the top-left corner.
  The GUT wall tests only checked the body position, not what is drawn.
- Fix: collider 12x15 at (0, -2.5) covering the sprite (y -10..5); sprite shortened to
  15 px. New test `test_player_visual_bounds.gd` asserts the sprite stays inside the
  collider.
- Lesson / rule to add: for visual specs ("never ends up inside the wall"), check a
  screenshot, not only positions. Keep collider and placeholder visual in sync.
