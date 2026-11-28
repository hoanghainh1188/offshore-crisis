extends GutTest
## Document content rules from specs/artifact-viewer, checked over many cases.

const FILLER_PATH: String = "res://artifacts/artifact_filler.json"
const SEEDS: int = 300

var _template: CaseTemplate
var _filler: ArtifactFiller


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template(GameState.CASE_TEMPLATE_PATH)
	_filler = ArtifactFiller.load_from(FILLER_PATH)


func _sheet(seed_value: int) -> TruthSheet:
	return CaseGenerator.new().generate(_template, seed_value)


## Every fact of the sheet with its text, keyed by id.
func _fact_texts(sheet: TruthSheet) -> Dictionary[StringName, String]:
	var texts: Dictionary[StringName, String] = {}
	for fact: CaseTemplate.Fact in sheet.chain + sheet.red_herrings:
		texts[fact.id] = fact.text
	return texts


# --- filler data ---

func test_filler_has_every_supported_type() -> void:
	assert_not_null(_filler, ArtifactFiller.last_error)
	for type: StringName in ArtifactDocument.TYPES:
		assert_false(_filler.title_for(type).is_empty(), "%s title" % type)
		assert_between(_filler.lines_for(type).size(), 5, 7, "%s filler lines" % type)


func test_filler_missing_type_is_refused() -> void:
	assert_null(ArtifactFiller.load_from("res://tests/fixtures/artifacts/filler_missing_type.json"))
	assert_string_contains(ArtifactFiller.last_error, "meeting_notes")
	assert_push_error("meeting_notes")


func test_types_are_listed_in_spec_order() -> void:
	assert_eq(ArtifactDocument.TYPES, [&"ticket", &"chat_log", &"meeting_notes"] as Array[StringName])
	assert_eq(ArtifactDocument.display_name(&"chat_log"), "Chat log")


# --- document content ---

func test_shows_exactly_the_facts_this_artifact_holds() -> void:
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = _sheet(seed_value)
		var texts: Dictionary[StringName, String] = _fact_texts(sheet)
		for type: StringName in ArtifactDocument.TYPES:
			var doc: ArtifactDocument = ArtifactDocument.build(sheet, type, _filler)
			var holder: String = "artifact:%s" % type
			for fact_id: StringName in sheet.knowledge:
				var held_here: bool = sheet.knowledge[fact_id] == holder
				assert_eq(doc.lines.has(texts[fact_id]), held_here,
					"seed %d %s fact %s" % [seed_value, type, fact_id])
				assert_eq(doc.fact_ids.has(fact_id), held_here)


func test_filler_lines_are_all_present_in_order() -> void:
	var sheet: TruthSheet = _sheet(7)
	for type: StringName in ArtifactDocument.TYPES:
		var doc: ArtifactDocument = ArtifactDocument.build(sheet, type, _filler)
		var filler_only: Array[String] = []
		for line: String in doc.lines:
			if _filler.lines_for(type).has(line):
				filler_only.append(line)
		assert_eq(filler_only, _filler.lines_for(type), "%s keeps filler order" % type)
		assert_eq(doc.title, _filler.title_for(type))


func test_artifact_with_no_facts_is_filler_only() -> void:
	var found: bool = false
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = _sheet(seed_value)
		if sheet.knowledge.values().has("artifact:meeting_notes"):
			continue
		var doc: ArtifactDocument = ArtifactDocument.build(sheet, &"meeting_notes", _filler)
		assert_eq(doc.lines, _filler.lines_for(&"meeting_notes"))
		assert_eq(doc.fact_ids.size(), 0)
		found = true
		break
	assert_true(found, "some seed leaves meeting notes empty")


func test_same_sheet_same_document() -> void:
	var sheet: TruthSheet = _sheet(42)
	for type: StringName in ArtifactDocument.TYPES:
		var first: ArtifactDocument = ArtifactDocument.build(sheet, type, _filler)
		var second: ArtifactDocument = ArtifactDocument.build(sheet, type, _filler)
		assert_eq(first.lines, second.lines)
		assert_eq(first.fact_ids, second.fact_ids)


func test_facts_are_not_always_at_the_same_place() -> void:
	# Mixing must vary between runs, or players learn "line 1 is the clue".
	var positions: Dictionary[int, bool] = {}
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = _sheet(seed_value)
		var doc: ArtifactDocument = ArtifactDocument.build(sheet, &"chat_log", _filler)
		if doc.fact_ids.is_empty():
			continue
		var first_fact: String = _fact_texts(sheet)[doc.fact_ids[0]]
		positions[doc.lines.find(first_fact)] = true
	assert_gt(positions.size(), 3)
