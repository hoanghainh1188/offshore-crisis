extends GutTest
## Clue board in the real office room (specs/clue-board): open anywhere, close back to the
## panel underneath, player stays frozen, clicks and keys do not reach the room.

const LINH_SPOT: Vector2 = Vector2(232, 112)

var _room: OfficeRoom
var _player: Player
var _viewer: ArtifactViewer
var _dialogue: DialoguePanel
var _board: ClueBoard


func before_each() -> void:
	GameState.reset_run()
	GameState.start_case(42)
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	_player = _room.get_node("Player") as Player
	_viewer = _room.get_node("ArtifactViewer") as ArtifactViewer
	_dialogue = _room.get_node("DialoguePanel") as DialoguePanel
	_board = _room.get_node("ClueBoard") as ClueBoard
	await wait_physics_frames(2)


func after_each() -> void:
	Input.action_release(&"move_right")
	GameState.reset_run()


func _stand_at(pos: Vector2) -> void:
	_player.position = pos
	await wait_physics_frames(3)


func _press(key: Key) -> void:
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


func _assert_frozen() -> void:
	var start: Vector2 = _player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	Input.action_release(&"move_right")
	assert_eq(_player.position, start, "player does not move")


func _assert_walks() -> void:
	var start: Vector2 = _player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	Input.action_release(&"move_right")
	assert_gt(_player.position.x, start.x, "player walks")


func _open_viewer() -> void:
	await _stand_at(_room.get_node("Interactables/DocumentShelf").position + Vector2(16, 0))
	await _press(KEY_E)


func test_board_key_opens_board_in_the_office_and_freezes_player() -> void:
	await _press(KEY_C)
	assert_true(_board.is_open())
	await _assert_frozen()


func test_esc_closes_board_and_player_walks_again() -> void:
	await _press(KEY_C)
	await _press(KEY_ESCAPE)
	assert_false(_board.is_open())
	await _assert_walks()


func test_board_over_viewer_one_esc_closes_only_board() -> void:
	await _open_viewer()
	assert_true(_viewer.is_open())
	await _press(KEY_C)
	assert_true(_board.is_open())
	assert_true(_viewer.is_open(), "viewer stays open under the board")
	await _press(KEY_ESCAPE)
	assert_false(_board.is_open())
	assert_true(_viewer.is_open())
	await _assert_frozen()
	await _press(KEY_ESCAPE)
	assert_false(_viewer.is_open())
	await _assert_walks()


func test_board_over_dialogue_one_esc_closes_only_board() -> void:
	await _stand_at(LINH_SPOT)
	await _press(KEY_E)
	assert_true(_dialogue.is_open())
	await _press(KEY_C)
	assert_true(_board.is_open())
	await _press(KEY_ESCAPE)
	assert_false(_board.is_open())
	assert_true(_dialogue.is_open())
	await _assert_frozen()


func test_board_key_closes_board_over_viewer_and_keeps_viewer() -> void:
	await _open_viewer()
	await _press(KEY_C)
	await _press(KEY_C)
	assert_false(_board.is_open())
	assert_true(_viewer.is_open())


func test_focus_returns_to_the_viewer_after_board() -> void:
	await _open_viewer()
	var focused: Control = get_viewport().gui_get_focus_owner()
	assert_not_null(focused)
	await _press(KEY_C)
	await _press(KEY_ESCAPE)
	assert_eq(get_viewport().gui_get_focus_owner(), focused)


## GUT's output panel covers the root viewport, so this test runs its own room in a
## SubViewport where simulated clicks reach the game UI.
func _room_in_subviewport() -> SubViewport:
	var sub: SubViewport = SubViewport.new()
	sub.size = Vector2i(640, 360)
	sub.gui_disable_input = false
	add_child_autofree(sub)
	sub.add_child((load("res://office/office_room.tscn") as PackedScene).instantiate())
	await wait_process_frames(2)
	return sub


func _click_in(sub: SubViewport, at: Vector2) -> void:
	var hover: InputEventMouseMotion = InputEventMouseMotion.new()
	hover.position = at
	hover.global_position = at
	sub.push_input(hover, true)
	await wait_process_frames(1)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = at
		event.global_position = at
		sub.push_input(event, true)
		await wait_process_frames(1)


func _ticket_click(board_open: bool) -> String:
	var sub: SubViewport = await _room_in_subviewport()
	var room: OfficeRoom = sub.get_child(0) as OfficeRoom
	var viewer: ArtifactViewer = room.get_node("ArtifactViewer") as ArtifactViewer
	room._open_viewer("Document Shelf")
	if board_open:
		(room.get_node("ClueBoard") as ClueBoard).open()
	await wait_process_frames(2)
	await _click_in(sub, viewer.document_button(&"ticket").get_global_rect().get_center())
	return viewer.shown_title()


func test_click_reaches_viewer_button_without_board() -> void:
	# Control case: proves the simulated click can press the button at all.
	assert_ne(await _ticket_click(false), "")


func test_click_on_viewer_button_does_nothing_while_board_is_open() -> void:
	assert_eq(await _ticket_click(true), "", "no document opened under the board")


func test_interact_key_does_nothing_while_board_is_open() -> void:
	await _stand_at(LINH_SPOT)
	await _press(KEY_C)
	watch_signals(_player)
	await _press(KEY_E)
	assert_signal_not_emitted(_player, "interaction_triggered")
	assert_false(_dialogue.is_open())
