class_name ArtifactFiller
extends RefCounted
## Title and filler lines per artifact type, loaded from a data file. Filler keeps a
## document from showing only its facts (specs/artifact-viewer).

## Empty after a successful load; otherwise "<path>: <problem>".
static var last_error: String = ""

var _titles: Dictionary[StringName, String] = {}
var _lines: Dictionary[StringName, Array] = {}


## Returns null when the file is missing, not JSON, or lacks a supported type.
static func load_from(path: String) -> ArtifactFiller:
	last_error = ""
	if not FileAccess.file_exists(path):
		return _fail(path, "file not found")
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _fail(path, "not a JSON object")
	var data: Dictionary = json.data
	var filler: ArtifactFiller = ArtifactFiller.new()
	for type: StringName in ArtifactDocument.TYPES:
		var entry: Variant = data.get(String(type))
		if typeof(entry) != TYPE_DICTIONARY:
			return _fail(path, "missing artifact type '%s'" % type)
		var title: Variant = (entry as Dictionary).get("title")
		var lines: Variant = (entry as Dictionary).get("lines")
		if typeof(title) != TYPE_STRING or (title as String).is_empty():
			return _fail(path, "artifact type '%s' needs a 'title'" % type)
		if typeof(lines) != TYPE_ARRAY or (lines as Array).is_empty() \
				or not (lines as Array).all(func(l: Variant) -> bool: return typeof(l) == TYPE_STRING):
			return _fail(path, "artifact type '%s' needs a non-empty 'lines' list" % type)
		filler._titles[type] = title
		var typed: Array[String] = []
		typed.assign(lines)
		filler._lines[type] = typed
	return filler


static func _fail(path: String, problem: String) -> ArtifactFiller:
	last_error = "%s: %s" % [path, problem]
	push_error(last_error)
	return null


func title_for(type: StringName) -> String:
	return _titles.get(type, "")


func lines_for(type: StringName) -> Array[String]:
	var lines: Array[String] = []
	lines.assign(_lines.get(type, []))
	return lines
