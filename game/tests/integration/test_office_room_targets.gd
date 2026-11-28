extends GutTest
## specs/world-interaction: the prototype room contains the required targets, plus the
## PC Terminal from specs/artifact-viewer.

const EXPECTED: Dictionary = {
	"npc:linh": "Linh",
	"npc:trang": "Trang",
	"npc:minh": "Minh",
	"npc:hana": "Hana",
	"object:document_shelf": "Document Shelf",
	"object:meeting_screen": "Meeting Room Screen",
	"object:pc_terminal": "PC Terminal",
}

var _room: OfficeRoom


func before_each() -> void:
	_room = (load("res://office/office_room.tscn") as PackedScene).instantiate() as OfficeRoom
	add_child_autofree(_room)


func _targets() -> Array[Interactable]:
	var found: Array[Interactable] = []
	for node: Node in _room.find_children("*", "Interactable", true, false):
		found.append(node as Interactable)
	return found


func test_room_has_the_spec_targets() -> void:
	var keys: Dictionary = {}
	for target: Interactable in _targets():
		keys["%s:%s" % [target.kind_name(), target.id]] = target.display_name
	assert_eq(keys, EXPECTED)


func test_kind_and_id_pairs_are_unique() -> void:
	var seen: Array[String] = []
	for target: Interactable in _targets():
		var key: String = "%s:%s" % [target.kind_name(), target.id]
		assert_false(seen.has(key), "duplicate target %s" % key)
		seen.append(key)
	assert_eq(seen.size(), EXPECTED.size())
