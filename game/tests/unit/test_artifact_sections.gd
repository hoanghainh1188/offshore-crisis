extends GutTest
## Sections in filler data and documents (specs/artifact-viewer: Spec document sections).

const SHIPPED_PATH: String = "res://artifacts/artifact_filler.json"
const TEST_PATH: String = "user://test_filler_sections.json"
const SEEDS: int = 300

var _template: CaseTemplate


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template(GameState.CASE_TEMPLATE_PATH)


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


## Shipped flat entries plus a sectioned spec_doc that the tests control.
func _base() -> Dictionary:
	var data: Dictionary = {}
	for type: String in ["ticket", "chat_log", "meeting_notes"]:
		data[type] = {"title": "T " + type, "lines": ["%s one" % type, "%s two" % type, "%s three" % type]}
	data["git_log"] = {"title": "Git", "lines": ["c1", "c2", "c3", "c4"]}
	data["spec_doc"] = {
		"title": "Spec",
		"sections": [
			{"id": "revisions", "heading": "Revision history", "lines": ["r1", "r2"]},
			{"id": "jp", "heading": "Japanese original", "lines": ["j1", "j2", "j3"]},
			{"id": "en", "heading": "English translation", "lines": ["e1", "e2"]},
		],
		"fact_sections": {"fact_coc_spec_unchanged": "revisions", "fact_lit_jp_spec_closing": "jp"},
	}
	return data


func _load(data: Dictionary) -> ArtifactFiller:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	return ArtifactFiller.load_from(TEST_PATH)


func _expect_refused(data: Dictionary, problem: String) -> void:
	assert_null(_load(data), problem)
	assert_string_contains(ArtifactFiller.last_error, TEST_PATH)
	assert_string_contains(ArtifactFiller.last_error, problem)
	assert_push_error(problem)


## Seeds where the spec document holds the given fact.
func _sheets_where_spec_holds(fact_id: StringName) -> Array[TruthSheet]:
	var sheets: Array[TruthSheet] = []
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = CaseGenerator.new().generate(_template, seed_value)
		if sheet.knowledge.get(fact_id, "") == "artifact:spec_doc":
			sheets.append(sheet)
	return sheets


func _text(sheet: TruthSheet, fact_id: StringName) -> String:
	for fact: CaseTemplate.Fact in sheet.chain + sheet.red_herrings:
		if fact.id == fact_id:
			return fact.text
	return ""


# --- loader ---

func test_sectioned_entry_loads() -> void:
	var filler: ArtifactFiller = _load(_base())
	assert_not_null(filler, ArtifactFiller.last_error)
	assert_eq(filler.lines_for(&"spec_doc"), ["r1", "r2", "j1", "j2", "j3", "e1", "e2"] as Array[String])
	assert_eq(filler.headings_for(&"spec_doc"),
		["Revision history", "Japanese original", "English translation"] as Array[String])
	assert_eq(filler.headings_for(&"ticket"), [] as Array[String])


func test_missing_heading_is_refused() -> void:
	var data: Dictionary = _base()
	data["spec_doc"]["sections"][1].erase("heading")
	_expect_refused(data, "section 'jp' needs a 'heading'")


func test_section_without_lines_is_refused() -> void:
	var data: Dictionary = _base()
	data["spec_doc"]["sections"][2]["lines"] = []
	_expect_refused(data, "section 'en' needs a non-empty 'lines' list")


func test_duplicate_section_id_is_refused() -> void:
	var data: Dictionary = _base()
	data["spec_doc"]["sections"][2]["id"] = "jp"
	_expect_refused(data, "repeats section id 'jp'")


func test_lines_and_sections_together_are_refused() -> void:
	var data: Dictionary = _base()
	data["spec_doc"]["lines"] = ["x"]
	_expect_refused(data, "needs either 'lines' or 'sections', not both")


