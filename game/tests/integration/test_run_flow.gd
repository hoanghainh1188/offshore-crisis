extends GutTest
## Briefing -> office -> meeting flow of one run (specs/run-flow, specs/player-movement).

const SHORT_RUN: float = 0.5

var _run: Run


func before_each() -> void:
	GameState.reset_run()
	_run = (load("res://run/run.tscn") as PackedScene).instantiate() as Run
	var tuning: RunTuning = RunTuning.new()
	tuning.investigation_seconds = SHORT_RUN
	_run.tuning = tuning
	add_child_autofree(_run)
	await wait_process_frames(2)


func after_each() -> void:
	Input.action_release(&"move_right")
	GameState.reset_run()


func _screen() -> Node:
	return _run.current_screen


func _press_start() -> void:
	((_screen() as BriefingScreen).get_node("%StartButton") as Button).pressed.emit()
	await wait_process_frames(2)


## Polls instead of a fixed wait so a slow first frame cannot make the test flaky.
func _wait_for_meeting() -> void:
	await wait_until(func() -> bool: return _screen().name == &"MeetingPlaceholder", 3.0)


func test_meeting_placeholder_text() -> void:
	var meeting: Control = (load("res://run/meeting/meeting_placeholder.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(meeting)
	assert_eq((meeting.get_node("%TimeLabel") as Label).text, "17:00")
	assert_eq((meeting.get_node("%MessageLabel") as Label).text, "The meeting with the client has started.")


func test_opens_on_briefing_with_no_player() -> void:
	assert_is(_screen(), BriefingScreen)
	assert_null(_run.find_child("Player", true, false), "no player on the briefing")
	assert_false(GameState.clock.is_started())


func test_clock_stays_stopped_on_briefing() -> void:
	await wait_seconds(SHORT_RUN + 0.2)
	assert_is(_screen(), BriefingScreen)
	assert_false(GameState.clock.is_started())
	assert_eq(GameState.clock.office_minutes(), RunClock.START_MINUTES)


func test_start_shows_office_with_player_at_entrance_and_clock_running() -> void:
	# No frame wait: with a 0.5 s run each frame is ~20 in-game minutes.
	((_screen() as BriefingScreen).get_node("%StartButton") as Button).pressed.emit()
	assert_is(_screen(), OfficeRoom)
	var room: OfficeRoom = _screen() as OfficeRoom
	var player: Player = room.get_node("Player") as Player
	var spawn: Marker2D = room.get_node("EntranceSpawn") as Marker2D
	assert_eq(player.position, spawn.position)
	assert_true(GameState.clock.is_running())
	assert_eq(RunClock.format_office_time(GameState.clock.office_minutes()), "09:00")
	assert_null(_run.find_child("BriefingScreen", true, false), "briefing is gone")


func test_time_up_shows_meeting_and_stops_clock() -> void:
	watch_signals(GameState.clock)
	await _press_start()
	await _wait_for_meeting()
	assert_eq(_screen().name, &"MeetingPlaceholder")
	assert_null(_run.find_child("OfficeRoom", true, false), "office is gone")
	assert_false(GameState.clock.is_running())
	await wait_seconds(0.2)
	assert_signal_emit_count(GameState.clock, "time_up", 1)


func test_holding_movement_through_time_up() -> void:
	await _press_start()
	Input.action_press(&"move_right")
	await _wait_for_meeting()
	assert_eq(_screen().name, &"MeetingPlaceholder")
	assert_null(_run.find_child("Player", true, false), "no player on the meeting screen")
