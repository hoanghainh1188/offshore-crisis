class_name ClueBoardArea
extends Control
## The cork part of the clue board: holds pinned cards and draws links under them.

const LINK_COLOR: Color = Color(0.75, 0.15, 0.12, 0.85)
const LINK_WIDTH: float = 2.0

## Line segments [from, to] in local coordinates, set by ClueBoard.
var link_segments: Array[PackedVector2Array] = []


func set_links(segments: Array[PackedVector2Array]) -> void:
	link_segments = segments
	queue_redraw()


func _draw() -> void:
	for segment: PackedVector2Array in link_segments:
		draw_line(segment[0], segment[1], LINK_COLOR, LINK_WIDTH, true)
