extends GutTest
## Shipped dialogue content against the "Wrong Delivery" template, across many cases
## (specs/npc-dialogue).

const DIALOGUE_PATH: String = "res://dialogue/dialogue_offline.json"
const NPCS: Array[StringName] = [&"linh", &"trang", &"minh", &"hana", &"tanaka"]
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
		assert_between(locked, 1, 3, "%s follow-ups" % npc)



# --- follow-ups unlocked by reading the git log or spec (artifacts-viewer-part2) ---

func _find(npc: StringName, id: StringName) -> DialogueData.Question:
	for question: DialogueData.Question in _data.questions_for(npc):
		if question.id == id:
			return question
	return null


func _assert_answers_every_attitude(npc: StringName, question: DialogueData.Question) -> void:
	var attitudes: Array[StringName] = []
	for candidate: CaseTemplate.Npc in _template.npcs:
		if candidate.id == npc:
			attitudes.assign(candidate.attitudes)
	assert_gt(attitudes.size(), 0, "%s has an attitude pool" % npc)
	for attitude: StringName in attitudes:
		assert_true(question.not_held.has(attitude), "%s not_held %s" % [question.id, attitude])
		if question.fact != &"":
			assert_true(question.holds.has(attitude), "%s holds %s" % [question.id, attitude])


func test_linh_no_ticket_follow_up() -> void:
	var question: DialogueData.Question = _find(&"linh", &"linh_no_ticket_followup")
	assert_not_null(question)
	if question == null:
		return
	assert_eq(question.fact, &"fact_coc_chat_agreement")
	assert_eq(question.unlock_any, [&"fact_coc_no_ticket"] as Array[StringName])
	assert_eq(_data.questions_for(&"linh").back(), question, "last in Linh's list")
	_assert_answers_every_attitude(&"linh", question)


func test_trang_closing_follow_up() -> void:
	var question: DialogueData.Question = _find(&"trang", &"trang_closing_followup")
	assert_not_null(question)
	if question == null:
		return
	assert_eq(question.fact, &"")
	assert_eq(question.unlock_any, [&"fact_lit_jp_spec_closing"] as Array[StringName])
	assert_string_contains(question.text, "月次締め")
	assert_eq(_data.questions_for(&"trang").back(), question, "last in Trang's list")
	_assert_answers_every_attitude(&"trang", question)


func test_every_chain_fact_is_reachable_across_seeds() -> void:
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = CaseGenerator.new().generate(_template, seed_value)
		var reached: Array[StringName] = []
		for fact_id: StringName in sheet.knowledge:
			if (sheet.knowledge[fact_id] as String).begins_with("artifact:"):
				reached.append(fact_id)
		var changed: bool = true
		while changed:
			changed = false
			for npc: StringName in NPCS:
				for question: DialogueData.Question in DialogueRules.visible_questions(
						_data.questions_for(npc), reached):
					if question.fact != &"" \
							and sheet.knowledge.get(question.fact, "") == "npc:%s" % npc \
							and not reached.has(question.fact):
						reached.append(question.fact)
						changed = true
		for fact: CaseTemplate.Fact in sheet.chain:
			assert_has(reached, fact.id, "seed %d reaches chain fact %s" % [seed_value, fact.id])


func test_part2_follow_ups() -> void:
	var minh_q: DialogueData.Question = _find(&"minh", &"minh_chat_followup")
	assert_not_null(minh_q)
	if minh_q != null:
		assert_eq(minh_q.fact, &"fact_coc_no_ticket")
		assert_eq(minh_q.unlock_any, [&"fact_coc_chat_agreement"] as Array[StringName])
		_assert_answers_every_attitude(&"minh", minh_q)

	var hana_q: DialogueData.Question = _find(&"hana", &"hana_hai_followup")
	assert_not_null(hana_q)
	if hana_q != null:
		assert_eq(hana_q.fact, &"fact_py_hai_recorded")
		assert_eq(hana_q.unlock_any, [&"fact_py_meeting_proposal"] as Array[StringName])
		_assert_answers_every_attitude(&"hana", hana_q)

	var tanaka_q: DialogueData.Question = _find(&"tanaka", &"tanaka_hai_followup")
	assert_not_null(tanaka_q)
	if tanaka_q != null:
		assert_eq(tanaka_q.fact, &"fact_py_check_internally")
		assert_eq(tanaka_q.unlock_any, [&"fact_py_hai_recorded"] as Array[StringName])
		_assert_answers_every_attitude(&"tanaka", tanaka_q)


func test_honest_and_indirect_non_held_answers_do_not_mislead() -> void:
	var checks: Array[Array] = [
		[&"linh", &"honest"],
		[&"trang", &"honest"],
		[&"hana", &"honest"],
		[&"tanaka", &"indirect"],
	]
	for pair: Array in checks:
		var npc: StringName = pair[0]
		var attitude: StringName = pair[1]
		for question: DialogueData.Question in _data.questions_for(npc):
			if question.fact == &"":
				continue
			var held_line: String = question.holds.get(attitude, "")
			var non_held_line: String = question.not_held.get(attitude, "")
			assert_ne(non_held_line, "", "%s %s non_held" % [question.id, attitude])
			assert_ne(non_held_line, held_line, "%s %s differs from holds" % [question.id, attitude])
