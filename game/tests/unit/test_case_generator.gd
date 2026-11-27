extends GutTest
## Truth Sheet rules from specs/case-generation, checked over many seeds.

const TEMPLATE_PATH: String = "res://case/templates/wrong_delivery.json"
const SEEDS: int = 300

var _template: CaseTemplate
var _generator: CaseGenerator = CaseGenerator.new()


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template(TEMPLATE_PATH)


func _sheets() -> Array[TruthSheet]:
	var sheets: Array[TruthSheet] = []
	for seed_value: int in range(1, SEEDS + 1):
		sheets.append(_generator.generate(_template, seed_value))
	return sheets


func _allowed_holders(sheet: TruthSheet, fact_id: StringName) -> Array[String]:
	var facts: Array[CaseTemplate.Fact] = sheet.chain + sheet.red_herrings
	for fact: CaseTemplate.Fact in facts:
		if fact.id == fact_id:
			return fact.holders
	return []


# --- TruthSheet ---

func test_truth_sheet_to_dict_has_every_field() -> void:
	var data: Dictionary = _generator.generate(_template, 7).to_dict()
	for key: String in ["seed", "template_id", "root_cause", "chain", "knowledge",
			"attitudes", "red_herrings", "fix_space"]:
		assert_has(data, key)
	assert_has(data["root_cause"], "id")
	assert_has(data["root_cause"], "description")
	assert_has(data["fix_space"], "fixes")
	assert_has(data["fix_space"], "prevention")


# --- Truth Sheet content ---

func test_complete_truth_sheet_for_every_seed() -> void:
	for sheet: TruthSheet in _sheets():
		var variant: CaseTemplate.Variant = _template.find_variant(sheet.root_cause_id)
		assert_not_null(variant, "seed %d root cause" % sheet.seed)
		assert_eq(sheet.root_cause_description, variant.description)
		assert_eq(sheet.chain, variant.chain, "chain in template order")
		assert_between(sheet.red_herrings.size(), 1, 2, "seed %d red herrings" % sheet.seed)
		assert_eq(sheet.knowledge.size(), sheet.chain.size() + sheet.red_herrings.size(),
			"one holder per chain fact and red herring")
		assert_eq(sheet.attitudes.size(), 5, "attitude for each NPC")
		assert_eq(sheet.fixes, variant.fixes)
		assert_eq(sheet.prevention, variant.prevention)


func test_holders_come_from_the_template() -> void:
	for sheet: TruthSheet in _sheets():
		for fact_id: StringName in sheet.knowledge:
			assert_has(_allowed_holders(sheet, fact_id), sheet.knowledge[fact_id],
				"seed %d fact %s" % [sheet.seed, fact_id])


func test_attitudes_come_from_npc_pools() -> void:
	for sheet: TruthSheet in _sheets():
		for npc: CaseTemplate.Npc in _template.npcs:
			assert_has(npc.attitudes, sheet.attitudes[npc.id], "seed %d %s" % [sheet.seed, npc.id])


func test_red_herrings_are_distinct_and_not_in_the_chain() -> void:
	for sheet: TruthSheet in _sheets():
		var chain_ids: Array[StringName] = []
		for fact: CaseTemplate.Fact in sheet.chain:
			chain_ids.append(fact.id)
		var seen: Array[StringName] = []
		for herring: CaseTemplate.Fact in sheet.red_herrings:
			assert_does_not_have(chain_ids, herring.id)
			assert_does_not_have(seen, herring.id, "seed %d duplicate herring" % sheet.seed)
			seen.append(herring.id)


func test_both_red_herring_counts_happen() -> void:
	var counts: Dictionary[int, bool] = {}
	for sheet: TruthSheet in _sheets():
		counts[sheet.red_herrings.size()] = true
	assert_eq(counts.keys().size(), 2, "1 and 2 red herrings both occur")


# --- Case is solvable ---

func test_chain_is_spread_and_has_an_npc() -> void:
	for sheet: TruthSheet in _sheets():
		var holders: Dictionary[String, bool] = {}
		for fact: CaseTemplate.Fact in sheet.chain:
			holders[sheet.knowledge[fact.id]] = true
		assert_gte(holders.size(), 2, "seed %d chain holders" % sheet.seed)
		assert_true(holders.keys().any(func(h: String) -> bool: return h.begins_with("npc:")),
			"seed %d has an NPC holder" % sheet.seed)


func test_only_the_solvable_assignment_is_ever_returned() -> void:
	# Only one assignment is solvable and most random draws miss it; whether it comes from a
	# redraw or the fallback, it must always be that one. Fallback branches are tested directly
	# in test_fallback_covers_every_branch.
	var template: CaseTemplate = CaseTemplateLoader.new().load_template(
		"res://tests/fixtures/case/valid_minimal.json")
	var fact_a: CaseTemplate.Fact = template.variants[0].chain[0]
	var fact_b: CaseTemplate.Fact = template.variants[0].chain[1]
	fact_a.holders.assign(["npc:ana"])
	fact_b.holders.assign(["npc:ana", "npc:ana", "npc:ana", "npc:ana", "artifact:ticket"])
	for seed_value: int in range(1, 101):
		var sheet: TruthSheet = _generator.generate(template, seed_value)
		assert_eq(sheet.knowledge[&"fact_two"], "artifact:ticket", "seed %d" % seed_value)


func _chain(holder_lists: Array) -> Array[CaseTemplate.Fact]:
	var chain: Array[CaseTemplate.Fact] = []
	for holders: Array in holder_lists:
		var fact: CaseTemplate.Fact = CaseTemplate.Fact.new()
		fact.holders.assign(holders)
		chain.append(fact)
	return chain


func test_fallback_covers_every_branch() -> void:
	# First guess already valid.
	var a: Array[String] = _generator._fallback_holders(_chain([["npc:x"], ["artifact:ticket"]]))
	assert_true(CaseGenerator.is_solvable(a), str(a))
	# All on the NPC: another fact moves away.
	var b: Array[String] = _generator._fallback_holders(_chain([["npc:x"], ["npc:x", "artifact:ticket"]]))
	assert_eq(b, ["npc:x", "artifact:ticket"] as Array[String])
	# Only the NPC fact itself can move.
	var c: Array[String] = _generator._fallback_holders(_chain([["artifact:ticket", "npc:x"], ["npc:x"]]))
	assert_eq(c, ["artifact:ticket", "npc:x"] as Array[String])


# --- Generation is seedable ---

func test_same_seed_same_case() -> void:
	var first: Dictionary = _generator.generate(_template, 42).to_dict()
	var second: Dictionary = CaseGenerator.new().generate(_template, 42).to_dict()
	assert_eq(JSON.stringify(first, "", true), JSON.stringify(second, "", true))


func test_seed_is_recorded() -> void:
	assert_eq(_generator.generate(_template, 42).seed, 42)


func test_all_variants_reachable() -> void:
	var chosen: Dictionary[StringName, int] = {}
	for sheet: TruthSheet in _sheets():
		chosen[sheet.root_cause_id] = chosen.get(sheet.root_cause_id, 0) + 1
	for variant: CaseTemplate.Variant in _template.variants:
		assert_gt(chosen.get(variant.id, 0), 0, "%s chosen at least once" % variant.id)


func test_global_rng_does_not_change_the_case() -> void:
	var before: String = JSON.stringify(_generator.generate(_template, 99).to_dict())
	seed(12345)
	randi()
	var after: String = JSON.stringify(_generator.generate(_template, 99).to_dict())
	assert_eq(before, after)
