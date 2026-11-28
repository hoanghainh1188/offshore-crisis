class_name OfficeRoom
extends Node2D
## The single office room (GDD section 12). Places the player at the entrance on load and
## opens panels from targets: the Document Shelf and the PC Terminal open the artifact
## viewer (specs/artifact-viewer), NPCs with dialogue open the dialogue panel (specs/npc-dialogue).
## The clue board opens with its own key, also over an open panel (specs/clue-board).

@onready var _spawn: Marker2D = $EntranceSpawn
@onready var _player: Player = $Player
@onready var _shelf: Interactable = $Interactables/DocumentShelf
@onready var _terminal: Interactable = $Interactables/PcTerminal
@onready var _meeting_screen: Interactable = $Interactables/MeetingScreen
@onready var _viewer: ArtifactViewer = $ArtifactViewer
@onready var _dialogue: DialoguePanel = $DialoguePanel
@onready var _board: ClueBoard = $ClueBoard


func _ready() -> void:
	# The marker is the source of truth for the start position, so moving it in the
	# editor is enough to change where the run begins.
	_player.position = _spawn.position
	_shelf.interacted.connect(_open_viewer.bind(_shelf.display_name))
	_terminal.interacted.connect(_open_viewer.bind(_terminal.display_name))
	if _dialogue.has_dialogue(&"tanaka"):
		_meeting_screen.interacted.connect(_open_dialogue.bind(&"tanaka"))
	_viewer.closed.connect(_unfreeze_player)
	_dialogue.closed.connect(_unfreeze_player)
	_board.opened.connect(_freeze_player)
	_board.closed.connect(_unfreeze_player)
	for node: Node in $Interactables.get_children():
		var target: Interactable = node as Interactable
		if target != null and target.kind == Interactable.Kind.NPC and _dialogue.has_dialogue(target.id):
			target.interacted.connect(_open_dialogue.bind(target.id))


func _open_viewer(source_name: String) -> void:
	_viewer.open(source_name)
	_freeze_player()


func _open_dialogue(npc_id: StringName) -> void:
	_dialogue.open(npc_id)
	_freeze_player()


## One path for every panel. Freeze only the player, not the tree: pausing the tree would
## also stop the run clock, which keeps running while reading or talking.
func _freeze_player() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED


## The board can sit over a panel, so closing one of them must not free the player while
## the other is still open.
func _unfreeze_player() -> void:
	if _viewer.is_open() or _dialogue.is_open() or _board.is_open():
		return
	_player.process_mode = Node.PROCESS_MODE_INHERIT
