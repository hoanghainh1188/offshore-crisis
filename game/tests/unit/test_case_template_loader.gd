extends GutTest
## Template validation rules from specs/case-generation ("Invalid template is refused").

const FIXTURES: String = "res://tests/fixtures/case/"

var _loader: CaseTemplateLoader


func before_each() -> void:
	_loader = CaseTemplateLoader.new()


## Loads a broken fixture and returns the error text; asserts that no template came back.
func _load_error(file: String) -> String:
	var template: CaseTemplate = _loader.load_template(FIXTURES + file)
	assert_null(template, "%s must be refused" % file)
	assert_string_contains(_loader.last_error, file, "error names the file")
	# A refused template must also reach the Godot log; asserting it keeps GUT green.
	assert_push_error(file)
	return _loader.last_error


func test_valid_minimal_template_loads_into_typed_objects() -> void:
	var template: CaseTemplate = _loader.load_template(FIXTURES + "valid_minimal.json")
	assert_not_null(template, _loader.last_error)
	assert_eq(template.id, &"fixture_case")
	assert_eq(template.npcs.size(), 2)
	assert_eq(template.npcs[0].display_name, "Ana")
	assert_eq(template.npcs[0].attitudes, [&"honest", &"defensive"] as Array[StringName])
	assert_eq(template.variants.size(), 1)
	var variant: CaseTemplate.Variant = template.variants[0]
	assert_eq(variant.chain.size(), 2)
	assert_eq(variant.chain[0].holders, ["npc:ana", "artifact:ticket"] as Array[String])
	assert_eq(variant.fixes, ["Fix it."] as Array[String])
	assert_eq(variant.prevention, ["Prevent it."] as Array[String])
	assert_eq(template.red_herrings[0].id, &"rh_one")
	assert_eq(_loader.last_error, "")


func test_missing_file_is_refused() -> void:
	assert_null(_loader.load_template(FIXTURES + "does_not_exist.json"))
	assert_string_contains(_loader.last_error, "does_not_exist.json")
	assert_push_error("does_not_exist.json")


func test_not_json_is_refused() -> void:
	_load_error("not_json.json")


func test_missing_variants_field() -> void:
	assert_string_contains(_load_error("missing_variants.json"), "variants")


func test_unknown_holder() -> void:
	var error: String = _load_error("unknown_holder.json")
	assert_string_contains(error, "fact_two")
	assert_string_contains(error, "npc:nobody")


func test_duplicate_fact_id() -> void:
	assert_string_contains(_load_error("duplicate_fact_id.json"), "fact_one")


func test_chain_too_short() -> void:
	assert_string_contains(_load_error("chain_too_short.json"), "variant_a")


func test_chain_too_long() -> void:
	assert_string_contains(_load_error("chain_too_long.json"), "variant_a")


func test_unknown_attitude() -> void:
	assert_string_contains(_load_error("unknown_attitude.json"), "grumpy")


func test_empty_red_herring_pool() -> void:
	assert_string_contains(_load_error("empty_red_herrings.json"), "red_herrings")


func test_unsolvable_variant_artifacts_only() -> void:
	assert_string_contains(_load_error("unsolvable_artifacts_only.json"), "variant_a")


func test_unsolvable_variant_single_holder() -> void:
	assert_string_contains(_load_error("unsolvable_single_holder.json"), "variant_a")


func test_error_is_cleared_after_a_good_load() -> void:
	_loader.load_template(FIXTURES + "missing_variants.json")
	assert_push_error("missing_variants.json")
	_loader.load_template(FIXTURES + "valid_minimal.json")
	assert_eq(_loader.last_error, "")
