extends GutTest
## Drives the interact key in the real office room (specs/world-interaction).

var _room: OfficeRoom
var _player: Player


func before_each() -> void:
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	_player = _room.get_node("Player") as Player
	watch_signals(_player)
	await wait_physics_frames(2)


func _target(node_name: String) -> Interactable:
	return _room.get_node("Interactables/%s" % node_name) as Interactable


## Teleports the player and waits so the physics server updates area overlaps.
func _stand_at(pos: Vector2) -> void:
	_player.position = pos
	await wait_physics_frames(3)


func _press_interact(echo: bool = false) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await wait_process_frames(2)
	var release: InputEventKey = event.duplicate() as InputEventKey
	release.pressed = false
	release.echo = false
	Input.parse_input_event(release)
	await wait_process_frames(2)


func test_press_next_to_npc_triggers_once() -> void:
	var trang: Interactable = _target("Trang")
	watch_signals(trang)
	await _stand_at(trang.position + Vector2(0, 18))
	await _press_interact()
	assert_signal_emit_count(_player, "interaction_triggered", 1)
	assert_signal_emitted_with_parameters(_player, "interaction_triggered", [trang])
	assert_signal_emit_count(trang, "interacted", 1)


func test_press_with_nothing_in_range_does_nothing() -> void:
	await _stand_at(Vector2(320, 300))
	await _press_interact()
	assert_signal_not_emitted(_player, "interaction_triggered")


func test_held_key_echo_does_not_repeat() -> void:
	var shelf: Interactable = _target("DocumentShelf")
	await _stand_at(shelf.position + Vector2(-16, 0))
	await _press_interact()
	await _press_interact(true)
	await _press_interact(true)
	assert_signal_emit_count(_player, "interaction_triggered", 1)


func test_between_linh_and_shelf_nearest_wins() -> void:
	# Linh is at x 232, the shelf at x 270. x 252 is inside both ranges, nearer the shelf.
	var linh: Interactable = _target("Linh")
	var shelf: Interactable = _target("DocumentShelf")
	await _stand_at(Vector2(252, linh.position.y))
	assert_true(_player._targets_in_range.has(linh), "Linh in range")
	assert_true(_player._targets_in_range.has(shelf), "shelf in range")
	await _press_interact()
	assert_signal_emit_count(_player, "interaction_triggered", 1)
	assert_signal_emitted_with_parameters(_player, "interaction_triggered", [shelf])


func test_every_target_is_reachable_and_interactable() -> void:
	# Approach points a real player can stand on (just outside each solid body).
	var approach: Dictionary = {
		"Linh": Vector2(232, 112),
		"DocumentShelf": Vector2(286, 92),
		"Trang": Vector2(500, 136),
		"MeetingScreen": Vector2(600, 200),
	}
	for node_name: String in approach:
		await _stand_at(approach[node_name])
		var hit: Interactable = _player.try_interact()
		assert_eq(hit, _target(node_name), "interact with %s" % node_name)
