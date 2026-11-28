extends GutTest
## Clock rules from specs/run-clock, driven with explicit time steps.

const TOTAL: float = 900.0

var _clock: RunClock


func before_each() -> void:
	_clock = RunClock.new()
	watch_signals(_clock)


func test_tuning_resource_defaults_to_fifteen_minutes() -> void:
	var tuning: RunTuning = load("res://run/run_tuning.tres") as RunTuning
	assert_not_null(tuning)
	assert_eq(tuning.investigation_seconds, 900.0)


# --- start / tick ---

func test_not_running_before_start() -> void:
	_clock.tick(30.0)
	assert_false(_clock.is_running())
	assert_false(_clock.is_started())
	assert_eq(_clock.office_minutes(), RunClock.START_MINUTES)


func test_start_sets_full_time_and_runs() -> void:
	_clock.start(TOTAL)
	assert_true(_clock.is_running())
	assert_eq(_clock.remaining_seconds, TOTAL)


func test_ten_seconds_remove_ten_seconds() -> void:
	_clock.start(TOTAL)
	_clock.tick(10.0)
	assert_almost_eq(_clock.remaining_seconds, TOTAL - 10.0, 0.0001)


func test_overshoot_ends_at_exactly_zero() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL + 50.0)
	assert_eq(_clock.remaining_seconds, 0.0)


func test_time_up_emitted_once() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL)
	_clock.tick(10.0)
	_clock.tick(10.0)
	assert_signal_emit_count(_clock, "time_up", 1)
	assert_eq(_clock.remaining_seconds, 0.0)
	assert_false(_clock.is_running())
	assert_true(_clock.is_expired())


func test_start_is_ignored_after_first_start() -> void:
	_clock.start(TOTAL)
	_clock.tick(100.0)
	_clock.start(TOTAL)
	assert_almost_eq(_clock.remaining_seconds, TOTAL - 100.0, 0.0001)


func test_tuned_sixty_second_countdown() -> void:
	_clock.start(60.0)
	_clock.tick(59.0)
	assert_signal_emit_count(_clock, "time_up", 0)
	_clock.tick(1.0)
	assert_signal_emit_count(_clock, "time_up", 1)


# --- pause reasons ---

func test_pause_stops_time() -> void:
	_clock.start(TOTAL)
	_clock.pause(&"ai_reply")
	_clock.tick(10.0)
	assert_eq(_clock.remaining_seconds, TOTAL)
	assert_eq(_clock.office_minutes(), RunClock.START_MINUTES)
	assert_false(_clock.is_running())


func test_resume_continues_from_paused_time() -> void:
	_clock.start(TOTAL)
	_clock.tick(5.0)
	_clock.pause(&"ai_reply")
	_clock.tick(10.0)
	_clock.resume(&"ai_reply")
	_clock.tick(1.0)
	assert_almost_eq(_clock.remaining_seconds, TOTAL - 6.0, 0.0001)


func test_two_reasons_need_two_resumes() -> void:
	_clock.start(TOTAL)
	_clock.pause(&"a")
	_clock.pause(&"b")
	_clock.resume(&"a")
	_clock.tick(10.0)
	assert_eq(_clock.remaining_seconds, TOTAL)
	_clock.resume(&"b")
	_clock.tick(10.0)
	assert_almost_eq(_clock.remaining_seconds, TOTAL - 10.0, 0.0001)


func test_same_reason_twice_counts_once() -> void:
	_clock.start(TOTAL)
	_clock.pause(&"a")
	_clock.pause(&"a")
	_clock.resume(&"a")
	assert_true(_clock.is_running())


func test_unknown_resume_changes_nothing() -> void:
	_clock.start(TOTAL)
	_clock.pause(&"a")
	_clock.resume(&"other")
	assert_false(_clock.is_running())
	_clock.resume(&"a")
	_clock.resume(&"other")
	assert_true(_clock.is_running())


func test_pause_before_start_holds_after_start() -> void:
	_clock.pause(&"a")
	_clock.start(TOTAL)
	_clock.tick(10.0)
	assert_eq(_clock.remaining_seconds, TOTAL)


func test_paused_with_under_one_second_left() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL - 0.5)
	_clock.pause(&"a")
	_clock.tick(10.0)
	assert_signal_emit_count(_clock, "time_up", 0)
	_clock.resume(&"a")
	_clock.tick(0.5)
	assert_signal_emit_count(_clock, "time_up", 1)


func test_pause_and_resume_after_time_up_do_nothing() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL)
	_clock.pause(&"a")
	_clock.resume(&"a")
	_clock.tick(10.0)
	assert_signal_emit_count(_clock, "time_up", 1)
	assert_eq(_clock.remaining_seconds, 0.0)
	assert_false(_clock.is_running())


# --- office time ---

func test_office_time_at_start() -> void:
	_clock.start(TOTAL)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "09:00")


func test_office_time_at_half() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL / 2.0)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "13:00")


func test_office_time_rounds_down() -> void:
	_clock.start(TOTAL)
	_clock.tick(100.0)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "09:53")


func test_office_time_at_zero() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "17:00")


func test_office_time_with_tuned_countdown() -> void:
	_clock.start(60.0)
	_clock.tick(30.0)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "13:00")


func test_format_pads_hours_and_minutes() -> void:
	assert_eq(RunClock.format_office_time(9 * 60 + 5), "09:05")
	assert_eq(RunClock.format_office_time(17 * 60), "17:00")


# --- advance by in-game minutes ---

func test_advance_fifteen_minutes_on_default_run() -> void:
	_clock.start(TOTAL)
	_clock.advance_minutes(15)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "09:15")
	assert_almost_eq(TOTAL - _clock.remaining_seconds, 28.125, 0.0001)


func test_advance_while_paused_keeps_the_pause() -> void:
	_clock.start(TOTAL)
	_clock.pause(&"ai_reply")
	_clock.advance_minutes(15)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "09:15")
	assert_false(_clock.is_running())


func test_advance_past_five_pm_ends_the_day_once() -> void:
	_clock.start(TOTAL)
	_clock.advance_minutes(470)  # 16:50
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "16:50")
	_clock.advance_minutes(15)
	assert_eq(RunClock.format_office_time(_clock.office_minutes()), "17:00")
	assert_eq(_clock.remaining_seconds, 0.0)
	_clock.advance_minutes(15)
	assert_signal_emit_count(_clock, "time_up", 1)


func test_advance_before_start_does_nothing() -> void:
	_clock.advance_minutes(15)
	assert_false(_clock.is_started())
	assert_eq(_clock.office_minutes(), RunClock.START_MINUTES)


func test_advance_after_time_up_does_nothing() -> void:
	_clock.start(TOTAL)
	_clock.tick(TOTAL)
	_clock.advance_minutes(15)
	assert_signal_emit_count(_clock, "time_up", 1)
	assert_eq(_clock.remaining_seconds, 0.0)
