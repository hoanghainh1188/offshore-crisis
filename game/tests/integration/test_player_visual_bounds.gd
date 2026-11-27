extends GutTest
## Guards against the drawn player sticking into walls: the collider must cover
## the whole visual body (see ai-failures/2026-11-27-player-sprite-overlaps-wall.md).


func test_collider_covers_visual() -> void:
	var player: Player = (load("res://player/player.tscn") as PackedScene).instantiate() as Player
	add_child_autofree(player)
	var shape_node: CollisionShape2D = player.get_node("CollisionShape2D") as CollisionShape2D
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	var collider: Rect2 = Rect2(shape_node.position - rect.size / 2.0, rect.size)
	var visual: Polygon2D = player.get_node("Body") as Polygon2D
	for point: Vector2 in visual.polygon:
		assert_true(collider.grow(0.01).has_point(point), "visual point %s inside collider" % point)
