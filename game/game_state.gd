extends Node
## Autoload "GameState": per-run state that must outlive screen swaps and be reachable
## from any system. Pause the clock with GameState.clock.pause(&"reason").

var clock: RunClock = RunClock.new()


func _process(delta: float) -> void:
	clock.tick(delta)


## Starts a fresh run state. Tests call this so runs do not leak into each other.
func reset_run() -> void:
	clock = RunClock.new()
