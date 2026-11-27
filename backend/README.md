# Backend (placeholder)

Not started yet. Planned: a small Node/TypeScript proxy on Vercel that holds the API keys
and exposes two endpoints for the game:

- `POST /npc-reply` — in-character NPC answer + structured tags
- `POST /grade-report` — structured grading of the 5 PM report

API keys live only in Vercel environment variables, never in this repo or in the game.
See `docs/gdd.md` §13.
