extends GutTest
## Asking questions in a run through GameState (specs/npc-dialogue: reveal, cost, asked).

var _data: DialogueData


func before_each() -> void:
	GameState.reset_run()
	watch_signals(GameState)


func after_each() -> void:
	GameState.reset_run()


## Starts a case whose Truth Sheet gives `fact_id` to `holder`, with the clock running.
func _start_case_where(fact_id: StringName, holder: String) -> void:
	for seed_value: int in range(1, 500):
		GameState.start_case(seed_value)
		if GameState.truth_sheet.knowledge.get(fact_id, "") == holder:
			break
	assert_eq(GameState.truth_sheet.knowledge.get(fact_id, ""), holder, "found a seed")
	GameState.clock.start(900.0)
	GameState.clock.pause(&"test")  # Only question costs move time in these tests.
	_data = DialogueData.load_from("res://dialogue/dialogue_offline.json", GameState.case_template())


func _question(npc: StringName, id: StringName) -> DialogueData.Question:
	for question: DialogueData.Question in _data.questions_for(npc):
		if question.id == id:
			return question
	return null


func _office_time() -> String:
	return RunClock.format_office_time(GameState.clock.office_minutes())


func test_tuning_defaults_to_fifteen_minutes() -> void:
	var tuning: DialogueTuning = load("res://dialogue/dialogue_tuning.tres") as DialogueTuning
	assert_eq(tuning.question_cost_minutes, 15)


func test_first_ask_reveals_and_costs_fifteen_minutes() -> void:
	_start_case_where(&"fact_lit_ticket_calendar", "npc:linh")
	var answer: DialogueAnswer = GameState.ask_question(&"linh", _question(&"linh", &"linh_ticket_wording"))
	assert_eq(answer.reveals, &"fact_lit_ticket_calendar")
	assert_has(GameState.revealed_fact_ids, &"fact_lit_ticket_calendar")
	assert_eq(_office_time(), "09:15")
	assert_true(GameState.is_asked(&"linh_ticket_wording"))


func test_asking_again_is_free_and_reveals_nothing_new() -> void:
	_start_case_where(&"fact_lit_ticket_calendar", "npc:linh")
	var question: DialogueData.Question = _question(&"linh", &"linh_ticket_wording")
	var first: DialogueAnswer = GameState.ask_question(&"linh", question)
	var second: DialogueAnswer = GameState.ask_question(&"linh", question)
	assert_eq(second.text, first.text)
	assert_eq(_office_time(), "09:15")
	assert_signal_emit_count(GameState, "fact_revealed", 1)


func test_non_answer_costs_time_but_reveals_nothing() -> void:
	_start_case_where(&"fact_lit_ticket_calendar", "artifact:ticket")
	var answer: DialogueAnswer = GameState.ask_question(&"linh", _question(&"linh", &"linh_ticket_wording"))
	assert_eq(answer.reveals, &"")
	assert_eq(GameState.revealed_fact_ids.size(), 0)
	assert_eq(_office_time(), "09:15")


func test_question_at_four_fifty_ends_the_day_and_still_reveals() -> void:
	_start_case_where(&"fact_lit_ticket_calendar", "npc:linh")
	GameState.clock.advance_minutes(470)
	watch_signals(GameState.clock)
	GameState.ask_question(&"linh", _question(&"linh", &"linh_ticket_wording"))
	assert_signal_emit_count(GameState.clock, "time_up", 1)
	assert_has(GameState.revealed_fact_ids, &"fact_lit_ticket_calendar")


func test_asked_state_is_per_run() -> void:
	_start_case_where(&"fact_lit_ticket_calendar", "npc:linh")
	GameState.ask_question(&"linh", _question(&"linh", &"linh_release_work"))
	GameState.start_case(7)
	assert_false(GameState.is_asked(&"linh_release_work"), "new case clears asked")
	GameState.ask_question(&"linh", _question(&"linh", &"linh_release_work"))
	GameState.reset_run()
	assert_false(GameState.is_asked(&"linh_release_work"), "reset clears asked")


func _remote_question(id: StringName, fact_id: StringName) -> DialogueData.Question:
	var question: DialogueData.Question = DialogueData.Question.new()
	question.id = id
	question.text = "Remote test question"
	question.fact = fact_id
	question.holds = {&"indirect": "We did ask in chat."}
	question.not_held = {&"indirect": "I would need to check."}
	return question


func test_remote_tuning_defaults_to_thirty_minutes() -> void:
	var tuning: DialogueTuning = load("res://dialogue/dialogue_tuning.tres") as DialogueTuning
	assert_eq(tuning.remote_question_cost_minutes, 30)
	assert_eq(tuning.cost_for(&"tanaka"), 30)
	assert_eq(tuning.cost_for(&"linh"), 15)


func test_remote_first_ask_costs_thirty_minutes_and_repeat_is_free() -> void:
	_start_case_where(&"fact_coc_chat_agreement", "npc:tanaka")
	var question: DialogueData.Question = _remote_question(&"tanaka_test_cost", &"fact_coc_chat_agreement")
	var first: DialogueAnswer = GameState.ask_question(&"tanaka", question)
	assert_eq(first.reveals, &"fact_coc_chat_agreement")
	assert_eq(_office_time(), "09:30")
	var second: DialogueAnswer = GameState.ask_question(&"tanaka", question)
	assert_eq(second.text, first.text)
	assert_eq(_office_time(), "09:30")
	assert_signal_emit_count(GameState, "fact_revealed", 1)


func test_remote_question_at_four_thirty_five_ends_the_day() -> void:
	_start_case_where(&"fact_coc_chat_agreement", "npc:tanaka")
	GameState.clock.advance_minutes(455)
	watch_signals(GameState.clock)
	GameState.ask_question(&"tanaka", _remote_question(&"tanaka_test_end", &"fact_coc_chat_agreement"))
	assert_signal_emit_count(GameState.clock, "time_up", 1)
	assert_has(GameState.revealed_fact_ids, &"fact_coc_chat_agreement")
