class_name CaseTemplate
extends RefCounted
## A validated case template (specs/case-generation). Built only by CaseTemplateLoader,
## so code that receives one can trust every field.

const ATTITUDES: Array[StringName] = [
	&"honest", &"defensive", &"vague", &"protective", &"nervous", &"indirect",
]
const ARTIFACT_TYPES: Array[StringName] = [
	&"ticket", &"git_log", &"chat_log", &"spec_doc", &"meeting_notes",
]
const MIN_CHAIN: int = 2
const MAX_CHAIN: int = 4


class Fact:
	extends RefCounted
	var id: StringName
	var text: String
	## Possible holders, in "npc:<id>" or "artifact:<type>" form.
	var holders: Array[String] = []


class Npc:
	extends RefCounted
	var id: StringName
	var display_name: String
	var role: String
	var attitudes: Array[StringName] = []


class Variant:
	extends RefCounted
	var id: StringName
	var description: String
	var chain: Array[Fact] = []
	var fixes: Array[String] = []
	var prevention: Array[String] = []


var id: StringName
var title: String
var npcs: Array[Npc] = []
var variants: Array[Variant] = []
var red_herrings: Array[Fact] = []


func find_variant(variant_id: StringName) -> Variant:
	for variant: Variant in variants:
		if variant.id == variant_id:
			return variant
	return null
