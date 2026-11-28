extends GutTest
## Card text and source label (specs/clue-board: card shows the fact text and its source).

var _template: CaseTemplate


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template(GameState.CASE_TEMPLATE_PATH)


func _sheet(seed_value: int) -> TruthSheet:
	return CaseGenerator.new().generate(_template, seed_value)


func _all_facts(sheet: TruthSheet) -> Array[CaseTemplate.Fact]:
	var facts: Array[CaseTemplate.Fact] = []
	facts.append_array(sheet.chain)
	facts.append_array(sheet.red_herrings)
	return facts


func test_npc_holder_gives_display_name() -> void:
	assert_eq(ClueCard.source_label("npc:hana", _template), "Hana")
	assert_eq(ClueCard.source_label("npc:tanaka", _template), "Tanaka-san")


func test_artifact_holder_gives_document_name() -> void:
	assert_eq(ClueCard.source_label("artifact:git_log", _template), "Git log")
	assert_eq(ClueCard.source_label("artifact:spec_doc", _template), "Spec document")


func test_unknown_holder_falls_back_to_raw_string() -> void:
	assert_eq(ClueCard.source_label("npc:nobody", _template), "npc:nobody")
	assert_eq(ClueCard.source_label("weird", _template), "weird")


func test_text_is_truth_sheet_text_for_chain_and_red_herrings() -> void:
	var sheet: TruthSheet = _sheet(7)
	for fact: CaseTemplate.Fact in _all_facts(sheet):
		var card: ClueCard = ClueCard.from_fact(fact.id, sheet, _template)
		assert_eq(card.fact_id, fact.id)
		assert_eq(card.text, fact.text)


func test_card_source_is_this_runs_holder() -> void:
	var sheet: TruthSheet = _sheet(7)
	var fact: CaseTemplate.Fact = sheet.chain[0]
	var card: ClueCard = ClueCard.from_fact(fact.id, sheet, _template)
	assert_eq(card.source, ClueCard.source_label(sheet.knowledge[fact.id], _template))


func test_every_fact_gets_a_real_label_for_300_seeds() -> void:
	var bad: Array[String] = []
	for seed_value: int in range(1, 301):
		var sheet: TruthSheet = _sheet(seed_value)
		for fact: CaseTemplate.Fact in _all_facts(sheet):
			var card: ClueCard = ClueCard.from_fact(fact.id, sheet, _template)
			if card.source == "" or card.source.contains(":"):
				bad.append("seed %d %s -> '%s'" % [seed_value, fact.id, card.source])
	assert_eq(bad, [] as Array[String])
