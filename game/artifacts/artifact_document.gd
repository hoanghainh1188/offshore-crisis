class_name ArtifactDocument
extends RefCounted
## One readable document, built from the run's Truth Sheet (specs/artifact-viewer).
## Pure: the same sheet, type and filler always give the same lines.

## Supported types in list order. Part 2 adds git_log and spec_doc here and in the filler.
const TYPES: Array[StringName] = [&"ticket", &"chat_log", &"meeting_notes"]
const DISPLAY_NAMES: Dictionary[StringName, String] = {
	&"ticket": "Ticket",
	&"chat_log": "Chat log",
	&"meeting_notes": "Meeting notes",
}

var title: String = ""
var lines: Array[String] = []
## Facts shown in this document, in Truth Sheet order.
var fact_ids: Array[StringName] = []


static func display_name(type: StringName) -> String:
	return DISPLAY_NAMES.get(type, String(type))


static func build(sheet: TruthSheet, type: StringName, filler: ArtifactFiller) -> ArtifactDocument:
	var doc: ArtifactDocument = ArtifactDocument.new()
	doc.title = filler.title_for(type)
	doc.lines = filler.lines_for(type)
	var holder: String = "artifact:%s" % type
	# Truth Sheet order (chain, then red herrings), never dictionary order.
	var facts: Array[CaseTemplate.Fact] = sheet.chain + sheet.red_herrings
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	# Plain integer seed instead of hash(): identical on desktop and web.
	rng.seed = sheet.seed * 16 + TYPES.find(type)
	for fact: CaseTemplate.Fact in facts:
		if sheet.knowledge.get(fact.id, "") != holder:
			continue
		doc.lines.insert(rng.randi_range(0, doc.lines.size()), fact.text)
		doc.fact_ids.append(fact.id)
	return doc
