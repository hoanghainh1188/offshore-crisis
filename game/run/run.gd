class_name Run
extends Node
## Main scene. Runs one case as a sequence of screens: briefing -> office -> meeting
## (specs/run-flow). Swaps child screens instead of change_scene_to_file() so the whole
## flow also works inside GUT.

const BRIEFING_SCENE: PackedScene = preload("res://run/briefing/briefing_screen.tscn")
const OFFICE_SCENE: PackedScene = preload("res://office/office_room.tscn")
const MEETING_SCENE: PackedScene = preload("res://run/meeting/meeting_placeholder.tscn")

@export var tuning: RunTuning = preload("res://run/run_tuning.tres")
## Seed for this run's case. -1 picks a random seed; tests set a fixed one.
@export var case_seed: int = -1

## The screen currently shown; exactly one at a time.
var current_screen: Node


func _ready() -> void:
	var briefing: BriefingScreen = BRIEFING_SCENE.instantiate() as BriefingScreen
	briefing.start_pressed.connect(_on_start_pressed, CONNECT_ONE_SHOT)
	_show(briefing)


func _on_start_pressed() -> void:
	# The case exists before the office does, so the office can read it in _ready().
	GameState.start_case(next_case_seed())
	_show(OFFICE_SCENE.instantiate())
	# Connect before start(): a zero-length countdown expires inside start().
	GameState.clock.time_up.connect(_on_time_up, CONNECT_ONE_SHOT)
	GameState.clock.start(tuning.investigation_seconds)


func next_case_seed() -> int:
	if case_seed >= 0:
		return case_seed
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	# Non-negative and short enough for a playtester to read out of the log.
	return rng.randi_range(0, 999_999)


func _on_time_up() -> void:
	# Deferred: time_up fires from GameState._process; swap outside that call. Instantiate
	# inside the deferred call so nothing leaks if Run is freed first.
	_show_meeting.call_deferred()


func _show_meeting() -> void:
	_show(MEETING_SCENE.instantiate())


func _show(screen: Node) -> void:
	if current_screen != null:
		remove_child(current_screen)
		current_screen.queue_free()
	current_screen = screen
	add_child(screen)
