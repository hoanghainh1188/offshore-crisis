class_name ClueBoardState
extends RefCounted
## Rules of the clue board for one run (specs/clue-board): which cards are pinned and where,
## and which pinned cards are linked. Pure data, so the report screen can read pins later
## and tests need no UI. Pins and links are a thinking aid: nothing here touches the run.

## Results of select(), so the view can react without re-reading the state.
const SELECTED: StringName = &"selected"
const LINKED: StringName = &"linked"
const UNLINKED: StringName = &"unlinked"
const CLEARED: StringName = &"cleared"
const IGNORED: StringName = &"ignored"

## First end of a link in progress; empty when nothing is selected.
var selected: StringName = &""

## Fact id -> position in board-area coordinates. Insertion order is pin order.
var _pinned: Dictionary[StringName, Vector2] = {}
## Link key "a|b" (ids sorted) -> the sorted pair, so a pair exists once in either order.
var _links: Dictionary[String, Array] = {}


## Revealed ids that are not pinned, in reveal order.
func tray_ids(revealed: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in revealed:
		if not _pinned.has(id):
			result.append(id)
	return result


## Pins a revealed card. Refuses unrevealed ids so the board never shows an unfound fact.
func pin(id: StringName, pos: Vector2, revealed: Array[StringName]) -> bool:
	if not revealed.has(id) or _pinned.has(id):
		return false
	_pinned[id] = pos
	return true


func unpin(id: StringName) -> void:
	if not _pinned.erase(id):
		return
	for key: String in _links.keys():
		if (_links[key] as Array).has(id):
			_links.erase(key)
	if selected == id:
		selected = &""


func move(id: StringName, pos: Vector2) -> void:
	if _pinned.has(id):
		_pinned[id] = pos


func is_pinned(id: StringName) -> bool:
	return _pinned.has(id)


func position_of(id: StringName) -> Vector2:
	return _pinned.get(id, Vector2.ZERO)


func pinned_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_pinned.keys())
	return result


## Selecting a second pinned card toggles the link between the two. Tray cards are ignored.
func select(id: StringName) -> StringName:
	if not _pinned.has(id):
		return IGNORED
	if selected == &"":
		selected = id
		return SELECTED
	var first: StringName = selected
	selected = &""
	if first == id:
		return CLEARED
	var key: String = _key(first, id)
	if _links.has(key):
		_links.erase(key)
		return UNLINKED
	_links[key] = _pair(first, id)
	return LINKED


func is_linked(a: StringName, b: StringName) -> bool:
	return _links.has(_key(a, b))


## Links as sorted [a, b] pairs, in the order they were made.
func links() -> Array[Array]:
	var result: Array[Array] = []
	for pair: Array in _links.values():
		result.append(pair.duplicate())
	return result


static func _pair(a: StringName, b: StringName) -> Array:
	return [a, b] if String(a) < String(b) else [b, a]


static func _key(a: StringName, b: StringName) -> String:
	var pair: Array = _pair(a, b)
	return "%s|%s" % [pair[0], pair[1]]


## Top-left position that keeps a card of `card_size` fully inside the board area. A card
## bigger than the area sticks to the top-left corner.
static func clamp_position(pos: Vector2, card_size: Vector2, area_size: Vector2) -> Vector2:
	var max_pos: Vector2 = (area_size - card_size).max(Vector2.ZERO)
	return pos.clamp(Vector2.ZERO, max_pos)
