extends GutTest
## The office clock HUD in the room shows GameState's clock as HH:MM (specs/run-clock).

var _room: OfficeRoom


func before_each() -> void:
	GameState.reset_run()
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	await wait_process_frames(2)


func after_each() -> void:
	GameState.reset_run()


func _clock_text() -> String:
	return (_room.get_node("OfficeClock/%TimeLabel") as Label).text


func test_shows_nine_before_start() -> void:
	assert_eq(_clock_text(), "09:00")


func test_shows_thirteen_at_half() -> void:
	GameState.clock.start(900.0)
	GameState.clock.tick(450.0)
	GameState.clock.pause(&"test")  # Keep real frames from moving the clock.
	await wait_process_frames(2)
	assert_eq(_clock_text(), "13:00")


func test_shows_seventeen_at_zero() -> void:
	GameState.clock.start(900.0)
	GameState.clock.tick(900.0)
	await wait_process_frames(2)
	assert_eq(_clock_text(), "17:00")
