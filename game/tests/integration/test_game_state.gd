extends GutTest
## The GameState Autoload ticks the run clock with real frame time (specs/run-clock).


func before_each() -> void:
	GameState.reset_run()


func after_each() -> void:
	GameState.reset_run()


func test_autoload_ticks_clock_until_time_up() -> void:
	watch_signals(GameState.clock)
	GameState.clock.start(0.3)
	await wait_seconds(0.5)
	assert_signal_emit_count(GameState.clock, "time_up", 1)
	assert_eq(GameState.clock.remaining_seconds, 0.0)


func test_clock_does_not_run_before_start() -> void:
	await wait_process_frames(5)
	assert_false(GameState.clock.is_started())
	assert_eq(GameState.clock.office_minutes(), RunClock.START_MINUTES)


func test_reset_run_gives_fresh_clock() -> void:
	GameState.clock.start(10.0)
	GameState.reset_run()
	assert_false(GameState.clock.is_started())
