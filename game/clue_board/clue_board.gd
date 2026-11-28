class_name ClueBoard
extends CanvasLayer
## Clue board (specs/clue-board). Layer 6: above the artifact viewer and dialogue panel (5)
## so it can open over them, under the office clock (10) so time stays visible. Keep this
## node after the panels in the office scene: Godot sends unhandled input to later siblings
## first, so one Esc closes only the board and not the panel under it.
## Rules live in GameState.clue_board; this node draws them and forwards input.

signal opened
signal closed

const EMPTY_TEXT: String = "No clues found yet."
## Grid used to place a freshly pinned card; the player drags it from there.
const PIN_STEP: Vector2 = Vector2(136, 72)
const PIN_MARGIN: Vector2 = Vector2(6, 6)

var _tray_cards: Dictionary[StringName, ClueCardView] = {}
var _pinned_cards: Dictionary[StringName, ClueCardView] = {}
var _return_focus: Control = null

@onready var _tray_list: VBoxContainer = %TrayList
@onready var _empty_label: Label = %EmptyLabel
@onready var _count_label: Label = %CountLabel
@onready var _area: ClueBoardArea = %BoardArea
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)
	GameState.fact_revealed.connect(_on_fact_revealed)
	_area.resized.connect(_refresh_links)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"clue_board"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if visible:
		return
	_return_focus = get_viewport().gui_get_focus_owner()
	visible = true
	_rebuild()
	_close_button.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	_state().selected = &""
	# Give focus back so Enter cannot press a hidden control, and keyboard use of an open
	# viewer or dialogue panel continues where it was.
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	_return_focus = null
	closed.emit()


func is_open() -> bool:
	return visible


# --- Read access for tests and later screens ---

func tray_ids_shown() -> Array[StringName]:
	var ids: Array[StringName] = []
	for node: Node in _tray_list.get_children():
		var card: ClueCardView = node as ClueCardView
		if card != null:
			ids.append(card.fact_id)
	return ids


func tray_card(fact_id: StringName) -> ClueCardView:
	return _tray_cards.get(fact_id)


func pinned_card(fact_id: StringName) -> ClueCardView:
	return _pinned_cards.get(fact_id)


func board_area() -> ClueBoardArea:
	return _area


func close_button() -> Button:
	return _close_button


func empty_text_shown() -> bool:
	return _empty_label.visible


func count_text() -> String:
	return _count_label.text


# --- Building ---

func _state() -> ClueBoardState:
	return GameState.clue_board


func _revealed() -> Array[StringName]:
	return GameState.revealed_fact_ids


func _card_for(fact_id: StringName) -> ClueCard:
	return ClueCard.from_fact(fact_id, GameState.truth_sheet, GameState.case_template())


func _rebuild() -> void:
	_rebuild_tray()
	_rebuild_pinned()
	_refresh_count()


func _rebuild_tray() -> void:
	for card: ClueCardView in _tray_cards.values():
		_discard(card)
	_tray_cards.clear()
	if GameState.truth_sheet != null:
		for fact_id: StringName in _state().tray_ids(_revealed()):
			var view: ClueCardView = _new_view(fact_id, false)
			view.pin_pressed.connect(_pin)
			_tray_list.add_child(view)
			_tray_cards[fact_id] = view
	_empty_label.visible = _revealed().is_empty()


func _rebuild_pinned() -> void:
	for card: ClueCardView in _pinned_cards.values():
		_discard(card)
	_pinned_cards.clear()
	if GameState.truth_sheet != null:
		for fact_id: StringName in _state().pinned_ids():
			_add_pinned_view(fact_id)
	_refresh_selection()
	_refresh_links()


## Out of the tree at once, so lists read right in the same frame; freed at frame end
## because the card may be the one whose button is being pressed.
func _discard(view: ClueCardView) -> void:
	view.get_parent().remove_child(view)
	view.queue_free()


func _new_view(fact_id: StringName, pinned: bool) -> ClueCardView:
	var view: ClueCardView = ClueCardView.new()
	view.setup(_card_for(fact_id), pinned)
	return view


