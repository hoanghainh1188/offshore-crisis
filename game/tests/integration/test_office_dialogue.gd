extends GutTest
## Talking to NPCs in the real office room (specs/npc-dialogue).

var _room: OfficeRoom
var _player: Player
var _panel: DialoguePanel


func before_each() -> void:
	GameState.reset_run()
	GameState.start_case(42)
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	_player = _room.get_node("Player") as Player
	_panel = _room.get_node("DialoguePanel") as DialoguePanel
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


func test_linh_opens_the_dialogue_and_still_logs() -> void:
	watch_signals(_target("Linh"))
	await _stand_at(Vector2(232, 112))
	await _press(KEY_E)
	assert_true(_panel.is_open())
	assert_eq(_panel.header_name(), "Linh")
	assert_signal_emit_count(_target("Linh"), "interacted", 1)


func test_trang_opens_her_dialogue() -> void:
	await _stand_at(Vector2(500, 136))
	await _press(KEY_E)
	assert_true(_panel.is_open())
	assert_eq(_panel.header_name(), "Trang")


func test_minh_opens_his_dialogue_and_logs() -> void:
	watch_signals(_target("Minh"))
	await _stand_at(Vector2(150, 296))
	await _press(KEY_E)
	assert_true(_panel.is_open())
	assert_eq(_panel.header_name(), "Minh")
	assert_eq(_panel.header_role(), "Junior dev")
	assert_signal_emit_count(_target("Minh"), "interacted", 1)


func test_hana_opens_her_dialogue_and_logs() -> void:
	watch_signals(_target("Hana"))
	await _stand_at(Vector2(422, 308))
	await _press(KEY_E)
	assert_true(_panel.is_open())
	assert_eq(_panel.header_name(), "Hana")
	assert_eq(_panel.header_role(), "Comtor (interpreter)")
	assert_signal_emit_count(_target("Hana"), "interacted", 1)


func test_meeting_screen_opens_tanaka_dialogue_and_fits_640x360() -> void:
	watch_signals(_target("MeetingScreen"))
	await _stand_at(Vector2(600, 200))
	await _press(KEY_E)
	assert_true(_panel.is_open())
	assert_eq(_panel.header_name(), "Tanaka-san")
	assert_eq(_panel.header_role(), "Client PM, Kazegumo Logistics")
	assert_signal_emit_count(_target("MeetingScreen"), "interacted", 1)
	var role_label: Label = _panel.get_node("%NpcRole") as Label
	var panel_node: Control = _panel.get_node("Panel") as Control
	assert_lte(role_label.get_rect().end.x, panel_node.size.x,
		"Tanaka-san role fits within 640x360 dialogue panel")


func test_shelf_opens_the_viewer_not_the_dialogue() -> void:
	await _stand_at(_target("DocumentShelf").position + Vector2(16, 0))
	await _press(KEY_E)
	assert_false(_panel.is_open())
	assert_true((_room.get_node("ArtifactViewer") as ArtifactViewer).is_open())


func test_player_is_frozen_while_talking_and_walks_after_esc() -> void:
	await _stand_at(Vector2(232, 112))
	await _press(KEY_E)
	var start: Vector2 = _player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	assert_eq(_player.position, start, "frozen while talking")
	Input.action_release(&"move_right")
	await _press(KEY_ESCAPE)
	assert_false(_panel.is_open())
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, start.x, "walks after Esc")