func test_unknown_fact_section_is_refused() -> void:
	var data: Dictionary = _base()
	data["spec_doc"]["fact_sections"]["fact_lit_jp_spec_closing"] = "appendix"
	_expect_refused(data, "fact 'fact_lit_jp_spec_closing' goes to unknown section 'appendix'")


# --- builder ---

func test_headings_come_out_in_order() -> void:
	var filler: ArtifactFiller = _load(_base())
	var sheet: TruthSheet = CaseGenerator.new().generate(_template, 5)
	var doc: ArtifactDocument = ArtifactDocument.build(sheet, &"spec_doc", filler)
	assert_eq(doc.headings, ["Revision history", "Japanese original", "English translation"] as Array[String])
	var at: Array[int] = []
	for heading: String in doc.headings:
		at.append(doc.lines.find(heading))
	assert_eq(at[0], 0, "document starts with the first heading")
	assert_lt(at[0], at[1])
	assert_lt(at[1], at[2])


func test_facts_land_in_their_assigned_section() -> void:
	var filler: ArtifactFiller = _load(_base())
	var cases: Dictionary = {&"fact_coc_spec_unchanged": [0, 1], &"fact_lit_jp_spec_closing": [1, 2]}
	for fact_id: StringName in cases:
		var sheets: Array[TruthSheet] = _sheets_where_spec_holds(fact_id)
		assert_gt(sheets.size(), 0, "some seed gives %s to the spec" % fact_id)
		for sheet: TruthSheet in sheets:
			var doc: ArtifactDocument = ArtifactDocument.build(sheet, &"spec_doc", filler)
			var line: int = doc.lines.find(_text(sheet, fact_id))
			var after: int = doc.lines.find(doc.headings[cases[fact_id][0]])
			var before: int = doc.lines.find(doc.headings[cases[fact_id][1]])
			assert_between(line, after + 1, before - 1, "seed %d %s" % [sheet.seed, fact_id])
			assert_true(doc.fact_ids.has(fact_id))


func test_unassigned_fact_goes_to_first_section() -> void:
	var data: Dictionary = _base()
	(data["spec_doc"]["fact_sections"] as Dictionary).erase("fact_lit_jp_spec_closing")
	var filler: ArtifactFiller = _load(data)
	var sheets: Array[TruthSheet] = _sheets_where_spec_holds(&"fact_lit_jp_spec_closing")
	for sheet: TruthSheet in sheets:
		var doc: ArtifactDocument = ArtifactDocument.build(sheet, &"spec_doc", filler)
		var line: int = doc.lines.find(_text(sheet, &"fact_lit_jp_spec_closing"))
		assert_between(line, 1, doc.lines.find(doc.headings[1]) - 1, "seed %d" % sheet.seed)


func test_same_sheet_same_sections() -> void:
	var filler: ArtifactFiller = _load(_base())
	var sheet: TruthSheet = _sheets_where_spec_holds(&"fact_coc_spec_unchanged")[0]
	var first: ArtifactDocument = ArtifactDocument.build(sheet, &"spec_doc", filler)
	var second: ArtifactDocument = ArtifactDocument.build(sheet, &"spec_doc", filler)
	assert_eq(first.lines, second.lines)
	assert_eq(first.fact_ids, second.fact_ids)


func test_flat_document_has_no_headings() -> void:
	var filler: ArtifactFiller = _load(_base())
	var sheet: TruthSheet = CaseGenerator.new().generate(_template, 5)
	assert_eq(ArtifactDocument.build(sheet, &"ticket", filler).headings, [] as Array[String])


func test_flat_entry_with_fact_sections_is_refused() -> void:
	var data: Dictionary = _base()
	data["git_log"]["fact_sections"] = {"rh_timezone_config": "x"}
	_expect_refused(data, "has 'fact_sections' but no 'sections'")


func test_entry_without_lines_or_sections_is_refused() -> void:
	var data: Dictionary = _base()
	(data["git_log"] as Dictionary).erase("lines")
	_expect_refused(data, "needs a non-empty 'lines' or 'sections' list")
