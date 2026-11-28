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
		assert_gt(_filler.lines_for(type).size(), 0, "%s filler lines" % type)
	for type: StringName in [&"ticket", &"chat_log", &"meeting_notes"]:
		assert_between(_filler.lines_for(type).size(), 5, 7, "%s filler lines" % type)
	assert_between(_filler.lines_for(&"git_log").size(), 6, 8, "git_log commits")


func test_filler_missing_type_is_refused() -> void:
	assert_null(ArtifactFiller.load_from("res://tests/fixtures/artifacts/filler_missing_type.json"))
	assert_string_contains(ArtifactFiller.last_error, "meeting_notes")
	assert_push_error("meeting_notes")


func test_types_are_listed_in_spec_order() -> void:
	assert_eq(ArtifactDocument.TYPES,
		[&"ticket", &"git_log", &"chat_log", &"spec_doc", &"meeting_notes"] as Array[StringName])
	assert_eq(ArtifactDocument.display_name(&"chat_log"), "Chat log")
	assert_eq(ArtifactDocument.display_name(&"git_log"), "Git log")
	assert_eq(ArtifactDocument.display_name(&"spec_doc"), "Spec document")


func test_part1_documents_unchanged_per_seed() -> void:
	# Hashes captured from the part 1 build: reordering the list must not move facts.
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/artifacts/part1_document_hashes.json"))
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = _sheet(seed_value)
		for type: String in ["ticket", "chat_log", "meeting_notes"]:
			var doc: ArtifactDocument = ArtifactDocument.build(sheet, StringName(type), _filler)
			assert_eq("\n".join(doc.lines).md5_text(), expected[str(seed_value)][type],
				"seed %d %s" % [seed_value, type])


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


# --- part 2 content (git log, spec document) ---

func test_spec_fact_sections_name_facts_the_spec_can_hold() -> void:
	var holdable: Array[StringName] = []
	for variant: CaseTemplate.Variant in _template.variants:
		for fact: CaseTemplate.Fact in variant.chain:
			if fact.holders.has("artifact:spec_doc"):
				holdable.append(fact.id)
	for fact: CaseTemplate.Fact in _template.red_herrings:
		if fact.holders.has("artifact:spec_doc"):
			holdable.append(fact.id)
	assert_gt(_filler.placed_fact_ids(&"spec_doc").size(), 0)
	for fact_id: StringName in _filler.placed_fact_ids(&"spec_doc"):
		assert_has(holdable, fact_id, "fact_sections names %s" % fact_id)
	for fact_id: StringName in holdable:
		assert_has(_filler.placed_fact_ids(&"spec_doc"), fact_id, "%s has a section" % fact_id)


func test_spec_document_has_the_three_sections() -> void:
	assert_eq(_filler.headings_for(&"spec_doc"),
		["Revision history", "Japanese original (日本語原文)", "English translation"] as Array[String])


func test_git_log_filler_lines_are_commits() -> void:
	var commit: RegEx = RegEx.create_from_string("^[0-9a-f]{7}  \\d{4}-\\d{2}-\\d{2}  \\S+ +\\S.*$")
	for line: String in _filler.lines_for(&"git_log"):
		assert_not_null(commit.search(line), "commit form: %s" % line)


func test_git_log_shows_timezone_change_when_it_holds_it() -> void:
	var found: bool = false
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = _sheet(seed_value)
		if sheet.knowledge.get(&"rh_timezone_config", "") != "artifact:git_log":
			continue
		var doc: ArtifactDocument = ArtifactDocument.build(sheet, &"git_log", _filler)
		assert_has(doc.lines, _fact_texts(sheet)[&"rh_timezone_config"])
		found = true
	assert_true(found, "some seed gives the timezone change to the git log")
