# Proposal

Owner: Antigravity (assigned by Harry)

## Why

Part 1 of `npc-dialogue-offline` gave Linh and Trang pre-written dialogue, but the remaining three NPCs in the "Wrong Delivery" case — Minh (Junior dev), Hana (Comtor), and Tanaka-san (Client PM) — still cannot be questioned. Several key facts (such as Hana's translation note, Minh's un-ticketed work, and Tanaka-san's polite "はい") can only be heard directly from them, so completing all five NPCs makes the full investigation loop playable offline.

## What Changes

- **Add Minh and Hana to the office room:** place Minh (`npc:minh`, "Minh") and Hana (`npc:hana`, "Hana", with a Comtor desk solid and zone label) as interactable NPCs in `office_room.tscn`, opening the existing dialogue panel on interaction.
- **Connect the Meeting Room Screen to Tanaka-san:** interacting with `object:meeting_screen` ("Meeting Room Screen") opens the dialogue panel for `tanaka` ("Tanaka-san", "Client PM, Kazegumo Logistics") while still logging `[interact] object:meeting_screen "Meeting Room Screen"`.
- **Higher time cost for remote client questions:** asking a new question to Tanaka-san via the Meeting Room Screen costs more in-game time than asking an NPC in the room (starting value: 30 in-game minutes vs. 15, stored in `DialogueTuning`). Opening the call itself costs nothing extra, and asking an already-asked question again remains free.
- **Add offline dialogue content for Minh, Hana, and Tanaka-san:** extend `dialogue_offline.json` with 6–8 pre-written questions per NPC (covering every fact they can hold in "Wrong Delivery", small talk, and 1–2 locked follow-ups), with answers for every attitude in each NPC's pool (`nervous` for Minh, `protective` and `honest` for Hana, `indirect` for Tanaka-san). Ensure every chain fact across seeds 1–300 is reachable without lock cycles and that `honest` / `indirect` non-held answers never imply the NPC holds a fact they do not hold.
- **No network or AI calls:** all replies remain pre-written data that will also serve as the future AI fallback.

Out of scope: free-text questions, NPC portraits or voice, NPCs walking around, relationship/trust meters, AI backend calls, and new UI screens for video calls.

## Capabilities

### New Capabilities

<!-- None: extends existing capabilities to the remaining three NPCs. -->

### Modified Capabilities

- `npc-dialogue`: expands dialogue availability from Linh and Trang only to all five case NPCs (adding Minh and Hana in the room, and Tanaka-san via the Meeting Room Screen), adds a higher per-question time cost for remote calls, and adds content, reachability, and non-misleading answer requirements for Minh, Hana, and Tanaka-san.
- `world-interaction`: updates the room's interactable targets to include Minh (`npc:minh`) and Hana (`npc:hana`).

## Impact

- `game/dialogue/dialogue_offline.json`: add `minh`, `hana`, and `tanaka` question pools and attitude-keyed answers.
- `game/dialogue/dialogue_tuning.gd`, `game/dialogue/dialogue_tuning.tres`, and `game/game_state.gd`: add remote question cost (default 30 minutes) and apply it per NPC in `ask_question()`.
- `game/office/office_room.tscn` and `game/office/office_room.gd`: add `ComtorDesk` solid, `"Comtor desk"` label, `Minh`, and `Hana` interactables, and wire `MeetingScreen` to open `DialoguePanel` for `&"tanaka"`.
- `game/fonts/`: rebuild `noto_sans_jp_subset.ttf` only if new CJK characters are introduced.
- `game/tests/`: add failing tests first, then update `test_dialogue_content.gd`, `test_asking.gd`, `test_office_dialogue.gd`, and `test_office_room_targets.gd` to cover all 5 NPCs, remote cost, reachability (seeds 1–300), non-misleading answers, and 640×360 panel rendering.
