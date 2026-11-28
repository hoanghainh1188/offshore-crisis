extends GutTest
## Every CJK character in the game's text data must exist in the subset font, or it shows
## as an empty box on web (specs/artifact-viewer). Fix: rebuild the font (fonts/README.md).

const FONT_PATH: String = "res://fonts/noto_sans_jp_subset.ttf"
const DATA_FILES: Array[String] = [
	"res://case/templates/wrong_delivery.json",
	"res://artifacts/artifact_filler.json",
	"res://dialogue/dialogue_offline.json",
]

var _font: FontFile


func before_all() -> void:
	_font = load(FONT_PATH) as FontFile


static func _is_cjk(code: int) -> bool:
	return (code >= 0x3000 and code <= 0x9FFF) or (code >= 0xF900 and code <= 0xFAFF) \
		or (code >= 0xFF00 and code <= 0xFFEF)


## Returns the CJK characters in the text that the font cannot draw.
func _missing(text: String) -> Array[String]:
	var missing: Array[String] = []
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		if _is_cjk(code) and not _font.has_char(code) and not missing.has(text[i]):
			missing.append(text[i])
	return missing


func test_font_loads_and_is_small() -> void:
	assert_not_null(_font)
	var size: int = FileAccess.get_file_as_bytes(FONT_PATH).size()
	assert_lt(size, 1024 * 1024, "subset stays under 1 MB")


func test_known_terms_are_covered() -> void:
	assert_eq(_missing("はい 月次締め 締め日"), [] as Array[String])


func test_every_data_file_is_covered() -> void:
	for path: String in DATA_FILES:
		var missing: Array[String] = _missing(FileAccess.get_file_as_string(path))
		assert_eq(missing, [] as Array[String], "%s needs a font rebuild" % path)


func test_detects_a_character_outside_the_subset() -> void:
	# 鬱 is not in any data file, so the check must report it.
	assert_eq(_missing("鬱"), ["鬱"] as Array[String])
