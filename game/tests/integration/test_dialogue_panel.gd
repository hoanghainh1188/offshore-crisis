extends GutTest
## The dialogue panel on its own (specs/npc-dialogue: header, list, asked marker, unlock,
## close).

var _panel: DialoguePanel


func before_each() -> void:
	GameState.reset_run()
	# A case where Trang can reveal the chat agreement's follow-up target is not needed;
	# any case works for list and marker tests.
	GameState.start_case(42)
	GameState.clock.start(900.0)
	GameState.clock.pause(&"test")
	_panel = (load("res://dialogue/dialogue_panel.tscn") as PackedScene).instantiate() as DialoguePanel
	add_child_autofree(_panel)
	watch_signals(_panel)
	await wait_process_frames(1)


func after_each() -> void:
	GameState.reset_run()


func _press_esc() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)


func test_only_npcs_with_content_have_dialogue() -> void:
	assert_true(_panel.has_dialogue(&"linh"))
	assert_true(_panel.has_dialogue(&"trang"))
	assert_true(_panel.has_dialogue(&"minh"))
	assert_true(_panel.has_dialogue(&"hana"))
	assert_true(_panel.has_dialogue(&"tanaka"))
	assert_false(_panel.has_dialogue(&"unknown_npc"))


func test_header_shows_name_and_role() -> void:
	_panel.open(&"linh")
	assert_eq(_panel.header_name(), "Linh")
	assert_eq(_panel.header_role(), "Dev lead")


func test_lists_unlocked_questions_in_data_order() -> void:
	_panel.open(&"linh")
	assert_eq(_panel.listed_question_ids(), [&"linh_release_work", &"linh_ticket_wording",
		&"linh_client_changes", &"linh_who_decided", &"linh_release_day"] as Array[StringName])


func test_first_question_has_focus() -> void:
	_panel.open(&"trang")
	await wait_process_frames(1)
	assert_true(_panel.question_button(&"trang_testing_overall").has_focus())


func test_asking_shows_the_answer_and_marks_it() -> void:
	_panel.open(&"trang")
	_panel.question_button(&"trang_testing_overall").pressed.emit()
	assert_eq(_panel.shown_answer(), "We ran the full regression. Two small UI issues, nothing serious.")
	assert_string_starts_with(_panel.question_button(&"trang_testing_overall").text, "✓ ")
	assert_eq(RunClock.format_office_time(GameState.clock.office_minutes()), "09:15")


func test_asked_marker_survives_reopening() -> void:
	_panel.open(&"trang")
	_panel.question_button(&"trang_testing_overall").pressed.emit()
	_panel.close()
	_panel.open(&"trang")
	assert_string_starts_with(_panel.question_button(&"trang_testing_overall").text, "✓ ")
	assert_false(_panel.question_button(&"trang_export_checks").text.begins_with("✓ "))


func test_follow_up_appears_while_open() -> void:
	_panel.open(&"trang")
	assert_false(_panel.listed_question_ids().has(&"trang_chat_followup"))
	# Force the unlock fact into this case so it can be revealed.
	GameState.truth_sheet.knowledge[&"fact_coc_chat_agreement"] = "artifact:chat_log"
	GameState.reveal_fact(&"fact_coc_chat_agreement")
	await wait_process_frames(1)
	assert_true(_panel.listed_question_ids().has(&"trang_chat_followup"))


func test_close_button_and_esc_close() -> void:
	_panel.open(&"linh")
	_panel.close_button().pressed.emit()
	assert_false(_panel.is_open())
	_panel.open(&"linh")
	await _press_esc()
	assert_false(_panel.is_open())
	assert_signal_emit_count(_panel, "closed", 2)


func test_panel_uses_the_japanese_font_theme() -> void:
	var theme: Theme = _panel.get_node("%Panel").theme
	assert_eq(theme.default_font.resource_path, "res://fonts/noto_sans_jp_subset.ttf")


func test_revealing_answer_rebuilds_list_safely() -> void:
	# Make Linh the holder so the answer reveals a fact and the list rebuilds mid-press.
	GameState.truth_sheet.knowledge[&"fact_lit_ticket_calendar"] = "npc:linh"
	_panel.open(&"linh")
	_panel.question_button(&"linh_ticket_wording").pressed.emit()
	await wait_process_frames(2)
	assert_has(GameState.revealed_fact_ids, &"fact_lit_ticket_calendar")
	assert_string_contains(_panel.shown_answer(), "calendar month")
	assert_string_starts_with(_panel.question_button(&"linh_ticket_wording").text, "✓ ")
	assert_true(_panel.question_button(&"linh_ticket_wording").has_focus(), "focus kept")
