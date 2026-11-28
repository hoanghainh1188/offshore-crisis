class_name ArtifactViewer
extends CanvasLayer
## Reading screen for the Document Shelf (specs/artifact-viewer). Sits on layer 5, under
## the office clock (layer 10), so the time stays visible: the clock keeps running here.

## Emitted when the viewer closes (Close button or Esc).
signal closed

const FILLER_PATH: String = "res://artifacts/artifact_filler.json"

## Where the filler data comes from; tests point it at a missing file.
var filler_path: String = FILLER_PATH

var _filler: ArtifactFiller
var _buttons: Dictionary[StringName, Button] = {}
var _shown: ArtifactDocument = null

@onready var _list: VBoxContainer = %DocumentList
@onready var _title_label: Label = %DocTitle
@onready var _body_label: Label = %DocBody
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_filler = ArtifactFiller.load_from(filler_path)
	for type: StringName in ArtifactDocument.TYPES:
		var button: Button = Button.new()
		button.name = String(type)
		button.text = ArtifactDocument.display_name(type)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_show_document.bind(type))
		_list.add_child(button)
		_buttons[type] = button
	_close_button.pressed.connect(close)
	if _filler == null:
		# Without filler data no document can be built; say so instead of failing on click.
		for button: Button in _buttons.values():
			button.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_shown = null
	_title_label.text = "Document Shelf"
	_body_label.text = "Pick a document on the left." if _filler != null \
		else "Documents could not be loaded."
	_buttons[ArtifactDocument.TYPES[0]].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func listed_titles() -> Array[String]:
	var titles: Array[String] = []
	for type: StringName in ArtifactDocument.TYPES:
		titles.append(_buttons[type].text)
	return titles


func document_button(type: StringName) -> Button:
	return _buttons[type]


func close_button() -> Button:
	return _close_button


func shown_title() -> String:
	return _shown.title if _shown != null else ""


func shown_lines() -> Array[String]:
	return _shown.lines if _shown != null else ([] as Array[String])


func _show_document(type: StringName) -> void:
	if _filler == null:
		return
	# Without a case (e.g. the office opened alone in a test) a document is filler only.
	var sheet: TruthSheet = GameState.truth_sheet if GameState.truth_sheet != null else TruthSheet.new()
	_shown = ArtifactDocument.build(sheet, type, _filler)
	_title_label.text = _shown.title
	_body_label.text = "\n\n".join(_shown.lines)
	for fact_id: StringName in _shown.fact_ids:
		GameState.reveal_fact(fact_id)
