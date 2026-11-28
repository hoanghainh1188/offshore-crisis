extends GutTest
## Reading in a real run: the clock keeps going and time up still ends the investigation
## (specs/artifact-viewer "Reading does not stop the clock or the run").

var _run: Run


func _start_run(seconds: float) -> void:
	GameState.reset_run()
	_run = (load("res://run/run.tscn") as PackedScene).instantiate() as Run
	var tuning: RunTuning = RunTuning.new()
	tuning.investigation_seconds = seconds
	_run.tuning = tuning
	_run.case_seed = 42
	add_child_autofree(_run)
	await wait_process_frames(2)
	((_run.current_screen as BriefingScreen).get_node("%StartButton") as Button).pressed.emit()
	await wait_process_frames(2)


func _open_viewer() -> ArtifactViewer:
	var viewer: ArtifactViewer = (_run.current_screen as OfficeRoom).get_node("ArtifactViewer") as ArtifactViewer
	(_run.current_screen as OfficeRoom)._open_viewer("Document Shelf")
	return viewer


func after_each() -> void:
	GameState.reset_run()


func test_clock_keeps_running_while_reading() -> void:
	await _start_run(60.0)
	var viewer: ArtifactViewer = _open_viewer()
	var before: float = GameState.clock.remaining_seconds
	var started_ms: int = Time.get_ticks_msec()
	await wait_seconds(1.0)
	var elapsed: float = (Time.get_ticks_msec() - started_ms) / 1000.0
	assert_true(viewer.is_open())
	assert_true(GameState.clock.is_running())
	# The clock lost about the wall time that passed; loose bound so a slow frame on a busy
	# machine does not make the test flaky.
	assert_almost_eq(before - GameState.clock.remaining_seconds, elapsed, 0.25)


func test_time_up_while_reading_shows_the_meeting() -> void:
	await _start_run(0.5)
	_open_viewer()
	await wait_until(func() -> bool: return _run.current_screen.name == &"MeetingPlaceholder", 3.0)
	assert_eq(_run.current_screen.name, &"MeetingPlaceholder")
	assert_null(_run.find_child("ArtifactViewer", true, false), "viewer is gone")
