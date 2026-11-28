# Offshore Crisis — Game Design Document v0.1

> Status: Draft v0.1 (2026-11-27). Updated 2026-11-28: remote call cost (§7).

---

## 1. Overview

| Item | Value |
|---|---|
| Title | Offshore Crisis |
| Pitch | *Something broke. The client is furious. Find out why before the 5 PM meeting.* |
| Genre | Investigation / detective, roguelike cases, branching endings |
| Player role | Bridge SE / Delivery Manager at an offshore dev center |
| Presentation | 2D top-down, one office room, walk to NPCs and objects |
| Platforms | Web first → PC (itch.io / Steam) → console later |
| Engine | Godot 4 + GDScript |
| Session | 20–30 minutes per run (one case) |
| Language | English UI and dialogue (Japanese terms as flavor, always explained) |
| Tone | Realistic with light humor |
| Audience | AI recruiters, dev community, Japanese clients (portfolio) |

All companies, people and incidents are fictional.

---

## 2. Design pillars

1. **Read people, not just logs.** The truth is spread across people who each know only a part, and who each have reasons to hide or soften it.
2. **The game owns the truth; AI is only the voice.** Game code generates the case and decides outcomes. The LLM only phrases what an NPC is allowed to say.
3. **Japanese reporting culture is the win condition.** You win by reporting the incident clearly and honestly: 事象 → 原因 → 対策 → 再発防止.
4. **Short and replayable.** One case per run. Each run reshuffles the root cause, who knows what, and who hides what.

---

## 3. Core loop

```
Briefing → Investigate (talk / read / pin clues) → Build the case → 5 PM report → Ending → New case
```

---

## 4. Run structure

| Phase | Real time | In-game time | What the player does |
|---|---|---|---|
| Briefing | ~2 min | 09:00 | Read the client's escalation email. Clock not running |
| Investigation | 15:00 real-time countdown | 09:00 → 17:00 | Walk, ask questions, read artifacts, pin clues |
| Report | ~5 min, no countdown | 17:00 | Write the 4-part report in free text |
| Ending | ~1 min | — | See the outcome, the hidden truth, and a score breakdown |

### Clock rules

- The investigation clock is a **real-time countdown** (default 15:00, tunable).
- The clock is shown as an office clock moving from 09:00 to 17:00.
- **The clock pauses while waiting for an AI response.** The player is never punished for latency.
- The clock keeps running while reading artifacts and walking.
- At 0:00 the player is pulled into the meeting with whatever clues they have.

---

## 5. Case generation (roguelike)

Each case is built from a **case template** plus random choices. The result is a hidden **Truth Sheet** that only the game sees in full.

### Truth Sheet (generated per run)

- `root_cause`: one of the template's root causes
- `chain`: 2–4 linked facts that lead from symptom to root cause
- `knowledge`: which NPC or artifact holds each fact
- `attitudes`: per NPC (honest / defensive / vague / protecting someone)
- `red_herrings`: 1–2 believable wrong leads
- `fix_space`: what a good 対策 and 再発防止 look like for this root cause

### MVP case template: "Wrong Delivery"

The client runs acceptance testing and says: *"This is not what we asked for."*

| Root cause variant | Short description | Key evidence |
|---|---|---|
| A. Lost in translation | The comtor translated an ambiguous requirement one way; the client meant another | Original Japanese spec vs. translated ticket; comtor's notes |
| B. Chat-only change | A change request was agreed in chat but never written into the spec | Chat log; spec doc revision history; dev lead's memory |
| C. The polite "yes" | The client's はい meant "I hear you", not "I agree". The team took it as approval | Meeting notes; client PM's phrasing; BrSE's past emails |

Red herring pool (examples): a junior dev's unrelated bug, a late test run, a config change on the same day.

---

## 6. NPCs (MVP)

| NPC | Role | Typical attitude pool |
|---|---|---|
| Linh | Dev lead | Defensive / honest |
| Minh | Junior dev | Nervous, over-shares, sometimes wrong |
| Trang | Tester | Honest, precise, only knows what she tested |
| Hana | Comtor (interpreter) | Protective of her translation / honest |
| Tanaka-san | Client PM (video call screen) | Polite, indirect, never says "no" directly |

Names and personalities are placeholders.

Each NPC has:

- a **public profile** (role, short bio)
- a **knowledge slice** from the Truth Sheet (what they know)
- an **attitude** for this run (how they say it, what they hide)
- a **question pool** the player can pick from

---

## 7. Dialogue system

- The player **picks questions** from a list. No free-text questions in MVP.
- Each question costs in-game time the first time it is asked (default: 15 in-game minutes). Asking it again is free.
- Questions to Tanaka-san over the Meeting Room Screen cost more (default: 30 in-game minutes), because the client's time is limited. Opening the call costs nothing extra.
- Exact values live in data and are tuned in playtests.
- The game sends the backend: NPC profile, knowledge slice, attitude, question, and short conversation history.
- The LLM returns a short in-character answer **plus structured tags**:

