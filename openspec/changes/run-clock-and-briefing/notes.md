# Notes — run-clock-and-briefing

## Verification results (2026-11-27)

### GUT (task 6.1)

Full suite headless: 15 scripts, 69 tests, 69 passing, 0 failures.

### Visual checks (tasks 3.3, 4.1)

Desktop render of the briefing and office scenes at 640×360 (window 1280×720):

- Briefing: sender, subject, body and Start are all readable; the body scrolls when it is
  longer than the panel. Enter and Space press Start (GUT tests + web check).
- Office: the clock sits top-right inside the room and does not cover any target or label.

### Desktop real-time accuracy

A 10-second run in a real window reached "time up" after 9 862 ms of wall time (within one
frame) and switched to the meeting screen.

### Web build (tasks 6.2, 6.3)

- Export of the shipped build exits 0.
- Flow on a 3-second local build (tuning changed locally, not committed): briefing shown →
  Enter → office with clock at 09:0x → clock moves up → `17:00` meeting placeholder. No
  console errors.
- Hidden page: the agent's browser pane was hidden, so the page ran as a background page.
  There the clock **slows down instead of jumping forward**: about 25 s of wall time moved a
  60-second run only to 09:50 (~6 s of countdown), and it advanced roughly one rendered
  frame at a time. So a player who hides the tab loses almost no time. Not a spec
  violation for a hidden tab, but worth knowing for playtests.
- Console: only `GL_INVALID_FRAMEBUFFER_OPERATION ... Attachment has zero size` warnings,
  caused by the hidden pane having zero size. No errors.

### Scenario walk-through (task 6.4)

2026-11-27: Harry ran every scenario in `specs/run-flow`, `specs/run-clock` and the
modified `specs/player-movement` on a visible web build, including one default 15:00 run.
Result: **pass**.

## Devlog

- 2026-11-27: Briefing → office → meeting flow and the 09:00–17:00 run clock (pause by
  reason, one-shot time up) built test-first; 69/69 GUT tests pass, web build exports.
- Run swaps child screens instead of changing scenes, so the whole flow runs in GUT.
- Hidden browser tabs slow the clock rather than jumping it; Harry passed the visible
  15:00 web run (task 6.4).
