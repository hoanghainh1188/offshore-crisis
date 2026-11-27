extends GutTest
## Run case and revealed facts in GameState (specs/fact-discovery, specs/run-flow).

const SEED: int = 42


func before_each() -> void:
	GameState.reset_run()
	watch_signals(GameState)


func after_each() -> void:
	GameState.reset_run()


func _chain_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for fact: CaseTemplate.Fact in GameState.truth_sheet.chain:
		ids.append(fact.id)
	return ids


func test_no_case_after_reset() -> void:
	assert_null(GameState.truth_sheet)
	assert_eq(GameState.revealed_fact_ids.size(), 0)


func test_start_case_sets_sheet_and_seed() -> void:
	GameState.start_case(SEED)
	assert_not_null(GameState.truth_sheet)
	assert_eq(GameState.truth_sheet.seed, SEED)


func test_logged_seed_reproduces_the_case() -> void:
	GameState.start_case(SEED)
	var template: CaseTemplate = CaseTemplateLoader.new().load_template(GameState.CASE_TEMPLATE_PATH)
	var again: TruthSheet = CaseGenerator.new().generate(template, SEED)
	assert_eq(JSON.stringify(again.to_dict()), JSON.stringify(GameState.truth_sheet.to_dict()))


func test_case_log_line() -> void:
	assert_eq(CaseLog.format(42), "[case] seed 42")


func test_case_log_line_hides_the_root_cause() -> void:
	GameState.start_case(SEED)
	var line: String = CaseLog.format(SEED)
	assert_false(line.contains(String(GameState.truth_sheet.root_cause_id)))
	assert_false(line.contains(GameState.truth_sheet.root_cause_description))


func test_reveals_are_kept_in_order() -> void:
	GameState.start_case(SEED)
	var ids: Array[StringName] = _chain_ids()
	assert_true(GameState.reveal_fact(ids[1]))
	assert_true(GameState.reveal_fact(ids[0]))
	assert_eq(GameState.revealed_fact_ids, [ids[1], ids[0]] as Array[StringName])


func test_reveal_again_changes_nothing_and_announces_once() -> void:
	GameState.start_case(SEED)
	var id: StringName = _chain_ids()[0]
	GameState.reveal_fact(id)
	assert_false(GameState.reveal_fact(id))
	assert_eq(GameState.revealed_fact_ids, [id] as Array[StringName])
	assert_signal_emit_count(GameState, "fact_revealed", 1)
	assert_signal_emitted_with_parameters(GameState, "fact_revealed", [id])


func test_red_herrings_can_be_revealed() -> void:
	GameState.start_case(SEED)
	var herring: StringName = GameState.truth_sheet.red_herrings[0].id
	assert_true(GameState.reveal_fact(herring))


func test_unknown_fact_is_ignored() -> void:
	GameState.start_case(SEED)
	assert_false(GameState.reveal_fact(&"not_a_fact"))
	assert_eq(GameState.revealed_fact_ids.size(), 0)
	assert_signal_not_emitted(GameState, "fact_revealed")


func test_reveal_without_a_case_is_ignored() -> void:
	assert_false(GameState.reveal_fact(&"fact_lit_ticket_calendar"))
	assert_eq(GameState.revealed_fact_ids.size(), 0)


func test_new_run_clears_revealed_facts() -> void:
	GameState.start_case(SEED)
	GameState.reveal_fact(_chain_ids()[0])
	GameState.reset_run()
	assert_eq(GameState.revealed_fact_ids.size(), 0)
	assert_null(GameState.truth_sheet)
