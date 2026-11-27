class_name OfficeClock
extends CanvasLayer
## Wall-clock HUD for the office: shows the run clock as HH:MM (specs/run-clock).

@onready var _time_label: Label = %TimeLabel


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	# Read the clock each frame instead of caching it: GameState.reset_run() swaps it.
	_time_label.text = RunClock.format_office_time(GameState.clock.office_minutes())
