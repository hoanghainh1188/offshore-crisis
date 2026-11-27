extends GutTest
## The shipped "Wrong Delivery" template (specs/case-generation, template content).

const PATH: String = "res://case/templates/wrong_delivery.json"

var _template: CaseTemplate


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template(PATH)


func test_shipped_template_loads() -> void:
	assert_not_null(_template)
	assert_eq(_template.id, &"wrong_delivery")


func test_has_the_three_variants() -> void:
	var ids: Array[StringName] = []
	for variant: CaseTemplate.Variant in _template.variants:
		ids.append(variant.id)
	assert_eq(ids, [&"lost_in_translation", &"chat_only_change", &"polite_yes"] as Array[StringName])


func test_has_the_five_npcs_with_attitudes() -> void:
	var ids: Array[StringName] = []
	for npc: CaseTemplate.Npc in _template.npcs:
		ids.append(npc.id)
		assert_false(npc.attitudes.is_empty(), "%s has an attitude pool" % npc.id)
	assert_eq(ids, [&"linh", &"minh", &"trang", &"hana", &"tanaka"] as Array[StringName])


func test_has_at_least_three_red_herrings() -> void:
	assert_gte(_template.red_herrings.size(), 3)


func test_variant_shape() -> void:
	for variant: CaseTemplate.Variant in _template.variants:
		assert_false(variant.description.is_empty(), "%s description" % variant.id)
		assert_between(variant.chain.size(), 2, 4, "%s chain length" % variant.id)
		assert_gte(variant.fixes.size(), 1, "%s fixes" % variant.id)
		assert_gte(variant.prevention.size(), 1, "%s prevention" % variant.id)


func test_npc_ids_match_the_office_targets() -> void:
	# Linh and Trang already exist as interactables with these ids (specs/world-interaction).
	var ids: Array[StringName] = []
	for npc: CaseTemplate.Npc in _template.npcs:
		ids.append(npc.id)
	assert_has(ids, &"linh")
	assert_has(ids, &"trang")
