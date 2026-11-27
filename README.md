# Offshore Crisis

> *Something broke. The client is furious. Find out why before the 5 PM meeting.*

A short, replayable investigation game. You play a Bridge SE / Delivery Manager at an
offshore dev center. Walk around one office, question your team, read tickets, chat logs
and specs, pin clues — then deliver an honest incident report to the Japanese client:
**事象 → 原因 → 対策 → 再発防止** (what happened → root cause → fix → prevention).

- **Genre:** investigation / detective, roguelike cases, branching endings
- **Run length:** 20–30 minutes, one case per run
- **Engine:** Godot 4.7.2 (GDScript)
- **Platform:** web first (itch.io), PC later
- **AI:** the game owns the truth; an LLM only voices NPCs and grades the report

All companies, people and incidents are fictional.

**Status:** pre-prototype. See [`docs/gdd.md`](docs/gdd.md) for the design and
[`openspec/`](openspec/) for specs and changes.

## Repo layout

| Path | Content |
|---|---|
| `docs/gdd.md` | Game design document (the "why") |
| `openspec/` | Specs and change proposals (the "what") |
| `game/` | Godot project (the "how") |
| `backend/` | AI proxy (Vercel), not started yet |
| `prompts/` | Versioned LLM prompts with test sets |
| `playtest/` | Playtest notes and tuning log |
| `ai-failures/` | Log of AI mistakes during development and play |
| `assets/CREDITS.md` | Asset sources and licenses |

## License

Code: [MIT](LICENSE). Assets keep their original licenses, listed in
[`assets/CREDITS.md`](assets/CREDITS.md).
