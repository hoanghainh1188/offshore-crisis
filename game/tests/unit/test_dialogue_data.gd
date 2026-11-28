extends GutTest
## Dialogue data validation (specs/npc-dialogue "Dialogue content is data").

const FIXTURES: String = "res://tests/fixtures/dialogue/"

var _template: CaseTemplate


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template("res://tests/fixtures/case/valid_minimal.json")


func _load_error(file: String) -> String:
	assert_null(DialogueData.load_from(FIXTURES + file, _template), "%s must be refused" % file)
	assert_string_contains(DialogueData.last_error, file, "error names the file")
	assert_push_error(file)
	return DialogueData.last_error


func test_valid_minimal_loads() -> void:
	var data: DialogueData = DialogueData.load_from(FIXTURES + "valid_minimal.json", _template)
	assert_not_null(data, DialogueData.last_error)
	assert_true(data.has_npc(&"ana"))
	assert_false(data.has_npc(&"linh"))
	var questions: Array[DialogueData.Question] = data.questions_for(&"ana")
	assert_eq(questions.size(), 3)
	assert_eq(questions[0].id, &"ana_fact_one")
	assert_eq(questions[0].fact, &"fact_one")
	assert_eq(questions[1].fact, &"", "small talk has no fact")
	assert_eq(questions[2].unlock_any, [&"fact_one"] as Array[StringName])
	assert_eq(questions[0].holds[&"defensive"], "Fact one is true. (defensive)")
	assert_eq(DialogueData.last_error, "")


func test_unknown_npc() -> void:
	assert_string_contains(_load_error("unknown_npc.json"), "zed")


func test_unknown_fact() -> void:
	var error: String = _load_error("unknown_fact.json")
	assert_string_contains(error, "ana_fact_one")
	assert_string_contains(error, "nope")


func test_unknown_unlock_fact() -> void:
	assert_string_contains(_load_error("unknown_unlock_fact.json"), "nope_unlock")


func test_repeated_question_id() -> void:
	assert_string_contains(_load_error("repeated_question_id.json"), "ana_small")


func test_missing_attitude_answer() -> void:
	var error: String = _load_error("missing_attitude.json")
	assert_string_contains(error, "ana_fact_one")
	assert_string_contains(error, "defensive")


func test_holds_without_fact() -> void:
	assert_string_contains(_load_error("holds_without_fact.json"), "ana_small")


func test_missing_file() -> void:
	assert_null(DialogueData.load_from(FIXTURES + "nope.json", _template))
	assert_push_error("nope.json")


func test_unlock_any_must_be_a_list() -> void:
	assert_string_contains(_load_error("unlock_not_a_list.json"), "ana_follow")


func test_no_template_is_refused() -> void:
	assert_null(DialogueData.load_from(FIXTURES + "valid_minimal.json", null))
	assert_push_error("no case template")
