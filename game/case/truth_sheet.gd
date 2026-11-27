class_name TruthSheet
extends RefCounted
## The hidden truth of one run (GDD §5). Only game code reads all of it; the AI only gets
## the slices it is allowed to see.

var seed: int = 0
var template_id: StringName
var root_cause_id: StringName
var root_cause_description: String = ""
## Facts from symptom to root cause, in template order. Fact objects are shared with the
## CaseTemplate, so treat them as read-only: per-run data belongs in this sheet's own fields.
var chain: Array[CaseTemplate.Fact] = []
var red_herrings: Array[CaseTemplate.Fact] = []
## Fact id -> the one holder ("npc:<id>" or "artifact:<type>") that knows it in this run.
var knowledge: Dictionary[StringName, String] = {}
## NPC id -> attitude for this run.
var attitudes: Dictionary[StringName, StringName] = {}
var fixes: Array[String] = []
var prevention: Array[String] = []


## Plain data for comparisons, logs and (later) the grader prompt.
func to_dict() -> Dictionary:
	return {
		"seed": seed,
		"template_id": String(template_id),
		"root_cause": { "id": String(root_cause_id), "description": root_cause_description },
		"chain": _facts_to_list(chain),
		"knowledge": _stringify_keys(knowledge),
		"attitudes": _stringify_keys(attitudes),
		"red_herrings": _facts_to_list(red_herrings),
		"fix_space": { "fixes": fixes.duplicate(), "prevention": prevention.duplicate() },
	}


static func _facts_to_list(facts: Array[CaseTemplate.Fact]) -> Array:
	var result: Array = []
	for fact: CaseTemplate.Fact in facts:
		result.append({ "id": String(fact.id), "text": fact.text })
	return result


static func _stringify_keys(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: StringName in source:
		result[String(key)] = String(source[key])
	return result
