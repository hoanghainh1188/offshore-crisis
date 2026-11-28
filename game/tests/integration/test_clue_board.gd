extends GutTest
## The clue board scene on its own (specs/clue-board): tray, pin, drag, link, unpin, keys.

var _board: ClueBoard
var _facts: Array[StringName] = []


func before_each() -> void:
	GameState.reset_run()
	GameState.start_case(42)
	_facts = []
	for fact: CaseTemplate.Fact in GameState.truth_sheet.chain:
		_facts.append(fact.id)
	for fact: CaseTemplate.Fact in GameState.truth_sheet.red_herrings:
		_facts.append(fact.id)
	_board = (load("res://clue_board/clue_board.tscn") as PackedScene).instantiate() as ClueBoard
	add_child_autofree(_board)
	await wait_process_frames(2)


func after_each() -> void:
	GameState.reset_run()


func _reveal(count: int) -> void:
	for i: int in count:
		GameState.reveal_fact(_facts[i])


func _open() -> void:
	_board.open()
	await wait_process_frames(2)


func _press_key(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	var release: InputEventKey = event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(2)


func _mouse_button(view: ClueCardView, global: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.global_position = global
	event.position = global
	view._gui_input(event)


func _mouse_move(view: ClueCardView, global: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.global_position = global
	event.position = global
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	view._gui_input(event)


func _click(view: ClueCardView) -> void:
	_mouse_button(view, Vector2(10, 10), true)
	_mouse_button(view, Vector2(10, 10), false)
	await wait_process_frames(1)


func _drag(view: ClueCardView, by: Vector2) -> void:
	_mouse_button(view, Vector2(10, 10), true)
	_mouse_move(view, Vector2(10, 10) + by / 2.0)
	_mouse_move(view, Vector2(10, 10) + by)
	_mouse_button(view, Vector2(10, 10) + by, false)
	await wait_process_frames(1)


func _pin(fact_id: StringName) -> void:
	_board.tray_card(fact_id).action_button().pressed.emit()
	await wait_process_frames(2)


# --- Cards and tray ---

func test_starts_closed() -> void:
	assert_false(_board.is_open())


func test_tray_lists_cards_in_reveal_order_with_text_and_source() -> void:
	GameState.reveal_fact(_facts[2])
	GameState.reveal_fact(_facts[0])
	await _open()
	assert_eq(_board.tray_ids_shown(), [_facts[2], _facts[0]] as Array[StringName])
	var expected: ClueCard = ClueCard.from_fact(_facts[2], GameState.truth_sheet,
		GameState.case_template())
	assert_eq(_board.tray_card(_facts[2]).text(), expected.text)
	assert_eq(_board.tray_card(_facts[2]).source(), expected.source)
	assert_false(_board.empty_text_shown())
	assert_eq(_board.count_text(), "2 clues · 0 pinned")


func test_empty_run_shows_empty_text() -> void:
	await _open()
	assert_eq(_board.tray_ids_shown().size(), 0)
	assert_true(_board.empty_text_shown())


func test_reveal_while_open_adds_a_tray_card() -> void:
	_reveal(1)
	await _open()
	GameState.reveal_fact(_facts[1])
	await wait_process_frames(1)
	assert_true(_board.is_open())
	assert_eq(_board.tray_ids_shown(), [_facts[0], _facts[1]] as Array[StringName])


func test_repeated_reveal_keeps_one_card() -> void:
	_reveal(1)
	GameState.reveal_fact(_facts[0])
	await _open()
	assert_eq(_board.tray_ids_shown(), [_facts[0]] as Array[StringName])


func test_pin_moves_card_from_tray_to_board() -> void:
	_reveal(2)
	await _open()
	await _pin(_facts[0])
	assert_eq(_board.tray_ids_shown(), [_facts[1]] as Array[StringName])
	var view: ClueCardView = _board.pinned_card(_facts[0])
	assert_not_null(view)
	assert_eq(view.get_parent(), _board.board_area())
	assert_true(GameState.clue_board.is_pinned(_facts[0]))
	assert_eq(_board.count_text(), "2 clues · 1 pinned")


func test_pinned_cards_land_inside_the_area_on_different_spots() -> void:
	_reveal(4)
	await _open()
	for i: int in 4:
		await _pin(_facts[i])
	var area: Rect2 = Rect2(Vector2.ZERO, _board.board_area().size)
	var spots: Array[Vector2] = []
	for i: int in 4:
		var view: ClueCardView = _board.pinned_card(_facts[i])
		assert_true(area.encloses(Rect2(view.position, view.size)), "card %d inside" % i)
		assert_false(spots.has(view.position), "card %d has its own spot" % i)
		spots.append(view.position)


func test_pins_survive_close_and_reopen() -> void:
	_reveal(1)
	await _open()
	await _pin(_facts[0])
	var pos: Vector2 = _board.pinned_card(_facts[0]).position
	_board.close()
	await _open()
	assert_not_null(_board.pinned_card(_facts[0]))
	assert_eq(_board.pinned_card(_facts[0]).position, pos)


# --- Pinned card input ---

func test_drag_moves_card_and_link_follows() -> void:
	_reveal(2)
	await _open()
	await _pin(_facts[0])
	await _pin(_facts[1])
	await _click(_board.pinned_card(_facts[0]))
	await _click(_board.pinned_card(_facts[1]))
	var view: ClueCardView = _board.pinned_card(_facts[0])
	var start: Vector2 = view.position
	await _drag(view, Vector2(30, 40))
	assert_eq(view.position, start + Vector2(30, 40))
	assert_eq(GameState.clue_board.position_of(_facts[0]), view.position)
	var segments: Array[PackedVector2Array] = _board.board_area().link_segments
	assert_eq(segments.size(), 1)
	assert_true(segments[0].has(view.position + view.size / 2.0))
	assert_true(GameState.clue_board.is_linked(_facts[0], _facts[1]), "drag is not a click")


func test_drag_past_edge_stops_at_edge() -> void:
	_reveal(1)
	await _open()
	await _pin(_facts[0])
	var view: ClueCardView = _board.pinned_card(_facts[0])
	await _drag(view, Vector2(5000, 5000))
	var area: Vector2 = _board.board_area().size
	assert_eq(view.position, (area - view.size).max(Vector2.ZERO))


func test_small_wiggle_is_a_click_not_a_drag() -> void:
	_reveal(1)
	await _open()
	await _pin(_facts[0])
	var view: ClueCardView = _board.pinned_card(_facts[0])
	var start: Vector2 = view.position
	await _drag(view, Vector2(2, 1))
	assert_eq(view.position, start)
	assert_true(view.is_selected())


func test_click_a_then_b_draws_a_link() -> void:
	_reveal(2)
	await _open()
	await _pin(_facts[0])
	await _pin(_facts[1])
	await _click(_board.pinned_card(_facts[0]))
	assert_true(_board.pinned_card(_facts[0]).is_selected())
	await _click(_board.pinned_card(_facts[1]))
	assert_true(GameState.clue_board.is_linked(_facts[0], _facts[1]))
	assert_eq(_board.board_area().link_segments.size(), 1)
	assert_false(_board.pinned_card(_facts[0]).is_selected())


func test_click_pair_again_removes_link() -> void:
	_reveal(2)
	await _open()
	await _pin(_facts[0])
	await _pin(_facts[1])
	await _click(_board.pinned_card(_facts[0]))
	await _click(_board.pinned_card(_facts[1]))
	await _click(_board.pinned_card(_facts[1]))
	await _click(_board.pinned_card(_facts[0]))
	assert_false(GameState.clue_board.is_linked(_facts[0], _facts[1]))
	assert_eq(_board.board_area().link_segments.size(), 0)


func test_unpin_linked_card_returns_it_and_drops_link() -> void:
	_reveal(3)
	await _open()
	await _pin(_facts[0])
	await _pin(_facts[1])
	await _click(_board.pinned_card(_facts[0]))
	await _click(_board.pinned_card(_facts[1]))
	_board.pinned_card(_facts[0]).action_button().pressed.emit()
	await wait_process_frames(2)
	assert_null(_board.pinned_card(_facts[0]))
	assert_eq(_board.tray_ids_shown(), [_facts[0], _facts[2]] as Array[StringName])
	assert_eq(_board.board_area().link_segments.size(), 0)
	assert_eq(GameState.clue_board.links().size(), 0)


# --- Keys, close and focus ---

func test_board_key_toggles() -> void:
	await _press_key(KEY_C)
	assert_true(_board.is_open())
	await _press_key(KEY_C)
	assert_false(_board.is_open())


func test_esc_closes() -> void:
	await _open()
	await _press_key(KEY_ESCAPE)
	assert_false(_board.is_open())


func test_close_button_closes() -> void:
	await _open()
	_board.close_button().pressed.emit()
	assert_false(_board.is_open())


func test_signals_on_open_and_close() -> void:
	watch_signals(_board)
	await _open()
	_board.close()
	assert_signal_emit_count(_board, "opened", 1)
	assert_signal_emit_count(_board, "closed", 1)


func test_focus_goes_to_close_and_comes_back() -> void:
	var before: Button = Button.new()
	add_child_autofree(before)
	before.grab_focus()
	await _open()
	assert_eq(get_viewport().gui_get_focus_owner(), _board.close_button())
	_board.close()
	assert_eq(get_viewport().gui_get_focus_owner(), before)


func test_dim_blocks_clicks_to_panels_below() -> void:
	var dim: ColorRect = _board.get_node("Dim") as ColorRect
	assert_eq(dim.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(dim.get_rect().size, get_viewport().get_visible_rect().size)


# --- Review follow-ups ---

func test_link_ends_on_card_centres_after_reopen() -> void:
	_reveal(2)
	await _open()
	await _pin(_facts[0])
	await _pin(_facts[1])
	await _click(_board.pinned_card(_facts[0]))
	await _click(_board.pinned_card(_facts[1]))
	_board.close()
	await _open()
	await wait_process_frames(2)
	var a: ClueCardView = _board.pinned_card(_facts[0])
	var b: ClueCardView = _board.pinned_card(_facts[1])
	var segment: PackedVector2Array = _board.board_area().link_segments[0]
	assert_true(segment.has(a.position + a.size / 2.0), "starts at A's centre")
	assert_true(segment.has(b.position + b.size / 2.0), "ends at B's centre")


func test_lost_release_does_not_keep_dragging() -> void:
	_reveal(1)
	await _open()
	await _pin(_facts[0])
	var view: ClueCardView = _board.pinned_card(_facts[0])
	_mouse_button(view, Vector2(10, 10), true)
	_mouse_move(view, Vector2(40, 40))
	var after_drag: Vector2 = view.position
	var hover: InputEventMouseMotion = InputEventMouseMotion.new()
	hover.global_position = Vector2(90, 90)
	hover.button_mask = 0
	view._gui_input(hover)
	_mouse_move(view, Vector2(120, 120))
	assert_eq(view.position, after_drag, "card stops following once the button is up")


func test_focus_stays_on_the_board_after_pin_and_unpin() -> void:
	_reveal(2)
	await _open()
	_board.tray_card(_facts[0]).action_button().grab_focus()
	await _pin(_facts[0])
	assert_eq(get_viewport().gui_get_focus_owner(), _board.tray_card(_facts[1]).action_button())
	_board.pinned_card(_facts[0]).action_button().grab_focus()
	_board.pinned_card(_facts[0]).action_button().pressed.emit()
	await wait_process_frames(2)
	assert_not_null(get_viewport().gui_get_focus_owner())


func test_unpinning_selected_card_clears_selection() -> void:
	_reveal(2)
	await _open()
	await _pin(_facts[0])
	await _pin(_facts[1])
	await _click(_board.pinned_card(_facts[0]))
	_board.pinned_card(_facts[0]).action_button().pressed.emit()
	await wait_process_frames(2)
	await _click(_board.pinned_card(_facts[1]))
	assert_true(_board.pinned_card(_facts[1]).is_selected(), "B starts a new link, not linked to A")
	assert_eq(GameState.clue_board.links().size(), 0)


func test_new_pin_reuses_a_freed_slot() -> void:
	_reveal(4)
	await _open()
	for i: int in 3:
		await _pin(_facts[i])
	var freed: Vector2 = _board.pinned_card(_facts[0]).position
	_board.pinned_card(_facts[0]).action_button().pressed.emit()
	await wait_process_frames(2)
	await _pin(_facts[3])
	assert_eq(_board.pinned_card(_facts[3]).position, freed)


func test_reveal_while_open_keeps_pinned_cards() -> void:
	_reveal(1)
	await _open()
	await _pin(_facts[0])
	GameState.reveal_fact(_facts[1])
	await wait_process_frames(1)
	assert_not_null(_board.pinned_card(_facts[0]))
	assert_eq(_board.tray_ids_shown(), [_facts[1]] as Array[StringName])
