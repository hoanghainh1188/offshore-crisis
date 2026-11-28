class_name DialogueTuning
extends Resource
## Dialogue numbers. Balance values: tune in playtests, log in playtest/tuning-log.md.

## In-game minutes a new question moves the office clock forward (GDD §7 default: 15).
@export var question_cost_minutes: int = 15
## In-game minutes a new question to a remote NPC (e.g. Tanaka-san) costs.
@export var remote_question_cost_minutes: int = 30
## NPC ids reached through the Meeting Room Screen rather than in person.
@export var remote_npc_ids: Array[StringName] = [&"tanaka"]


func cost_for(npc_id: StringName) -> int:
	return remote_question_cost_minutes if remote_npc_ids.has(npc_id) else question_cost_minutes
