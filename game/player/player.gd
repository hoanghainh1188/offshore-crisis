class_name Player
extends CharacterBody2D
## Top-down office walker controlled by the move_* input actions. Also decides which
## nearby Interactable receives the interact key.

## Emitted once per successful interaction, after the target has handled it.
signal interaction_triggered(target: Interactable)

@export var tuning: PlayerTuning = preload("res://player/player_tuning.tres")

## Targets whose InteractionArea overlaps the sensor, kept in entry order because the
## nearest-target tie-break depends on it.
var _targets_in_range: Array[Interactable] = []

@onready var _sensor: Area2D = $InteractionSensor


func _ready() -> void:
	_sensor.area_entered.connect(_on_sensor_area_entered)
	_sensor.area_exited.connect(_on_sensor_area_exited)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = compute_velocity(direction, tuning.move_speed)
	# move_and_slide() also gives the "slide along walls" behavior the spec asks for.
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# allow_echo = false: holding the key must not repeat the interaction.
	if event.is_action_pressed(&"interact", false):
		try_interact()
		get_viewport().set_input_as_handled()


## Interacts with the nearest target in range. Returns it, or null if none is in range.
func try_interact() -> Interactable:
	var target: Interactable = InteractionTargetPicker.pick_nearest(global_position, _targets_in_range)
	if target == null:
		return null
	target.interact()
	interaction_triggered.emit(target)
	return target


## Pure so it can be unit-tested. Capping the length keeps diagonals at full speed,
## not faster, and keeps analog input proportional later.
static func compute_velocity(direction: Vector2, speed: float) -> Vector2:
	return direction.limit_length(1.0) * speed


func _on_sensor_area_entered(area: Area2D) -> void:
	var target: Interactable = area.get_parent() as Interactable
	if target != null and not _targets_in_range.has(target):
		_targets_in_range.append(target)


func _on_sensor_area_exited(area: Area2D) -> void:
	var target: Interactable = area.get_parent() as Interactable
	if target != null:
		_targets_in_range.erase(target)
