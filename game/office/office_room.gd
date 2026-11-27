class_name OfficeRoom
extends Node2D
## The single office room (GDD section 12). Places the player at the entrance on load.

@onready var _spawn: Marker2D = $EntranceSpawn
@onready var _player: Player = $Player


func _ready() -> void:
	# The marker is the source of truth for the start position, so moving it in the
	# editor is enough to change where the run begins.
	_player.position = _spawn.position
