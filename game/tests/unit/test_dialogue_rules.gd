extends GutTest
## Answer choice and question visibility (specs/npc-dialogue), on fixture data.

var _template: CaseTemplate
var _data: DialogueData


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template("res://tests/fixtures/case/valid_minimal.json")
	_data = DialogueData.load_from("res://tests/fixtures/dialogue/valid_minimal.json", _template)


## A sheet where `fact_one` sits with `holder` and Ana has `attitude`.
func _sheet(holder: String, attitude: StringName) -> TruthSheet:
	var sheet: TruthSheet = TruthSheet.new()
	sheet.knowledge = { &"fact_one": holder, &"fact_two": "artifact:chat_log" } as Dictionary[StringName, String]
	sheet.attitudes = { &"ana": attitude, &"bo": &"vague" } as Dictionary[StringName, StringName]
	return sheet


func _question(npc: StringName, id: StringName) -> DialogueData.Question:
	for question: DialogueData.Question in _data.questions_for(npc):
		if question.id == id:
			return question
	return null


func _ids(questions: Array[DialogueData.Question]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for question: DialogueData.Question in questions:
		ids.append(question.id)
	return ids


# --- answers ---

func test_holder_gets_the_holds_answer_for_their_attitude() -> void:
	var answer: DialogueAnswer = DialogueRules.answer(_question(&"ana", &"ana_fact_one"), &"ana",
		_sheet("npc:ana", &"defensive"))
	assert_eq(answer.text, "Fact one is true. (defensive)")
	assert_eq(answer.reveals, &"fact_one")


func test_attitude_changes_the_wording() -> void:
	var answer: DialogueAnswer = DialogueRules.answer(_question(&"ana", &"ana_fact_one"), &"ana",
		_sheet("npc:ana", &"honest"))
	assert_eq(answer.text, "Fact one is true. (honest)")


func test_fact_held_elsewhere_gets_a_non_answer() -> void:
	var answer: DialogueAnswer = DialogueRules.answer(_question(&"ana", &"ana_fact_one"), &"ana",
		_sheet("artifact:ticket", &"honest"))
	assert_eq(answer.text, "No idea. (honest)")
	assert_eq(answer.reveals, &"")


func test_fact_not_in_this_case_gets_a_non_answer() -> void:
	var sheet: TruthSheet = _sheet("npc:ana", &"honest")
	sheet.knowledge.erase(&"fact_one")
	var answer: DialogueAnswer = DialogueRules.answer(_question(&"ana", &"ana_fact_one"), &"ana", sheet)
	assert_eq(answer.reveals, &"")
	assert_eq(answer.text, "No idea. (honest)")


func test_small_talk_never_reveals() -> void:
	var answer: DialogueAnswer = DialogueRules.answer(_question(&"ana", &"ana_small"), &"ana",
		_sheet("npc:ana", &"honest"))
	assert_eq(answer.text, "Busy. (honest)")
	assert_eq(answer.reveals, &"")


func test_no_case_falls_back_to_a_non_answer() -> void:
	var answer: DialogueAnswer = DialogueRules.answer(_question(&"ana", &"ana_fact_one"), &"ana", null)
	assert_eq(answer.reveals, &"")
	assert_false(answer.text.is_empty())


# --- visible questions ---

func test_locked_question_hidden_until_unlocked() -> void:
	var questions: Array[DialogueData.Question] = _data.questions_for(&"ana")
	assert_eq(_ids(DialogueRules.visible_questions(questions, [] as Array[StringName])),
		[&"ana_fact_one", &"ana_small"] as Array[StringName])
	assert_eq(_ids(DialogueRules.visible_questions(questions, [&"fact_one"] as Array[StringName])),
		[&"ana_fact_one", &"ana_small", &"ana_follow"] as Array[StringName])


func test_unrelated_reveal_does_not_unlock() -> void:
	var questions: Array[DialogueData.Question] = _data.questions_for(&"ana")
	assert_eq(DialogueRules.visible_questions(questions, [&"rh_one"] as Array[StringName]).size(), 2)
