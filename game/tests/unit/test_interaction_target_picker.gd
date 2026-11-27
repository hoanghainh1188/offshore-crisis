extends GutTest
## Nearest-target rule from specs/world-interaction, including the tie-break.

const INTERACTABLE_SCENE: PackedScene = preload("res://interaction/interactable.tscn")


func _target_at(pos: Vector2, target_id: StringName) -> Interactable:
	var target: Interactable = INTERACTABLE_SCENE.instantiate() as Interactable
	target.id = target_id
	target.position = pos
	add_child_autofree(target)
	return target


func test_empty_list_returns_null() -> void:
	var none: Array[Interactable] = []
	assert_null(InteractionTargetPicker.pick_nearest(Vector2.ZERO, none))


func test_nearest_wins_regardless_of_order() -> void:
	var far: Interactable = _target_at(Vector2(50, 0), &"far")
	var near: Interactable = _target_at(Vector2(10, 0), &"near")
	var candidates: Array[Interactable] = [far, near]
	assert_eq(InteractionTargetPicker.pick_nearest(Vector2.ZERO, candidates), near)


func test_exact_tie_returns_earlier_entry() -> void:
	var first: Interactable = _target_at(Vector2(-20, 0), &"first")
	var second: Interactable = _target_at(Vector2(20, 0), &"second")
	var candidates: Array[Interactable] = [first, second]
	assert_eq(InteractionTargetPicker.pick_nearest(Vector2.ZERO, candidates), first)
	var reversed: Array[Interactable] = [second, first]
	assert_eq(InteractionTargetPicker.pick_nearest(Vector2.ZERO, reversed), second)
