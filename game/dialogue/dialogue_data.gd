class_name DialogueData
extends RefCounted
## Pre-written questions and answers per NPC (specs/npc-dialogue), checked against the case
## template when loaded. Also the future fallback content for the AI backend.

class Question:
	extends RefCounted
	var id: StringName
	var text: String
	## The fact this question is about, or &"" for small talk.
	var fact: StringName = &""
	## Hidden until at least one of these facts is revealed; empty = always listed.
	var unlock_any: Array[StringName] = []
	## Attitude -> answer when this NPC holds `fact` in the run.
	var holds: Dictionary[StringName, String] = {}
	## Attitude -> answer otherwise (and for small talk).
	var not_held: Dictionary[StringName, String] = {}


## Empty after a successful load; otherwise "<path>: <problem>".
static var last_error: String = ""

var _questions: Dictionary[StringName, Array] = {}


static func load_from(path: String, template: CaseTemplate) -> DialogueData:
	last_error = ""
	if template == null:
		return _fail(path, "no case template to check against")
	if not FileAccess.file_exists(path):
		return _fail(path, "file not found")
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY \
			or typeof((json.data as Dictionary).get("npcs")) != TYPE_DICTIONARY:
		return _fail(path, "needs an object with an 'npcs' object")
	var data: DialogueData = DialogueData.new()
	var seen_ids: Dictionary[StringName, bool] = {}
	var npcs: Dictionary = (json.data as Dictionary)["npcs"]
	for npc_key: String in npcs:
		var npc: CaseTemplate.Npc = _find_npc(template, StringName(npc_key))
		if npc == null:
			return _fail(path, "npc '%s' is not in the case template" % npc_key)
		var entry: Variant = npcs[npc_key]
		if typeof(entry) != TYPE_DICTIONARY or typeof((entry as Dictionary).get("questions")) != TYPE_ARRAY:
			return _fail(path, "npc '%s' needs a 'questions' list" % npc_key)
		var questions: Array[Question] = []
		for raw: Variant in (entry as Dictionary)["questions"]:
			var built: Variant = _build_question(raw, npc, template, seen_ids)
			if built is String:
				return _fail(path, built as String)
			questions.append(built as Question)
		data._questions[npc.id] = questions
	return data


static func _fail(path: String, problem: String) -> DialogueData:
	last_error = "%s: %s" % [path, problem]
	push_error(last_error)
	return null


static func _find_npc(template: CaseTemplate, npc_id: StringName) -> CaseTemplate.Npc:
	for npc: CaseTemplate.Npc in template.npcs:
		if npc.id == npc_id:
			return npc
	return null


static func _template_fact_ids(template: CaseTemplate) -> Array[StringName]:
	var ids: Array[StringName] = []
	for variant: CaseTemplate.Variant in template.variants:
		for fact: CaseTemplate.Fact in variant.chain:
			ids.append(fact.id)
	for fact: CaseTemplate.Fact in template.red_herrings:
		ids.append(fact.id)
	return ids


## Returns a Question, or a String describing the problem.
static func _build_question(raw: Variant, npc: CaseTemplate.Npc, template: CaseTemplate,
		seen_ids: Dictionary[StringName, bool]) -> Variant:
	if typeof(raw) != TYPE_DICTIONARY:
		return "npc '%s' has a question that is not an object" % npc.id
	var entry: Dictionary = raw
	if typeof(entry.get("id")) != TYPE_STRING or typeof(entry.get("text")) != TYPE_STRING \
			or (entry["id"] as String).is_empty() or (entry["text"] as String).is_empty():
		return "npc '%s' has a question without 'id' or 'text'" % npc.id
	var question: Question = Question.new()
	question.id = StringName(entry["id"] as String)
	question.text = entry["text"]
	if seen_ids.has(question.id):
		return "question id '%s' is repeated" % question.id
	seen_ids[question.id] = true
	var fact_ids: Array[StringName] = _template_fact_ids(template)
	if entry.has("fact"):
		question.fact = StringName(str(entry["fact"]))
		if not fact_ids.has(question.fact):
			return "question '%s' has unknown fact '%s'" % [question.id, question.fact]
	elif entry.has("holds"):
		return "question '%s' has 'holds' answers but no 'fact'" % question.id
	var unlocks: Variant = entry.get("unlock_any", [])
	if typeof(unlocks) != TYPE_ARRAY:
		return "question '%s' needs 'unlock_any' as a list of fact ids" % question.id
	for unlock: Variant in unlocks:
		var unlock_id: StringName = StringName(str(unlock))
		if not fact_ids.has(unlock_id):
			return "question '%s' has unknown unlock fact '%s'" % [question.id, unlock_id]
		question.unlock_any.append(unlock_id)
	var problem: String = _read_answers(entry, "not_held", npc, question.not_held, question.id)
	if problem.is_empty() and question.fact != &"":
		problem = _read_answers(entry, "holds", npc, question.holds, question.id)
	return question if problem.is_empty() else problem


## Fills `into` with one answer per attitude in the NPC's pool; returns a problem or "".
static func _read_answers(entry: Dictionary, key: String, npc: CaseTemplate.Npc,
		into: Dictionary[StringName, String], question_id: StringName) -> String:
	var answers: Variant = entry.get(key)
	if typeof(answers) != TYPE_DICTIONARY:
		return "question '%s' needs '%s' answers" % [question_id, key]
	for attitude: StringName in npc.attitudes:
		var line: Variant = (answers as Dictionary).get(String(attitude))
		if typeof(line) != TYPE_STRING or (line as String).is_empty():
			return "question '%s' has no '%s' answer for attitude '%s'" % [question_id, key, attitude]
		into[attitude] = line
	return ""


func has_npc(npc_id: StringName) -> bool:
	return _questions.has(npc_id)


func questions_for(npc_id: StringName) -> Array[Question]:
	var questions: Array[Question] = []
	questions.assign(_questions.get(npc_id, []))
	return questions
