class_name RunClock
extends RefCounted
## Investigation countdown (specs/run-clock). Pure logic: the owner calls tick(delta),
## so tests can drive time without waiting.

## Emitted once, when the remaining time reaches zero.
signal time_up

## Office time when the countdown is full (09:00) and when it reaches zero (17:00).
## Fixed by the spec, not balance values.
const START_MINUTES: int = 9 * 60
const END_MINUTES: int = 17 * 60

var remaining_seconds: float = 0.0
var total_seconds: float = 0.0

var _started: bool = false
var _expired: bool = false
## Used as a set: the same reason twice must count once.
var _pause_reasons: Dictionary[StringName, bool] = {}


## Starts the countdown. Only the first call counts: Start happens once per run.
func start(seconds: float) -> void:
	if _started:
		return
	_started = true
	total_seconds = maxf(seconds, 0.0)
	remaining_seconds = total_seconds
	if total_seconds == 0.0:
		_expire()


func tick(delta: float) -> void:
	if not is_running():
		return
	remaining_seconds = maxf(remaining_seconds - delta, 0.0)
	if remaining_seconds == 0.0:
		_expire()


func pause(reason: StringName) -> void:
	if _expired:
		return
	_pause_reasons[reason] = true


func resume(reason: StringName) -> void:
	_pause_reasons.erase(reason)


func is_started() -> bool:
	return _started


func is_expired() -> bool:
	return _expired


func is_running() -> bool:
	return _started and not _expired and _pause_reasons.is_empty()


## Office time in minutes after midnight, rounded down to the whole in-game minute.
func office_minutes() -> int:
	if not _started or total_seconds <= 0.0:
		return END_MINUTES if _expired else START_MINUTES
	var span: int = END_MINUTES - START_MINUTES
	var elapsed_ratio: float = (total_seconds - remaining_seconds) / total_seconds
	# Small epsilon so float error (e.g. 449.99999 for 450) never drops a whole minute.
	return START_MINUTES + mini(int(floor(span * elapsed_ratio + 0.0001)), span)


@warning_ignore("integer_division")
static func format_office_time(minutes: int) -> String:
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func _expire() -> void:
	_expired = true
	_pause_reasons.clear()
	time_up.emit()
