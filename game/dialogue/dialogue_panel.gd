class_name DialoguePanel
extends CanvasLayer
## Question-and-answer panel for an NPC (specs/npc-dialogue). Layer 5 like the artifact
## viewer, under the office clock (layer 10): the clock keeps running while talking.

## Emitted when the panel closes (Close button or Esc).
signal closed

const DIALOGUE_PATH: String = "res://dialogue/dialogue_offline.json"
const ASKED_MARK: String = "✓ "

var _data: DialogueData
var _npc_id: StringName = &""
var _buttons: Dictionary[StringName, Button] = {}

@onready var _name_label: Label = %NpcName
@onready var _role_label: Label = %NpcRole
@onready var _list: VBoxContainer = %QuestionList
@onready var _answer_label: Label = %Answer
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_data = DialogueData.load_from(DIALOGUE_PATH, GameState.case_template())
	_close_button.pressed.connect(close)
	GameState.fact_revealed.connect(_on_fact_revealed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func has_dialogue(npc_id: StringName) -> bool:
	return _data != null and _data.has_npc(npc_id)


func open(npc_id: StringName) -> void:
	_npc_id = npc_id
	var npc: CaseTemplate.Npc = _find_npc(npc_id)
	_name_label.text = npc.display_name if npc != null else String(npc_id)
	_role_label.text = npc.role if npc != null else ""
	_answer_label.text = "Pick a question on the left."
	visible = true
	_rebuild_list()
	if not _buttons.is_empty():
		_buttons.values()[0].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func header_name() -> String:
	return _name_label.text


func header_role() -> String:
	return _role_label.text


func listed_question_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_buttons.keys())
	return ids


func question_button(question_id: StringName) -> Button:
	return _buttons.get(question_id)


func shown_answer() -> String:
	return _answer_label.text


func close_button() -> Button:
	return _close_button


func _rebuild_list() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_buttons.clear()
	if not has_dialogue(_npc_id):
		return
	for question: DialogueData.Question in DialogueRules.visible_questions(
			_data.questions_for(_npc_id), GameState.revealed_fact_ids):
		var button: Button = Button.new()
		button.name = String(question.id)
		button.text = (ASKED_MARK if GameState.is_asked(question.id) else "") + question.text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_ask.bind(question))
		_list.add_child(button)
		_buttons[question.id] = button


func _ask(question: DialogueData.Question) -> void:
	var answer: DialogueAnswer = GameState.ask_question(_npc_id, question)
	_answer_label.text = answer.text
	# The reveal may have rebuilt the list, so look the button up again and keep keyboard
	# focus on the question just asked.
	var button: Button = _buttons.get(question.id)
	if button == null:
		return
	if not button.text.begins_with(ASKED_MARK):
		button.text = ASKED_MARK + button.text
	button.grab_focus()


## A reveal can unlock a follow-up; refresh so it appears without reopening the panel.
func _on_fact_revealed(_fact_id: StringName) -> void:
	if not visible:
		return
	var focused: Control = get_viewport().gui_get_focus_owner()
	var focused_id: StringName = StringName(focused.name) if focused != null else &""
	_rebuild_list()
	if _buttons.has(focused_id):
		_buttons[focused_id].grab_focus()


func _find_npc(npc_id: StringName) -> CaseTemplate.Npc:
	var template: CaseTemplate = GameState.case_template()
	if template == null:
		return null
	for npc: CaseTemplate.Npc in template.npcs:
		if npc.id == npc_id:
			return npc
	return null
