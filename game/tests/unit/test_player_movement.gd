extends GutTest
## Movement rules from specs/player-movement: stop on release, diagonal not faster.

const SPEED: float = 100.0


func test_zero_input_gives_zero_velocity() -> void:
	assert_eq(Player.compute_velocity(Vector2.ZERO, SPEED), Vector2.ZERO)


func test_straight_input_gives_full_speed() -> void:
	assert_eq(Player.compute_velocity(Vector2.RIGHT, SPEED), Vector2(SPEED, 0.0))


func test_diagonal_is_not_faster_than_straight() -> void:
	var diagonal: Vector2 = Player.compute_velocity(Vector2(1.0, -1.0), SPEED)
	assert_almost_eq(diagonal.length(), SPEED, 0.001)
	assert_gt(diagonal.x, 0.0, "moves right")
	assert_lt(diagonal.y, 0.0, "moves up")


func test_tuning_resource_loads_with_positive_speed() -> void:
	var tuning: PlayerTuning = load("res://player/player_tuning.tres") as PlayerTuning
	assert_not_null(tuning)
	assert_gt(tuning.move_speed, 0.0)
