class_name OfficeRoom
extends Node2D
## The single office room (GDD section 12). Places the player at the entrance on load and
## opens the artifact viewer from the Document Shelf (specs/artifact-viewer).

@onready var _spawn: Marker2D = $EntranceSpawn
@onready var _player: Player = $Player
@onready var _shelf: Interactable = $Interactables/DocumentShelf
@onready var _viewer: ArtifactViewer = $ArtifactViewer


func _ready() -> void:
	# The marker is the source of truth for the start position, so moving it in the
	# editor is enough to change where the run begins.
	_player.position = _spawn.position
	_shelf.interacted.connect(_open_viewer)
	_viewer.closed.connect(_on_viewer_closed)


func _open_viewer() -> void:
	_viewer.open()
	# Freeze only the player, not the tree: pausing the tree would also stop the run clock,
	# which must keep running while reading.
	_player.process_mode = Node.PROCESS_MODE_DISABLED


func _on_viewer_closed() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
