extends GutTest
## Board rules without UI (specs/clue-board): tray, pin, unpin, move, link.

const A: StringName = &"fact_a"
const B: StringName = &"fact_b"
const C: StringName = &"fact_c"

var _state: ClueBoardState
var _revealed: Array[StringName] = [A, B, C]


func before_each() -> void:
	_state = ClueBoardState.new()


func test_tray_follows_reveal_order() -> void:
	assert_eq(_state.tray_ids(_revealed), [A, B, C] as Array[StringName])


func test_pinned_card_leaves_the_tray() -> void:
	assert_true(_state.pin(B, Vector2(10, 20), _revealed))
	assert_eq(_state.tray_ids(_revealed), [A, C] as Array[StringName])
	assert_true(_state.is_pinned(B))
	assert_eq(_state.position_of(B), Vector2(10, 20))


func test_pin_refuses_unrevealed_id() -> void:
	assert_false(_state.pin(&"fact_hidden", Vector2.ZERO, _revealed))
	assert_eq(_state.pinned_ids().size(), 0)


func test_pin_twice_keeps_first_position() -> void:
	_state.pin(A, Vector2(1, 1), _revealed)
	assert_false(_state.pin(A, Vector2(5, 5), _revealed))
	assert_eq(_state.position_of(A), Vector2(1, 1))


func test_pinned_ids_in_pin_order() -> void:
	_state.pin(C, Vector2.ZERO, _revealed)
	_state.pin(A, Vector2.ZERO, _revealed)
	assert_eq(_state.pinned_ids(), [C, A] as Array[StringName])


func test_unpin_returns_card_to_its_reveal_order_place() -> void:
	_state.pin(A, Vector2.ZERO, _revealed)
	_state.pin(B, Vector2.ZERO, _revealed)
	_state.unpin(A)
	assert_eq(_state.tray_ids(_revealed), [A, C] as Array[StringName])
	assert_false(_state.is_pinned(A))


func test_unpin_removes_links_and_selection() -> void:
	_state.pin(A, Vector2.ZERO, _revealed)
	_state.pin(B, Vector2.ZERO, _revealed)
	_state.pin(C, Vector2.ZERO, _revealed)
	_state.select(A)
	_state.select(B)
	_state.select(A)
	_state.unpin(A)
	assert_false(_state.is_linked(A, B))
	assert_eq(_state.links().size(), 0)
	assert_eq(_state.selected, &"")


func test_select_then_select_links() -> void:
	_pin_all()
	assert_eq(_state.select(A), ClueBoardState.SELECTED)
	assert_eq(_state.select(B), ClueBoardState.LINKED)
	assert_true(_state.is_linked(A, B))
	assert_true(_state.is_linked(B, A))
	assert_eq(_state.selected, &"")


func test_same_pair_in_other_order_unlinks() -> void:
	_pin_all()
	_state.select(A)
	_state.select(B)
	_state.select(B)
	assert_eq(_state.select(A), ClueBoardState.UNLINKED)
	assert_false(_state.is_linked(A, B))
	assert_eq(_state.links().size(), 0)


func test_one_link_per_pair() -> void:
	_pin_all()
	_state.select(A)
	_state.select(B)
	_state.select(A)
	_state.select(C)
	assert_eq(_state.links().size(), 2)


func test_select_same_card_twice_clears() -> void:
	_pin_all()
	_state.select(A)
	assert_eq(_state.select(A), ClueBoardState.CLEARED)
	assert_eq(_state.selected, &"")
	assert_eq(_state.links().size(), 0)


func test_tray_card_cannot_be_selected() -> void:
	_state.pin(A, Vector2.ZERO, _revealed)
	assert_eq(_state.select(C), ClueBoardState.IGNORED)
	assert_eq(_state.selected, &"")
	_state.select(A)
	assert_eq(_state.select(C), ClueBoardState.IGNORED)
	assert_eq(_state.selected, A)
	assert_eq(_state.links().size(), 0)


func test_move_keeps_new_position() -> void:
	_state.pin(A, Vector2.ZERO, _revealed)
	_state.move(A, Vector2(40, 30))
	assert_eq(_state.position_of(A), Vector2(40, 30))


func test_move_ignores_tray_card() -> void:
	_state.move(A, Vector2(40, 30))
	assert_false(_state.is_pinned(A))


func test_links_are_sorted_pairs() -> void:
	_pin_all()
	_state.select(C)
	_state.select(A)
	assert_eq(_state.links(), [[A, C]])


func test_board_changes_nothing_else_in_the_run() -> void:
	GameState.reset_run()
	GameState.start_case(42)
	var revealed: Array[StringName] = []
	for fact: CaseTemplate.Fact in GameState.truth_sheet.chain:
		GameState.reveal_fact(fact.id)
	revealed.assign(GameState.revealed_fact_ids)
	var before_ids: Array[StringName] = GameState.revealed_fact_ids.duplicate()
	var before_minutes: int = GameState.clock.office_minutes()
	var board: ClueBoardState = GameState.clue_board
	for id: StringName in revealed:
		board.pin(id, Vector2.ZERO, revealed)
	board.select(revealed[0])
	board.select(revealed[1])
	board.unpin(revealed[1])
	assert_eq(GameState.revealed_fact_ids, before_ids)
	assert_eq(GameState.clock.office_minutes(), before_minutes)
	GameState.reset_run()


func _pin_all() -> void:
	for id: StringName in _revealed:
		_state.pin(id, Vector2.ZERO, _revealed)
