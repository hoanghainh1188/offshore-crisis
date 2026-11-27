class_name Interactable
extends StaticBody2D
## An NPC or object the player can interact with. Solid, so the player stands next to
## it. Its InteractionArea (body + margin) defines the interaction range.
## Later features (dialogue, artifacts) connect to `interacted` instead of editing this.

signal interacted

enum Kind { NPC, OBJECT }

const LABEL_WIDTH: float = 100.0

@export var kind: Kind = Kind.OBJECT
@export var id: StringName = &""
@export var display_name: String = ""
## Size of the solid body. Each instance builds its own shapes from this, so
## instances never share (and accidentally resize) one shape resource.
@export var body_size: Vector2 = Vector2(12.0, 16.0)
@export var color: Color = Color(0.85, 0.45, 0.3)
## Nudges the name label, e.g. away from a wall where it would be cut off.
@export var label_offset: Vector2 = Vector2.ZERO
@export var tuning: InteractionTuning = preload("res://interaction/interaction_tuning.tres")

@onready var _body_shape: CollisionShape2D = $BodyShape
@onready var _area_shape: CollisionShape2D = $InteractionArea/AreaShape
@onready var _visual: Polygon2D = $Visual
@onready var _label: Label = $NameLabel


func _ready() -> void:
	_body_shape.shape = _make_rect(body_size)
	_area_shape.shape = _make_rect(body_size + Vector2.ONE * tuning.interaction_margin * 2.0)
	var half: Vector2 = body_size / 2.0
	_visual.polygon = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	_visual.color = color
	_label.text = display_name
	# Fixed-width, centered label so long names stay centered over the target.
	_label.size = Vector2(LABEL_WIDTH, 12.0)
	_label.position = Vector2(-LABEL_WIDTH / 2.0, -half.y - 12.0) + label_offset


func kind_name() -> String:
	return "npc" if kind == Kind.NPC else "object"


## Logs the interaction and notifies listeners. Called once per key press.
func interact() -> void:
	print(InteractionLog.format(kind_name(), id, display_name))
	interacted.emit()


static func _make_rect(size: Vector2) -> RectangleShape2D:
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	return rect
