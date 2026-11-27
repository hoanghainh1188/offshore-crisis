extends GutTest
## Drives the real player scene with simulated input actions.

var _player: Player


func before_each() -> void:
	_player = (load("res://player/player.tscn") as PackedScene).instantiate() as Player
	add_child_autofree(_player)


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)


func test_holding_right_moves_right() -> void:
	var start: Vector2 = _player.position
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, start.x)
	assert_almost_eq(_player.position.y, start.y, 0.01)


func test_release_stops_on_next_frame() -> void:
	Input.action_press(&"move_right")
	await wait_physics_frames(5)
	Input.action_release(&"move_right")
	await wait_physics_frames(2)
	var stopped_at: Vector2 = _player.position
	await wait_physics_frames(5)
	assert_eq(_player.position, stopped_at)
	assert_eq(_player.velocity, Vector2.ZERO)
