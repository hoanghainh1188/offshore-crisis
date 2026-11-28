extends GutTest
## Shipped dialogue content against the "Wrong Delivery" template, across many cases
## (specs/npc-dialogue).

const DIALOGUE_PATH: String = "res://dialogue/dialogue_offline.json"
const NPCS: Array[StringName] = [&"linh", &"trang"]
const SEEDS: int = 300

var _template: CaseTemplate
var _data: DialogueData


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template(GameState.CASE_TEMPLATE_PATH)
	_data = DialogueData.load_from(DIALOGUE_PATH, _template)


func test_shipped_content_loads() -> void:
	assert_not_null(_data, DialogueData.last_error)
	for npc: StringName in NPCS:
		assert_between(_data.questions_for(npc).size(), 6, 8, "%s question count" % npc)


func test_every_fact_an_npc_can_hold_has_a_question() -> void:
	var facts: Array[CaseTemplate.Fact] = _template.red_herrings.duplicate()
	for variant: CaseTemplate.Variant in _template.variants:
		facts.append_array(variant.chain)
	for npc: StringName in NPCS:
		var asked_facts: Array[StringName] = []
		for question: DialogueData.Question in _data.questions_for(npc):
			asked_facts.append(question.fact)
		for fact: CaseTemplate.Fact in facts:
			if fact.holders.has("npc:%s" % npc):
				assert_has(asked_facts, fact.id, "%s has a question about %s" % [npc, fact.id])


func test_holds_exactly_when_the_npc_is_the_holder() -> void:
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = CaseGenerator.new().generate(_template, seed_value)
		for npc: StringName in NPCS:
			for question: DialogueData.Question in _data.questions_for(npc):
				var answer: DialogueAnswer = DialogueRules.answer(question, npc, sheet)
				var holder: bool = question.fact != &"" \
					and sheet.knowledge.get(question.fact, "") == "npc:%s" % npc
				assert_eq(answer.reveals, question.fact if holder else &"",
					"seed %d %s" % [seed_value, question.id])
				var expected: String = (question.holds if holder else question.not_held)[sheet.attitudes[npc]]
				assert_eq(answer.text, expected, "seed %d %s attitude line" % [seed_value, question.id])


func test_question_list_does_not_depend_on_the_root_cause() -> void:
	# With nothing revealed, every case shows the same list for each NPC.
	for npc: StringName in NPCS:
		var first: Array[DialogueData.Question] = DialogueRules.visible_questions(
			_data.questions_for(npc), [] as Array[StringName])
		for seed_value: int in range(1, 31):
			CaseGenerator.new().generate(_template, seed_value)
			assert_eq(DialogueRules.visible_questions(_data.questions_for(npc), [] as Array[StringName]), first)


func test_each_npc_has_a_locked_follow_up() -> void:
	for npc: StringName in NPCS:
		var locked: int = 0
		for question: DialogueData.Question in _data.questions_for(npc):
			if not question.unlock_any.is_empty():
				locked += 1
		assert_between(locked, 1, 2, "%s follow-ups" % npc)
