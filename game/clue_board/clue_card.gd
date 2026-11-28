class_name ClueCard
extends RefCounted
## What one clue card shows (specs/clue-board): the fact's Truth Sheet text, unchanged, and
## where the player found it this run.

var fact_id: StringName
var text: String = ""
var source: String = ""


static func from_fact(id: StringName, sheet: TruthSheet, template: CaseTemplate) -> ClueCard:
	var card: ClueCard = ClueCard.new()
	card.fact_id = id
	var all_facts: Array[CaseTemplate.Fact] = []
	all_facts.append_array(sheet.chain)
	all_facts.append_array(sheet.red_herrings)
	for fact: CaseTemplate.Fact in all_facts:
		if fact.id == id:
			card.text = fact.text
			break
	card.source = source_label(sheet.knowledge.get(id, ""), template)
	return card


## "npc:hana" -> "Hana", "artifact:git_log" -> "Git log". An unknown holder keeps its raw
## string and warns, so a template typo shows in tests instead of an empty label.
static func source_label(holder: String, template: CaseTemplate) -> String:
	var parts: PackedStringArray = holder.split(":", true, 1)
	if parts.size() == 2:
		if parts[0] == "npc":
			for npc: CaseTemplate.Npc in template.npcs:
				if String(npc.id) == parts[1]:
					return npc.display_name
		elif parts[0] == "artifact" and ArtifactDocument.DISPLAY_NAMES.has(StringName(parts[1])):
			return ArtifactDocument.display_name(StringName(parts[1]))
	push_warning("[clue_board] unknown fact holder '%s'" % holder)
	return holder
