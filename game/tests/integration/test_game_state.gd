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


func test_new_run_clears_the_clue_board() -> void:
	GameState.start_case(42)
	var ids: Array[StringName] = []
	for fact: CaseTemplate.Fact in GameState.truth_sheet.chain:
		GameState.reveal_fact(fact.id)
		ids.append(fact.id)
	GameState.clue_board.pin(ids[0], Vector2(5, 5), GameState.revealed_fact_ids)
	GameState.clue_board.pin(ids[1], Vector2(50, 5), GameState.revealed_fact_ids)
	GameState.clue_board.select(ids[0])
	GameState.clue_board.select(ids[1])
	GameState.start_case(43)
	assert_eq(GameState.clue_board.pinned_ids().size(), 0)
	assert_eq(GameState.clue_board.links().size(), 0)
	assert_eq(GameState.clue_board.tray_ids(GameState.revealed_fact_ids).size(), 0)
	GameState.clue_board.pin(ids[0], Vector2.ZERO, ids)
	GameState.reset_run()
	assert_eq(GameState.clue_board.pinned_ids().size(), 0)
