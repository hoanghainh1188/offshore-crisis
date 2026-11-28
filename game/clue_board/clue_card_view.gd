class_name ClueCardView
extends PanelContainer
## One clue card on screen (specs/clue-board). In the tray it has a Pin button; on the board
## it can be dragged, clicked to select or link, and unpinned with its × button. The card
## only reports what the player did; ClueBoard applies it to ClueBoardState.

signal pin_pressed(fact_id: StringName)
signal unpin_pressed(fact_id: StringName)
signal clicked(fact_id: StringName)
## `pos` is the wanted top-left in the parent's coordinates, before clamping.
signal dragged(fact_id: StringName, pos: Vector2)

## Mouse travel in pixels before a press counts as a drag instead of a click.
const DRAG_THRESHOLD: float = 4.0
const TRAY_WIDTH: float = 150.0
const PINNED_WIDTH: float = 128.0
const TEXT_COLOR: Color = Color(0.12, 0.12, 0.14, 1)
const SOURCE_COLOR: Color = Color(0.32, 0.34, 0.4, 1)
const PAPER: Color = Color(1.0, 0.97, 0.84, 1)
const BORDER: Color = Color(0.55, 0.5, 0.38, 1)
const SELECTED_BORDER: Color = Color(0.75, 0.15, 0.12, 1)

var fact_id: StringName
var pinned: bool = false

var _text_label: Label
var _source_label: Label
var _action_button: Button
var _style: StyleBoxFlat
var _pressing: bool = false
var _dragging: bool = false
var _press_mouse: Vector2
var _press_pos: Vector2


func setup(card: ClueCard, is_pinned: bool) -> void:
	fact_id = card.fact_id
	pinned = is_pinned
	name = String(card.fact_id)
	custom_minimum_size = Vector2(PINNED_WIDTH if pinned else TRAY_WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP if pinned else Control.MOUSE_FILTER_PASS
	_style = StyleBoxFlat.new()
	_style.bg_color = PAPER
	_style.set_border_width_all(1)
	_style.border_color = BORDER
	_style.set_content_margin_all(4)
	add_theme_stylebox_override(&"panel", _style)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_text_label = Label.new()
	_text_label.text = card.text
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	_text_label.add_theme_font_size_override(&"font_size", 9 if pinned else 10)
	column.add_child(_text_label)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(footer)
	_source_label = Label.new()
	_source_label.text = card.source
	_source_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_label.add_theme_color_override(&"font_color", SOURCE_COLOR)
	_source_label.add_theme_font_size_override(&"font_size", 9)
	footer.add_child(_source_label)
	_action_button = Button.new()
	_action_button.name = "Unpin" if pinned else "Pin"
	_action_button.text = "×" if pinned else "Pin"
	_action_button.tooltip_text = "Unpin" if pinned else "Pin to the board"
	_action_button.add_theme_font_size_override(&"font_size", 9)
	_action_button.pressed.connect(_on_action_pressed)
	footer.add_child(_action_button)
	if pinned:
		# On the board the card is not inside a container, so nothing shrinks it after the
		# wrapped label learns its width; follow the minimum size both ways.
		minimum_size_changed.connect(reset_size)


func text() -> String:
	return _text_label.text


func source() -> String:
	return _source_label.text


func action_button() -> Button:
	return _action_button


func set_selected(on: bool) -> void:
	_style.border_color = SELECTED_BORDER if on else BORDER
	_style.set_border_width_all(2 if on else 1)


func is_selected() -> bool:
	return _style.border_color == SELECTED_BORDER


func _gui_input(event: InputEvent) -> void:
	if not pinned:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_pressing = true
			_dragging = false
			_press_mouse = button.global_position
			_press_pos = position
		elif _pressing:
			_pressing = false
			if not _dragging:
				clicked.emit(fact_id)
			_dragging = false
		accept_event()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _pressing and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		# The release was lost (e.g. let go outside the web canvas); drop the card instead of
		# letting it follow the cursor.
		_pressing = false
		_dragging = false
		return
	if motion != null and _pressing:
		var travel: Vector2 = motion.global_position - _press_mouse
		if _dragging or travel.length() > DRAG_THRESHOLD:
			_dragging = true
			dragged.emit(fact_id, _press_pos + travel)
		accept_event()


func _on_action_pressed() -> void:
	if pinned:
		unpin_pressed.emit(fact_id)
	else:
		pin_pressed.emit(fact_id)
