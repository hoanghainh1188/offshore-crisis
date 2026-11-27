extends GutTest
## Briefing screen content and Start button (specs/run-flow).

const EMAIL_PATH: String = "res://run/briefing/wrong_delivery_email.tres"

var _screen: BriefingScreen


func before_each() -> void:
	_screen = (load("res://run/briefing/briefing_screen.tscn") as PackedScene).instantiate() as BriefingScreen
	add_child_autofree(_screen)
	watch_signals(_screen)
	await wait_process_frames(2)


func test_email_resource_has_all_fields() -> void:
	var email: BriefingEmail = load(EMAIL_PATH) as BriefingEmail
	assert_not_null(email)
	assert_false(email.sender.is_empty(), "sender")
	assert_false(email.subject.is_empty(), "subject")
	assert_false(email.body.is_empty(), "body")


func test_labels_show_email_from_data() -> void:
	var email: BriefingEmail = load(EMAIL_PATH) as BriefingEmail
	assert_string_contains(_label("%SenderLabel").text, email.sender)
	assert_string_contains(_label("%SubjectLabel").text, email.subject)
	assert_eq(_label("%BodyLabel").text, email.body)


func test_screen_uses_injected_email() -> void:
	var custom: BriefingEmail = BriefingEmail.new()
	custom.sender = "A"
	custom.subject = "Edited subject"
	custom.body = "B"
	var screen: BriefingScreen = (load("res://run/briefing/briefing_screen.tscn") as PackedScene).instantiate() as BriefingScreen
	screen.email = custom
	add_child_autofree(screen)
	await wait_process_frames(1)
	assert_string_contains((screen.get_node("%SubjectLabel") as Label).text, "Edited subject")


func test_start_button_has_focus_on_open() -> void:
	assert_true(_start_button().has_focus())


func test_pressing_start_emits_once() -> void:
	_start_button().pressed.emit()
	_start_button().pressed.emit()
	assert_signal_emit_count(_screen, "start_pressed", 1)


func test_enter_presses_start() -> void:
	await _press_key(KEY_ENTER)
	assert_signal_emit_count(_screen, "start_pressed", 1)


func test_space_presses_start() -> void:
	await _press_key(KEY_SPACE)
	assert_signal_emit_count(_screen, "start_pressed", 1)


func _label(path: String) -> Label:
	return _screen.get_node(path) as Label


func _start_button() -> Button:
	return _screen.get_node("%StartButton") as Button


func _press_key(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	var release: InputEventKey = event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(2)
