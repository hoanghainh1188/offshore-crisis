extends GutTest
## The artifact viewer on its own (specs/artifact-viewer: list, content, reveal, close).

const SEED: int = 42

var _viewer: ArtifactViewer


func before_each() -> void:
	GameState.reset_run()
	GameState.start_case(SEED)
	_viewer = (load("res://artifacts/artifact_viewer.tscn") as PackedScene).instantiate() as ArtifactViewer
	add_child_autofree(_viewer)
	watch_signals(_viewer)
	watch_signals(GameState)
	await wait_process_frames(1)


func after_each() -> void:
	GameState.reset_run()


func _expected(type: StringName) -> ArtifactDocument:
	return ArtifactDocument.build(GameState.truth_sheet, type,
		ArtifactFiller.load_from(ArtifactViewer.FILLER_PATH))


## A type that holds at least one fact for SEED, so reveal tests are meaningful.
func _type_with_facts() -> StringName:
	for type: StringName in ArtifactDocument.TYPES:
		if not _expected(type).fact_ids.is_empty():
			return type
	return &""


func _press_esc() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)


func test_hidden_until_opened() -> void:
	assert_false(_viewer.is_open())


func test_lists_types_in_spec_order() -> void:
	_viewer.open()
	assert_eq(_viewer.listed_titles(), ["Ticket", "Chat log", "Meeting notes"] as Array[String])


func test_first_document_button_has_focus_on_open() -> void:
	_viewer.open()
	await wait_process_frames(1)
	assert_eq(_viewer.document_button(&"ticket").has_focus(), true)


func test_document_text_matches_the_builder() -> void:
	_viewer.open()
	for type: StringName in ArtifactDocument.TYPES:
		_viewer.document_button(type).pressed.emit()
		var expected: ArtifactDocument = _expected(type)
		assert_eq(_viewer.shown_title(), expected.title)
		assert_eq(_viewer.shown_lines(), expected.lines)


func test_opening_a_document_reveals_its_facts() -> void:
	var type: StringName = _type_with_facts()
	assert_ne(type, &"", "seed %d puts a fact in some part-1 artifact" % SEED)
	_viewer.open()
	_viewer.document_button(type).pressed.emit()
	for fact_id: StringName in _expected(type).fact_ids:
		assert_has(GameState.revealed_fact_ids, fact_id)


func test_reopening_reveals_nothing_new() -> void:
	var type: StringName = _type_with_facts()
	_viewer.open()
	_viewer.document_button(type).pressed.emit()
	var count: int = get_signal_emit_count(GameState, "fact_revealed")
	_viewer.document_button(type).pressed.emit()
	_viewer.close()
	_viewer.open()
	_viewer.document_button(type).pressed.emit()
	assert_signal_emit_count(GameState, "fact_revealed", count)


func test_close_button_closes() -> void:
	_viewer.open()
	_viewer.close_button().pressed.emit()
	assert_false(_viewer.is_open())
	assert_signal_emit_count(_viewer, "closed", 1)


func test_esc_closes() -> void:
	_viewer.open()
	await _press_esc()
	assert_false(_viewer.is_open())
	assert_signal_emit_count(_viewer, "closed", 1)


func test_esc_does_nothing_when_closed() -> void:
	await _press_esc()
	assert_signal_not_emitted(_viewer, "closed")


func test_viewer_uses_the_japanese_font() -> void:
	var theme: Theme = _viewer.get_node("%Panel").theme
	assert_not_null(theme)
	assert_eq(theme.default_font.resource_path, "res://fonts/noto_sans_jp_subset.ttf")


func test_without_a_case_documents_are_filler_only() -> void:
	GameState.reset_run()
	_viewer.open()
	_viewer.document_button(&"chat_log").pressed.emit()
	var filler: ArtifactFiller = ArtifactFiller.load_from(ArtifactViewer.FILLER_PATH)
	assert_eq(_viewer.shown_lines(), filler.lines_for(&"chat_log"))


func test_missing_filler_disables_documents_instead_of_crashing() -> void:
	var viewer: ArtifactViewer = (load("res://artifacts/artifact_viewer.tscn") as PackedScene).instantiate() as ArtifactViewer
	viewer.filler_path = "res://tests/fixtures/artifacts/does_not_exist.json"
	add_child_autofree(viewer)
	assert_push_error("does_not_exist.json")
	viewer.open()
	assert_true(viewer.document_button(&"ticket").disabled)
	viewer.document_button(&"ticket").pressed.emit()
	assert_eq(viewer.shown_lines(), [] as Array[String])
