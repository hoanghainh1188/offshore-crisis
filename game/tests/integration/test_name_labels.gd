extends GutTest
## Target names must stay readable: drawn above the player, and not on top of
## walls or furniture. Found in Antigravity QA (see the change notes.md).

var _room: OfficeRoom


func before_each() -> void:
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)
	await wait_process_frames(2)


func _targets() -> Array[Interactable]:
	var found: Array[Interactable] = []
	for node: Node in _room.find_children("*", "Interactable", true, false):
		found.append(node as Interactable)
	return found


func test_name_labels_draw_above_player() -> void:
	var player: Player = _room.get_node("Player") as Player
	for target: Interactable in _targets():
		var label: Label = target.get_node("NameLabel") as Label
		assert_gt(label.z_index, player.z_index, "%s label above the player" % target.display_name)


## Text rect = the visible text (centered in the fixed-width label), in room coordinates.
func _text_rect(label: Label) -> Rect2:
	var text_size: Vector2 = label.get_minimum_size()
	var center_x: float = label.global_position.x + label.size.x / 2.0
	return Rect2(Vector2(center_x - text_size.x / 2.0, label.global_position.y), Vector2(text_size.x, label.size.y))


func test_name_labels_do_not_cover_solids() -> void:
	var solids: Array[Rect2] = []
	for shape_node: Node in _room.get_node("Solids").get_children():
		var col: CollisionShape2D = shape_node as CollisionShape2D
		var rect: RectangleShape2D = col.shape as RectangleShape2D
		solids.append(Rect2(col.global_position - rect.size / 2.0, rect.size))
	for target: Interactable in _targets():
		var text: Rect2 = _text_rect(target.get_node("NameLabel") as Label)
		for solid: Rect2 in solids:
			assert_false(text.intersects(solid), "%s label %s overlaps solid %s" % [target.display_name, text, solid])