func _add_pinned_view(fact_id: StringName) -> void:
	var view: ClueCardView = _new_view(fact_id, true)
	view.unpin_pressed.connect(_unpin)
	view.clicked.connect(_select)
	view.dragged.connect(_drag)
	# The wrapped text settles its height a frame later; keep link ends on the card centre.
	view.resized.connect(_refresh_links)
	_area.add_child(view)
	view.reset_size()
	view.position = _state().position_of(fact_id)
	_pinned_cards[fact_id] = view


func _refresh_count() -> void:
	var total: int = _revealed().size()
	_count_label.text = "%d clue%s · %d pinned" % [total, "" if total == 1 else "s",
		_state().pinned_ids().size()]


func _refresh_selection() -> void:
	for fact_id: StringName in _pinned_cards:
		_pinned_cards[fact_id].set_selected(fact_id == _state().selected)


func _refresh_links() -> void:
	var segments: Array[PackedVector2Array] = []
	for pair: Array in _state().links():
		var a: ClueCardView = _pinned_cards.get(pair[0])
		var b: ClueCardView = _pinned_cards.get(pair[1])
		if a != null and b != null:
			segments.append(PackedVector2Array([_centre(a), _centre(b)]))
	_area.set_links(segments)


func _centre(view: ClueCardView) -> Vector2:
	return view.position + view.size / 2.0


# --- Player actions ---

func _pin(fact_id: StringName) -> void:
	var view: ClueCardView = _tray_cards.get(fact_id)
	# The tray card is wider than the pinned one; clamp with the width it will have.
	var card_size: Vector2 = Vector2(ClueCardView.PINNED_WIDTH, view.size.y if view != null else PIN_STEP.y)
	var pos: Vector2 = ClueBoardState.clamp_position(_next_slot(card_size), card_size, _area.size)
	if not _state().pin(fact_id, pos, _revealed()):
		return
	_rebuild()
	_keep_focus()


## First grid slot no pinned card sits on, so new cards do not land on top of old ones.
## When every slot is taken the first one is reused.
func _next_slot(card_size: Vector2) -> Vector2:
	var columns: int = maxi(1, int((_area.size.x - PIN_MARGIN.x) / PIN_STEP.x))
	var rows: int = maxi(1, int((_area.size.y - PIN_MARGIN.y) / PIN_STEP.y))
	var taken: Array[Vector2] = []
	for id: StringName in _state().pinned_ids():
		taken.append(_state().position_of(id))
	for slot: int in columns * rows:
		var pos: Vector2 = ClueBoardState.clamp_position(
			PIN_MARGIN + Vector2(slot % columns, slot / columns) * PIN_STEP, card_size, _area.size)
		if not taken.has(pos):
			return pos
	return PIN_MARGIN


func _unpin(fact_id: StringName) -> void:
	_state().unpin(fact_id)
	_rebuild()
	_keep_focus()


## Pin and unpin remove the card whose button had focus; give keyboard users a place to
## continue from: the first tray card's Pin button, or Close.
func _keep_focus() -> void:
	if not visible or get_viewport().gui_get_focus_owner() != null:
		return
	var tray: Array[StringName] = _state().tray_ids(_revealed())
	if not tray.is_empty() and _tray_cards.has(tray[0]):
		_tray_cards[tray[0]].action_button().grab_focus()
	else:
		_close_button.grab_focus()


func _select(fact_id: StringName) -> void:
	_state().select(fact_id)
	_refresh_selection()
	_refresh_links()


func _drag(fact_id: StringName, pos: Vector2) -> void:
	var view: ClueCardView = _pinned_cards.get(fact_id)
	if view == null:
		return
	var clamped: Vector2 = ClueBoardState.clamp_position(pos, view.size, _area.size)
	_state().move(fact_id, clamped)
	view.position = clamped
	_refresh_links()


func _on_fact_revealed(_fact_id: StringName) -> void:
	if visible:
		_rebuild_tray()
		_refresh_count()
		_keep_focus()
