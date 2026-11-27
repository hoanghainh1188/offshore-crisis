# Reported "0 warnings" on the web build, but real Chrome shows 104

- Date: 2026-11-27
- Agent / model: Claude Code (Claude Opus 5.5)
- Context: office-prototype, web checks (tasks 6.4 and 7.1)
- What went wrong: I reported "0 console errors, 0 warnings" from a Playwright-driven
  Chromium. That browser used a different WebGL backend ("WebKit WebGL") and did not
  emit the WebGL warnings that Chrome with ANGLE Metal shows (104 warnings from
  godotengine/godot#124726). I stated the result as a general fact.
- How it was caught: Antigravity QA in a real Chrome on macOS.
- Fix: recorded the warnings and the upstream issue in notes.md as a known engine issue.
- Lesson / rule to add: when reporting web console results, name the browser and WebGL
  backend, and do not generalize "0 warnings" beyond that environment. A real-browser
  check (Antigravity or Harry) is needed before claiming a clean console.
