class_name CaseGenerator
extends RefCounted
## Turns a validated CaseTemplate and a seed into a TruthSheet (specs/case-generation).
##
## Determinism: a local RandomNumberGenerator only, and draws always happen in this order:
##   1. variant  2. holder per chain fact (redrawn if unsolvable)  3. red herring count
##   4. red herrings  5. holder per red herring  6. attitude per NPC (template order)
## Changing the order changes the case for every seed; test_case_generator_known_seeds
## pins two seeds so such a change is always deliberate.

## Random redraws of the chain holders before falling back to a fixed valid assignment.
const MAX_REDRAWS: int = 20


func generate(template: CaseTemplate, seed_value: int) -> TruthSheet:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var variant: CaseTemplate.Variant = template.variants[rng.randi_range(0, template.variants.size() - 1)]

	var sheet: TruthSheet = TruthSheet.new()
	sheet.seed = seed_value
	sheet.template_id = template.id
	sheet.root_cause_id = variant.id
	sheet.root_cause_description = variant.description
	sheet.chain = variant.chain.duplicate()
	sheet.fixes = variant.fixes.duplicate()
	sheet.prevention = variant.prevention.duplicate()

	var chain_holders: Array[String] = _draw_chain_holders(variant.chain, rng)
	for i: int in variant.chain.size():
		sheet.knowledge[variant.chain[i].id] = chain_holders[i]

	sheet.red_herrings = _draw_red_herrings(template.red_herrings, rng)
	for herring: CaseTemplate.Fact in sheet.red_herrings:
		sheet.knowledge[herring.id] = _pick(herring.holders, rng)

	for npc: CaseTemplate.Npc in template.npcs:
		sheet.attitudes[npc.id] = npc.attitudes[rng.randi_range(0, npc.attitudes.size() - 1)]
	return sheet


func _draw_chain_holders(chain: Array[CaseTemplate.Fact], rng: RandomNumberGenerator) -> Array[String]:
	for attempt: int in MAX_REDRAWS:
		var holders: Array[String] = []
		for fact: CaseTemplate.Fact in chain:
			holders.append(_pick(fact.holders, rng))
		if is_solvable(holders):
			return holders
	return _fallback_holders(chain)


## Spec "Case is solvable": at least two different holders, at least one of them an NPC.
static func is_solvable(holders: Array[String]) -> bool:
	var distinct: Dictionary[String, bool] = {}
	for holder: String in holders:
		distinct[holder] = true
	var has_npc: bool = holders.any(func(h: String) -> bool: return h.begins_with("npc:"))
	return has_npc and distinct.size() >= 2


## Fixed valid assignment. The loader only accepts chains whose holders together include an
## NPC and two different holders, which is exactly what makes this always succeed.
func _fallback_holders(chain: Array[CaseTemplate.Fact]) -> Array[String]:
	var holders: Array[String] = []
	var npc_index: int = -1
	var npc_holder: String = ""
	for i: int in chain.size():
		holders.append(chain[i].holders[0])
		if npc_index == -1:
			for holder: String in chain[i].holders:
				if holder.begins_with("npc:"):
					npc_index = i
					npc_holder = holder
					break
	holders[npc_index] = npc_holder
	if is_solvable(holders):
		return holders
	# Every fact now sits with npc_holder: move one fact to any other holder it allows.
	for i: int in chain.size():
		if i == npc_index:
			continue
		for holder: String in chain[i].holders:
			if holder != npc_holder:
				holders[i] = holder
				return holders
	for holder: String in chain[npc_index].holders:
		if holder != npc_holder:
			holders[npc_index] = holder
			break
	return holders


func _draw_red_herrings(pool: Array[CaseTemplate.Fact], rng: RandomNumberGenerator) -> Array[CaseTemplate.Fact]:
	var count: int = mini(rng.randi_range(1, 2), pool.size())
	var remaining: Array[CaseTemplate.Fact] = pool.duplicate()
	var chosen: Array[CaseTemplate.Fact] = []
	for i: int in count:
		chosen.append(remaining.pop_at(rng.randi_range(0, remaining.size() - 1)))
	return chosen


func _pick(options: Array[String], rng: RandomNumberGenerator) -> String:
	return options[rng.randi_range(0, options.size() - 1)]
