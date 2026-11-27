class_name PlayerTuning
extends Resource
## Movement numbers for the player. These are balance values: tune them through
## playtests and log changes in playtest/tuning-log.md, not in code.

## Walking speed in pixels per second (viewport is 640x360).
@export var move_speed: float = 110.0
