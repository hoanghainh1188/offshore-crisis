class_name DialogueRules
extends RefCounted
## Pure dialogue rules (specs/npc-dialogue): which questions are listed, which answer is
## given. No state, so every rule is unit-tested across many Truth Sheets.


## Questions in data order; a locked one appears once any of its unlock facts is revealed.
static func visible_questions(questions: Array[DialogueData.Question],
		revealed_ids: Array[StringName]) -> Array[DialogueData.Question]:
	var visible: Array[DialogueData.Question] = []
	for question: DialogueData.Question in questions:
		if question.unlock_any.is_empty() or question.unlock_any.any(
				func(fact_id: StringName) -> bool: return revealed_ids.has(fact_id)):
			visible.append(question)
	return visible


## "Holds" answer only when this NPC holds the question's fact in this run; otherwise a
## non-answer. The wording follows the NPC's attitude this run.
static func answer(question: DialogueData.Question, npc_id: StringName, sheet: TruthSheet) -> DialogueAnswer:
	var result: DialogueAnswer = DialogueAnswer.new()
	var attitude: StringName = _attitude(question, npc_id, sheet)
	var holds: bool = sheet != null and question.fact != &"" \
		and sheet.knowledge.get(question.fact, "") == "npc:%s" % npc_id
	if holds:
		result.text = question.holds[attitude]
		result.reveals = question.fact
	else:
		result.text = question.not_held[attitude]
	return result


## The run's attitude, or the first written one when there is no case (e.g. office tests).
static func _attitude(question: DialogueData.Question, npc_id: StringName, sheet: TruthSheet) -> StringName:
	if sheet != null and sheet.attitudes.has(npc_id) and question.not_held.has(sheet.attitudes[npc_id]):
		return sheet.attitudes[npc_id]
	return question.not_held.keys()[0]
