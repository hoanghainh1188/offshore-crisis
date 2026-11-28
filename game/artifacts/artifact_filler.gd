class_name ArtifactFiller
extends RefCounted
## Title and filler lines per artifact type, loaded from a data file. Filler keeps a
## document from showing only its facts (specs/artifact-viewer). An entry has either flat
## `lines` or titled `sections`, plus optional `fact_sections` that place facts.


## One block of filler lines; a flat entry is a single section with no heading.
class Section:
	extends RefCounted
	var id: String = ""
	var heading: String = ""
	var lines: Array[String] = []


## Empty after a successful load; otherwise "<path>: <problem>".
static var last_error: String = ""

var _titles: Dictionary[StringName, String] = {}
var _sections: Dictionary[StringName, Array] = {}
## type -> fact id -> section index.
var _fact_sections: Dictionary[StringName, Dictionary] = {}


## Returns null when the file is missing, not JSON, or an entry is malformed.
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
		var problem: String = filler._read_entry(type, entry as Dictionary)
		if not problem.is_empty():
			return _fail(path, "artifact type '%s' %s" % [type, problem])
	return filler


static func _fail(path: String, problem: String) -> ArtifactFiller:
	last_error = "%s: %s" % [path, problem]
	push_error(last_error)
	return null


static func _is_line_list(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and not (value as Array).is_empty() \
		and (value as Array).all(func(l: Variant) -> bool: return typeof(l) == TYPE_STRING)


## Returns "" when the entry is valid, otherwise the problem (after "artifact type 'x' ").
func _read_entry(type: StringName, entry: Dictionary) -> String:
	var title: Variant = entry.get("title")
	if typeof(title) != TYPE_STRING or (title as String).is_empty():
		return "needs a 'title'"
	var has_lines: bool = entry.has("lines")
	var has_sections: bool = entry.has("sections")
	if has_lines == has_sections:
		return "needs either 'lines' or 'sections', not both" if has_lines \
			else "needs a non-empty 'lines' or 'sections' list"
	var sections: Array[Section] = []
	if has_lines:
		if not _is_line_list(entry["lines"]):
			return "needs a non-empty 'lines' list"
		var flat: Section = Section.new()
		flat.lines.assign(entry["lines"])
		sections.append(flat)
	else:
		var problem: String = _read_sections(entry["sections"], sections)
		if not problem.is_empty():
			return problem
	if has_lines and entry.has("fact_sections"):
		return "has 'fact_sections' but no 'sections'"
	var placement: Dictionary = {}
	var problem_facts: String = _read_fact_sections(entry.get("fact_sections", {}), sections, placement)
	if not problem_facts.is_empty():
		return problem_facts
	_titles[type] = title
	_sections[type] = sections
	_fact_sections[type] = placement
	return ""


func _read_sections(raw: Variant, out: Array[Section]) -> String:
	if typeof(raw) != TYPE_ARRAY or (raw as Array).is_empty():
		return "needs a non-empty 'sections' list"
	var seen: Dictionary[String, bool] = {}
	for item: Variant in raw:
		if typeof(item) != TYPE_DICTIONARY:
			return "has a section that is not an object"
		var raw_id: Variant = (item as Dictionary).get("id")
		if typeof(raw_id) != TYPE_STRING or (raw_id as String).is_empty():
			return "has a section without an 'id'"
		var id: String = raw_id
		if seen.has(id):
			return "repeats section id '%s'" % id
		seen[id] = true
		var heading: Variant = (item as Dictionary).get("heading")
		if typeof(heading) != TYPE_STRING or (heading as String).is_empty():
			return "section '%s' needs a 'heading'" % id
		var lines: Variant = (item as Dictionary).get("lines")
		if not _is_line_list(lines):
			return "section '%s' needs a non-empty 'lines' list" % id
		var section: Section = Section.new()
		section.id = id
		section.heading = heading
		section.lines.assign(lines)
		out.append(section)
	return ""


func _read_fact_sections(raw: Variant, sections: Array[Section], out: Dictionary) -> String:
	if typeof(raw) != TYPE_DICTIONARY:
		return "needs 'fact_sections' to be an object"
	for fact_id: Variant in raw:
		var target: Variant = (raw as Dictionary)[fact_id]
		var index: int = -1
		for i: int in sections.size():
			if typeof(target) == TYPE_STRING and sections[i].id == target and not sections[i].id.is_empty():
				index = i
		if index < 0:
			return "fact '%s' goes to unknown section '%s'" % [fact_id, target]
		out[StringName(fact_id)] = index
	return ""


func title_for(type: StringName) -> String:
	return _titles.get(type, "")


## Every filler line of the type, all sections in order, without headings.
func lines_for(type: StringName) -> Array[String]:
	var lines: Array[String] = []
	for section: Section in sections_for(type):
		lines.append_array(section.lines)
	return lines


## Section headings in order; empty for a flat entry.
func headings_for(type: StringName) -> Array[String]:
	var headings: Array[String] = []
	for section: Section in sections_for(type):
		if not section.heading.is_empty():
			headings.append(section.heading)
	return headings


func sections_for(type: StringName) -> Array[Section]:
	var sections: Array[Section] = []
	sections.assign(_sections.get(type, []))
	return sections


## Section index for a fact in this type; facts not placed by the data go to the first.
func section_index_for(type: StringName, fact_id: StringName) -> int:
	return (_fact_sections.get(type, {}) as Dictionary).get(fact_id, 0)


## Fact ids placed by `fact_sections` for the type (for content checks).
func placed_fact_ids(type: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign((_fact_sections.get(type, {}) as Dictionary).keys())
	return ids
