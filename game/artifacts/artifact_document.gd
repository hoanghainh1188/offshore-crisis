class_name ArtifactDocument
extends RefCounted
## One readable document, built from the run's Truth Sheet (specs/artifact-viewer).
## Pure: the same sheet, type and filler always give the same lines.

## Supported types in list order (specs/artifact-viewer).
const TYPES: Array[StringName] = [&"ticket", &"git_log", &"chat_log", &"spec_doc", &"meeting_notes"]
## Seed offset per type. Kept apart from TYPES so a new list order does not move the facts
## of part 1 documents for a seed a playtester already reported.
const SEED_INDEX: Dictionary[StringName, int] = {
	&"ticket": 0,
	&"chat_log": 1,
	&"meeting_notes": 2,
	&"git_log": 3,
	&"spec_doc": 4,
}
const DISPLAY_NAMES: Dictionary[StringName, String] = {
	&"ticket": "Ticket",
	&"git_log": "Git log",
	&"chat_log": "Chat log",
	&"spec_doc": "Spec document",
	&"meeting_notes": "Meeting notes",
}

var title: String = ""
var lines: Array[String] = []
## Section headings as they appear in `lines`; empty for a flat document.
var headings: Array[String] = []
## Facts shown in this document, in Truth Sheet order.
var fact_ids: Array[StringName] = []


static func display_name(type: StringName) -> String:
	return DISPLAY_NAMES.get(type, String(type))


static func build(sheet: TruthSheet, type: StringName, filler: ArtifactFiller) -> ArtifactDocument:
	var doc: ArtifactDocument = ArtifactDocument.new()
	doc.title = filler.title_for(type)
	var holder: String = "artifact:%s" % type
	var sections: Array[ArtifactFiller.Section] = filler.sections_for(type)
	# Truth Sheet order (chain, then red herrings), never dictionary order.
	var held: Array[CaseTemplate.Fact] = []
	for fact: CaseTemplate.Fact in sheet.chain + sheet.red_herrings:
		if sheet.knowledge.get(fact.id, "") == holder:
			held.append(fact)
			doc.fact_ids.append(fact.id)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	# Plain integer seed instead of hash(): identical on desktop and web.
	rng.seed = sheet.seed * 16 + SEED_INDEX.get(type, -1)
	# Draws go section by section, then Truth Sheet order, so a flat document draws
	# exactly as part 1 did.
	for i: int in sections.size():
		var body: Array[String] = sections[i].lines.duplicate()
		for fact: CaseTemplate.Fact in held:
			if filler.section_index_for(type, fact.id) == i:
				body.insert(rng.randi_range(0, body.size()), fact.text)
		if not sections[i].heading.is_empty():
			doc.lines.append(sections[i].heading)
			doc.headings.append(sections[i].heading)
		doc.lines.append_array(body)
	return doc
