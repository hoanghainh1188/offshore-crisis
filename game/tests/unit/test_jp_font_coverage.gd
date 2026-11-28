extends GutTest
## Every CJK character in the game's text data must exist in the subset font, or it shows
## as an empty box on web (specs/artifact-viewer). The same holds for non-ASCII UI marks
## in scripts (for example the ✓ on asked questions): web has no system font fallback.
## Fix: rebuild the font (fonts/README.md).

const FONT_PATH: String = "res://fonts/noto_sans_jp_subset.ttf"
const DATA_FILES: Array[String] = [
	"res://case/templates/wrong_delivery.json",
	"res://artifacts/artifact_filler.json",
	"res://dialogue/dialogue_offline.json",
]
## Script folders that are not game UI and are skipped by the code scan.
const SKIPPED_DIRS: Array[String] = ["res://addons", "res://tests"]

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


## Returns every non-ASCII, non-whitespace character in the text that the font cannot draw.
func _missing_any(text: String) -> Array[String]:
	var missing: Array[String] = []
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		if code > 0x7E and code != 0xA0 and not _font.has_char(code) \
				and not missing.has(text[i]):
			missing.append(text[i])
	return missing


## Collects every game script under the folder, skipping addons and tests.
static func _game_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	if SKIPPED_DIRS.has(dir_path):
		return found
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		if not sub_dir.begins_with("."):
			found.append_array(_game_scripts(dir_path.path_join(sub_dir)))
	return found


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


func test_ui_marks_in_scripts_are_covered() -> void:
	var scripts: Array[String] = _game_scripts("res://")
	assert_true(scripts.has("res://dialogue/dialogue_panel.gd"), "scan finds game scripts")
	for path: String in scripts:
		var missing: Array[String] = _missing_any(FileAccess.get_file_as_string(path))
		assert_eq(missing, [] as Array[String], "%s uses a mark the font lacks" % path)


func test_asked_mark_is_covered() -> void:
	assert_eq(_missing_any(DialoguePanel.ASKED_MARK), [] as Array[String])
