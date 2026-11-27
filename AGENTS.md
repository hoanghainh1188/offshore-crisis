# AGENTS.md — Offshore Crisis

Shared rules for every AI agent working in this repo (Claude Code, Antigravity, others).
Source: Harry's "Game Dev - Working Agreement" v1.0.

## 1. Project

- Game: **Offshore Crisis** — *Something broke. The client is furious. Find out why before the 5 PM meeting.*
- Engine: **Godot 4.7.2-stable** (standard build, not .NET). Do not change the version.
- Language: **GDScript** with static typing.
- Platforms: Web (itch.io) → PC (itch.io / Steam) → console later (web build is the first target).
- Uses AI at runtime: Yes — NPC dialogue and report grading via `backend/` (not built yet)

## 2. Language

- Everything in this repo is written in **English**: docs, specs, comments, commits, README.
- When talking to Harry in chat, use the language he uses.

## 3. Source of truth

| Layer | Location | Answers |
|---|---|---|
| GDD | `docs/gdd.md` | **Why** — vision, what makes it fun |
| Spec | `openspec/specs/` | **What** the game does |
| Code | `game/`, `backend/` | **How** it is done |

- If layers conflict, the higher layer wins.
- If code differs from a spec, fix the code or open a change to update the spec. Never change behavior silently.

## 4. Roles

- **Harry (PO)**: final decisions, approves proposals, playtests.
- **Claude Code**: main developer. Creates proposals, writes code, archives changes.
- **Antigravity**: QA. Tests the web build against specs. Edits code only when Harry assigns it.
- **One change = one agent editing code.** Never edit files of a change owned by another agent.

## 5. OpenSpec rules

1. **No change, no code.** Every behavior change needs an OpenSpec change.
2. **Exceptions** (no change needed): balance numbers, text fixes, asset swaps. Log them in `playtest/tuning-log.md`.
3. **Keep changes small**: 1–2 sessions (max ~4 hours). Split anything bigger.
4. **Do not implement until Harry approves** the proposal and tasks.
5. **Archive only after verification passes.**
6. Do not write specs for game feel (speed, difficulty, controls). Tune those through playtests.

## 6. Definition of Ready

- Proposal, spec delta and tasks exist.
- Acceptance criteria are written as "When ... then ...".
- Harry has approved.

## 7. Definition of Done

- All tasks are checked.
- The web build runs with no errors.
- GUT tests pass for logic code.
- Antigravity has tested against the acceptance criteria.
- The change is archived and merged into `main`.

## 8. Git

- `main` must always be playable. Never commit directly to `main`.
- One branch per change: `change/<change-name>`.
- Conventional Commits, e.g. `feat(sprint): add random event`.
- Weekly build tag: `v0.<n>-week<n>`.

## 9. Security (this repo is PUBLIC)

- **Never commit secrets** (API keys, tokens, passwords). Use `.env` locally and Vercel environment variables.
- `.env` stays in `.gitignore`. Update `.env.example` when adding a new variable.
- No real company, client or project data. All characters and situations are fictional.
- If you find a secret in the code or history, stop and tell Harry.

## 10. Code conventions (Godot)

- File names: `snake_case`. Class names: `PascalCase`.
- Always use static typing (`var hp: int = 10`, `func damage(amount: int) -> void`).
- Comments in English, short, explain **why**, not what.
- Balance values live in data files (`.tres` Resources or JSON), never hard-coded.
- Keep Autoloads to a minimum. Allowed: `GameState`, `EventBus`, `AIClient` (add others only through an approved change).
- Prefer signals over direct node references across scenes.

## 11. AI at runtime (only if the game uses AI)

- API keys live **only in the backend** (`backend/`, deployed on Vercel). The game never calls the model provider directly.
- Prompts are files in `prompts/`, versioned like code. Each prompt has a small test set (sample input + expected output).
- Enforce a per-session call limit. Use the cheapest model that passes the prompt tests.
- Always provide fallback content when the network or API fails.
- Log AI mistakes (during coding or gameplay) in `ai-failures/`.

## 12. Assets

- Only CC0 or properly licensed assets.
- Add source and license to `assets/CREDITS.md` in the same commit that adds the asset.

## 13. Repo layout

```
AGENTS.md  CLAUDE.md  README.md  LICENSE  .env.example
docs/gdd.md
openspec/specs/   openspec/changes/
game/             # Godot project
backend/          # only if the game uses AI
prompts/          # only if the game uses AI
playtest/         # playtest notes, tuning-log.md
ai-failures/      # AI mistake log
assets/CREDITS.md
```
