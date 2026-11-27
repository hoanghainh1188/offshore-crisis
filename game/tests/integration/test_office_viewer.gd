extends GutTest
## Document Shelf -> viewer in the real office room (specs/artifact-viewer).

var _room: OfficeRoom
var _player: Player
var _viewer: ArtifactViewer


func before_each() -> void:
	GameState.reset_run()
	GameState.start_case(42)
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	_player = _room.get_node("Player") as Player
	_viewer = _room.get_node("ArtifactViewer") as ArtifactViewer
	await wait_physics_frames(2)


func after_each() -> void:
	Input.action_release(&"move_right")
	GameState.reset_run()


func _target(node_name: String) -> Interactable:
	return _room.get_node("Interactables/%s" % node_name) as Interactable


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


func _open_from_shelf() -> void:
	await _stand_at(_target("DocumentShelf").position + Vector2(16, 0))
	await _press(KEY_E)


func test_shelf_opens_the_viewer() -> void:
	watch_signals(_target("DocumentShelf"))
	await _open_from_shelf()
	assert_true(_viewer.is_open())
	# Interactable.interact() logs the line and then emits interacted (specs/world-interaction).
	assert_signal_emit_count(_target("DocumentShelf"), "interacted", 1)


func test_linh_does_not_open_the_viewer() -> void:
	var linh: Interactable = _target("Linh")
	watch_signals(linh)
	await _stand_at(Vector2(232, 112))
	await _press(KEY_E)
	assert_signal_emit_count(linh, "interacted", 1)
	assert_false(_viewer.is_open())


func test_player_is_frozen_while_reading() -> void:
	await _open_from_shelf()
	var start: Vector2 = _player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	assert_eq(_player.position, start)


func test_interact_key_does_nothing_while_reading() -> void:
	await _open_from_shelf()
	watch_signals(_player)
	await _press(KEY_E)
	assert_signal_not_emitted(_player, "interaction_triggered")


func test_player_walks_again_after_esc() -> void:
	await _open_from_shelf()
	await _press(KEY_ESCAPE)
	assert_false(_viewer.is_open())
	var start: Vector2 = _player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, start.x)


func test_player_can_interact_again_after_closing() -> void:
	await _open_from_shelf()
	await _press(KEY_ESCAPE)
	await wait_physics_frames(3)
	assert_eq(_player.try_interact(), _target("DocumentShelf"))
