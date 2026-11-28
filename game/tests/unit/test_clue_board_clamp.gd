extends GutTest
## Dragged cards stay fully inside the board area (specs/clue-board: move a pinned card).

const AREA: Vector2 = Vector2(400, 280)
const CARD: Vector2 = Vector2(120, 60)


func test_inside_is_unchanged() -> void:
	assert_eq(ClueBoardState.clamp_position(Vector2(50, 40), CARD, AREA), Vector2(50, 40))


func test_past_left_and_top() -> void:
	assert_eq(ClueBoardState.clamp_position(Vector2(-30, -10), CARD, AREA), Vector2(0, 0))


func test_past_right_and_bottom() -> void:
	assert_eq(ClueBoardState.clamp_position(Vector2(390, 300), CARD, AREA), Vector2(280, 220))


func test_card_larger_than_area_sticks_to_top_left() -> void:
	assert_eq(ClueBoardState.clamp_position(Vector2(10, 10), Vector2(500, 400), AREA), Vector2.ZERO)