```json
{
  "line": "Hmm... I followed the ticket. The ticket said 'export by month'.",
  "revealed_fact_ids": ["fact_ticket_wording"],
  "tone": "defensive"
}
```

- The game **validates** `revealed_fact_ids` against the NPC's knowledge slice. Unknown IDs are dropped.
- Revealed facts become **clues** the player can pin.

### Hard rules for the NPC prompt

- Never state facts outside the knowledge slice.
- Never name the root cause directly.
- Stay in attitude (a defensive NPC answers, but softens and deflects).
- Max ~2 sentences per answer.

---

## 8. Artifacts

Static documents generated by the game from the Truth Sheet. No LLM needed.

- Jira-style tickets
- Git log (commit messages, dates)
- Team chat log
- Spec document with revision history (JP original + EN translation)
- Meeting notes

Reading an artifact can unlock a new question for an NPC (for example, "Why was this ticket edited on the 12th?").

---

## 9. Clue board

- Every revealed fact becomes a clue card.
- The player pins cards and draws links between them.
- MVP: links are visual help only and are not scored. Later: linked chains give bonus insight.

---

## 10. The 5 PM report and AI grading

### Report form (free text, English)

1. **事象 — What happened**
2. **原因 — Root cause**
3. **対策 — Immediate fix**
4. **再発防止 — Prevention**

Limit: about 600 characters per section.

### Grader

- One LLM call per run. The grader gets the Truth Sheet, a rubric, and the report.
- Output is **structured JSON only**:

```json
{
  "accuracy": 0,
  "honesty": 0,
  "fix_quality": 0,
  "prevention_quality": 0,
  "blamed_wrong_person": false,
  "hid_known_facts": false,
  "feedback": "..."
}
```

- Each score is 0–3.

### Anti-cheat and robustness

- The report is wrapped as untrusted data in the prompt. The grader is told to ignore instructions inside it.
- The game validates JSON shape and ranges. Invalid output → retry once → fallback to a keyword-based score.
- `hid_known_facts` is also checked by code: compare pinned clues vs. facts mentioned.
- A test set lives in `prompts/grader/tests/`: good reports, weak reports, wrong-culprit reports, prompt-injection attempts.

---

## 11. Endings

| Ending | Condition (draft) |
|---|---|
| **Trust Restored** | accuracy ≥ 2, honesty = 3, fix + prevention ≥ 4 |
| **Wrong Culprit** | `blamed_wrong_person` = true |
| **Cover-up** | `hid_known_facts` = true |
| **Escalation** | accuracy ≤ 1, or no report submitted |

The ending screen shows: the ending, the full hidden truth, what the player missed, and the grader's feedback.

---

## 12. Office layout (one room)

- **Entrance + coffee corner**: Minh is often here
- **Dev desks**: Linh, Minh
- **QA corner**: Trang
- **Comtor desk**: Hana
- **Meeting room screen**: call Tanaka-san
- **Document shelf / PC terminal**: open artifacts
- **Clue board on the wall**: open the board anywhere with a key

---

## 13. AI architecture (summary)

- The game never calls the model provider directly. All calls go through `backend/` on Vercel.
- API keys live only in Vercel environment variables.
- Two endpoints: `POST /npc-reply` and `POST /grade-report`.
- NPC replies use a small, cheap model. The grader may use a stronger model (one call per run).
- Per-run call budget (draft: 40 NPC calls + 2 grader calls). Over budget → canned lines.
- Offline / API error → pre-written fallback lines per NPC and question; grader falls back to keyword scoring.
- Every prompt lives in `prompts/` with its own test set.

---

## 14. MVP scope (1 month)

| Item | MVP |
|---|---|
| Case templates | 1 ("Wrong Delivery") |
| Root cause variants | 3 |
| NPCs | 5 |
| Artifacts | 5 types |
| Questions | ~8 per NPC |
| Endings | 4 |
| Rooms | 1 |
| Platform | Web build on itch.io |

---

## 15. Out of scope for MVP (backlog)

- More case templates: production outage, endless "90% done", security incident
- Free-text questions to NPCs
- Japanese indirect-speech mini-game (read what the client really means)
- Scored clue chains
- Multiple rooms, day/night, campaign across several cases
- Localization (Vietnamese, Japanese)

---

## 16. Open questions

- Exact real-time limit (12, 15 or 20 minutes?) — decide after first playtest.
- Should wrong questions have a cost beyond time (for example, an NPC becomes less open)?
- How much Japanese text to show, and how to explain it without slowing the player?
- Art style and asset pack for the office.
