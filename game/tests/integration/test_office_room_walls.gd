extends GutTest
## specs/player-movement: walls block the player and there is no way out of the room.

const ROOM_SIZE: Vector2 = Vector2(640.0, 360.0)
const WALL: float = 16.0
const PUSH_FRAMES: int = 240  # long enough to cross the whole room at normal speed

var _room: OfficeRoom


func before_each() -> void:
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	await wait_physics_frames(2)


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)


func _player() -> Player:
	return _room.get_node("Player") as Player


func _assert_inside_room(where: String) -> void:
	var p: Vector2 = _player().position
	assert_between(p.x, WALL, ROOM_SIZE.x - WALL, "x inside room after %s" % where)
	assert_between(p.y, WALL, ROOM_SIZE.y - WALL, "y inside room after %s" % where)


func test_player_starts_at_entrance() -> void:
	var spawn: Marker2D = _room.get_node("EntranceSpawn") as Marker2D
	assert_eq(_player().position, spawn.position)


func test_pushing_into_bottom_wall_stays_inside() -> void:
	Input.action_press(&"move_down")
	await wait_physics_frames(PUSH_FRAMES)
	_assert_inside_room("pushing down")


func test_pushing_into_right_wall_stays_inside() -> void:
	Input.action_press(&"move_right")
	await wait_physics_frames(PUSH_FRAMES)
	_assert_inside_room("pushing right")
	assert_gt(_player().position.x, ROOM_SIZE.x - WALL - 20.0, "reached the right wall")


func test_slides_along_wall_when_moving_diagonally() -> void:
	Input.action_press(&"move_right")
	await wait_physics_frames(PUSH_FRAMES)
	Input.action_release(&"move_right")
	var against_wall: Vector2 = _player().position
	Input.action_press(&"move_right")
	Input.action_press(&"move_up")
	await wait_physics_frames(30)
	assert_lt(_player().position.y, against_wall.y - 10.0, "kept moving up along the wall")
	_assert_inside_room("sliding")


## Walks the inner edge clockwise from the entrance: down, left, up, right, down, left.
## Each leg pushes into a wall, so any gap in the walls would let the player escape.
func test_walk_full_perimeter_stays_inside() -> void:
	var legs: Array[Array] = [
		[&"move_down"],
		[&"move_down", &"move_left"],
		[&"move_left", &"move_up"],
		[&"move_up", &"move_right"],
		[&"move_right", &"move_down"],
		[&"move_down", &"move_left"],
	]
	for leg: Array in legs:
		for action: StringName in leg:
			Input.action_press(action)
		await wait_physics_frames(PUSH_FRAMES * 2)
		for action: StringName in leg:
			Input.action_release(action)
		_assert_inside_room("leg %s" % [leg])


## specs/player-movement "Walk into an NPC": the player stops next to Trang, not on her.
func test_npc_blocks_player() -> void:
	var trang: Interactable = _room.get_node("Interactables/Trang") as Interactable
	_player().position = trang.position + Vector2(0, 40)
	await wait_physics_frames(2)
	Input.action_press(&"move_up")
	await wait_physics_frames(PUSH_FRAMES)
	var player_top: float = _player().position.y - 10.0  # collider reaches 10 px above origin
	var trang_bottom: float = trang.position.y + trang.body_size.y / 2.0
	assert_almost_eq(player_top, trang_bottom, 1.0, "stands right below Trang")
	assert_gt(player_top, trang_bottom - 0.5, "does not overlap Trang")
