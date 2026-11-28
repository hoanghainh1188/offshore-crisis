extends GutTest
## Reading a part 2 document unlocks a follow-up question in the real office
## (specs/artifact-viewer: Reading can unlock follow-up questions; specs/npc-dialogue).

const LINH_SPOT: Vector2 = Vector2(232, 112)
const TRANG_SPOT: Vector2 = Vector2(500, 136)
const TERMINAL_SPOT: Vector2 = Vector2(60, 112)

var _room: OfficeRoom
var _player: Player
var _viewer: ArtifactViewer
var _panel: DialoguePanel


func after_each() -> void:
	GameState.reset_run()


## First seed whose Truth Sheet satisfies every fact -> holder pair. Deterministic.
func _seed_where(wanted: Dictionary) -> int:
	var template: CaseTemplate = GameState.case_template()
	for seed_value: int in range(1, 1000):
		var sheet: TruthSheet = CaseGenerator.new().generate(template, seed_value)
		var ok: bool = true
		for fact_id: StringName in wanted:
			ok = ok and sheet.knowledge.get(fact_id, "") == wanted[fact_id]
		if ok:
			return seed_value
	return -1


func _start(wanted: Dictionary) -> void:
	GameState.reset_run()
	var seed_value: int = _seed_where(wanted)
	assert_gt(seed_value, 0, "a seed exists for %s" % wanted)
	GameState.start_case(seed_value)
	GameState.clock.start(900.0)
	GameState.clock.pause(&"test")
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	_player = _room.get_node("Player") as Player
	_viewer = _room.get_node("ArtifactViewer") as ArtifactViewer
	_panel = _room.get_node("DialoguePanel") as DialoguePanel
	await wait_physics_frames(2)


func _stand_at(pos: Vector2) -> void:
	_player.position = pos
	await wait_physics_frames(3)


func _press(key: Key) -> void:
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


func _read_at_terminal(type: StringName) -> void:
	await _stand_at(TERMINAL_SPOT)
	await _press(KEY_E)
	assert_true(_viewer.is_open())
	_viewer.document_button(type).pressed.emit()
	await _press(KEY_ESCAPE)


func _talk_to(spot: Vector2) -> Array[StringName]:
	await _stand_at(spot)
	await _press(KEY_E)
	assert_true(_panel.is_open())
	return _panel.listed_question_ids()


func test_git_log_unlocks_linh_follow_up() -> void:
	await _start({&"fact_coc_no_ticket": "artifact:git_log"})
	assert_does_not_have(await _talk_to(LINH_SPOT), &"linh_no_ticket_followup", "locked before reading")
	await _press(KEY_ESCAPE)
	await _read_at_terminal(&"git_log")
	assert_has(GameState.revealed_fact_ids, &"fact_coc_no_ticket")
	assert_has(await _talk_to(LINH_SPOT), &"linh_no_ticket_followup")


func test_spec_unlocks_trang_follow_up() -> void:
	await _start({&"fact_lit_jp_spec_closing": "artifact:spec_doc"})
	assert_does_not_have(await _talk_to(TRANG_SPOT), &"trang_closing_followup", "locked before reading")
	await _press(KEY_ESCAPE)
	await _read_at_terminal(&"spec_doc")
	assert_has(await _talk_to(TRANG_SPOT), &"trang_closing_followup")


func test_trang_follow_up_reveals_nothing_and_costs_time_once() -> void:
	await _start({&"fact_lit_jp_spec_closing": "artifact:spec_doc"})
	await _read_at_terminal(&"spec_doc")
	await _talk_to(TRANG_SPOT)
	var revealed: int = GameState.revealed_fact_ids.size()
	var before: int = GameState.clock.office_minutes()
	_panel.question_button(&"trang_closing_followup").pressed.emit()
	await wait_process_frames(2)
	assert_eq(GameState.revealed_fact_ids.size(), revealed)
	assert_eq(GameState.clock.office_minutes(), before + 15)
	assert_string_contains(_panel.shown_answer(), "English ticket")


func test_linh_follow_up_reveals_chat_agreement_when_she_holds_it() -> void:
	await _start({&"fact_coc_no_ticket": "artifact:git_log", &"fact_coc_chat_agreement": "npc:linh"})
	await _read_at_terminal(&"git_log")
	await _talk_to(LINH_SPOT)
	_panel.question_button(&"linh_no_ticket_followup").pressed.emit()
	await wait_process_frames(2)
	assert_has(GameState.revealed_fact_ids, &"fact_coc_chat_agreement")


func test_linh_follow_up_reveals_nothing_when_the_chat_log_holds_it() -> void:
	await _start({&"fact_coc_no_ticket": "artifact:git_log", &"fact_coc_chat_agreement": "artifact:chat_log"})
	await _read_at_terminal(&"git_log")
	await _talk_to(LINH_SPOT)
	_panel.question_button(&"linh_no_ticket_followup").pressed.emit()
	await wait_process_frames(2)
	assert_does_not_have(GameState.revealed_fact_ids, &"fact_coc_chat_agreement")
