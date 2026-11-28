extends GutTest
## Clue board in a real run (specs/clue-board): only during the investigation, the clock
## keeps going, and time up still ends the investigation.

var _run: Run


func _make_run(seconds: float) -> void:
	GameState.reset_run()
	_run = (load("res://run/run.tscn") as PackedScene).instantiate() as Run
	var tuning: RunTuning = RunTuning.new()
	tuning.investigation_seconds = seconds
	_run.tuning = tuning
	_run.case_seed = 42
	add_child_autofree(_run)
	await wait_process_frames(2)


func _start(seconds: float) -> void:
	await _make_run(seconds)
	((_run.current_screen as BriefingScreen).get_node("%StartButton") as Button).pressed.emit()
	await wait_process_frames(2)


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


func _board() -> ClueBoard:
	return _run.find_child("ClueBoard", true, false) as ClueBoard


func after_each() -> void:
	GameState.reset_run()


func test_board_key_on_briefing_opens_nothing() -> void:
	await _make_run(60.0)
	await _press(KEY_C)
	assert_true(_run.current_screen is BriefingScreen)
	assert_null(_board())


func test_clock_keeps_running_with_board_open() -> void:
	await _start(60.0)
	await _press(KEY_C)
	assert_true(_board().is_open())
	var before: float = GameState.clock.remaining_seconds
	var started_ms: int = Time.get_ticks_msec()
	await wait_seconds(1.0)
	var elapsed: float = (Time.get_ticks_msec() - started_ms) / 1000.0
	assert_true(GameState.clock.is_running())
	assert_almost_eq(before - GameState.clock.remaining_seconds, elapsed, 0.25)


func test_time_up_with_board_open_shows_meeting() -> void:
	await _start(0.5)
	await _press(KEY_C)
	await wait_until(func() -> bool: return _run.current_screen.name == &"MeetingPlaceholder", 3.0)
	assert_eq(_run.current_screen.name, &"MeetingPlaceholder")
	assert_null(_board(), "board is gone")
