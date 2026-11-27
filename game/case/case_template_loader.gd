class_name CaseTemplateLoader
extends RefCounted
## Reads a case template JSON file, checks every rule in specs/case-generation
## ("Invalid template is refused"), and only then builds a typed CaseTemplate.

## Empty after a successful load; otherwise "<path>: <problem>".
var last_error: String = ""


## Returns the template, or null when the file is missing, not JSON, or breaks a rule.
func load_template(path: String) -> CaseTemplate:
	last_error = ""
	if not FileAccess.file_exists(path):
		return _fail(path, "file not found")
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail(path, "invalid JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()])
	if typeof(json.data) != TYPE_DICTIONARY:
		return _fail(path, "top level must be an object")
	var problem: String = _validate(json.data as Dictionary)
	if not problem.is_empty():
		return _fail(path, problem)
	return _build(json.data as Dictionary)


func _fail(path: String, problem: String) -> CaseTemplate:
	last_error = "%s: %s" % [path, problem]
	push_error(last_error)
	return null


# --- validation: each helper returns "" when fine, else the problem ---

func _validate(data: Dictionary) -> String:
	for key: String in ["id", "title"]:
		if not _is_text(data.get(key)):
			return "missing or empty field '%s'" % key
	for key: String in ["npcs", "variants", "red_herrings"]:
		if not data.has(key) or typeof(data[key]) != TYPE_ARRAY:
			return "missing field '%s' (must be a list)" % key
		if (data[key] as Array).is_empty():
			return "field '%s' must not be empty" % key
	var problem: String = _validate_npcs(data["npcs"] as Array)
	if not problem.is_empty():
		return problem
	var npc_ids: Array[String] = []
	for npc: Dictionary in data["npcs"]:
		npc_ids.append(npc["id"] as String)
	problem = _validate_facts(data, npc_ids)
	if not problem.is_empty():
		return problem
	return _validate_variants(data["variants"] as Array)


func _validate_npcs(npcs: Array) -> String:
	var seen: Dictionary[String, bool] = {}
	for npc: Variant in npcs:
		if typeof(npc) != TYPE_DICTIONARY:
			return "every npc must be an object"
		var entry: Dictionary = npc
		for key: String in ["id", "name", "role"]:
			if not _is_text(entry.get(key)):
				return "npc is missing field '%s'" % key
		var npc_id: String = entry["id"]
		if seen.has(npc_id):
			return "npc id '%s' is repeated" % npc_id
		seen[npc_id] = true
		if not _is_text_list(entry.get("attitudes")):
			return "npc '%s' needs a non-empty 'attitudes' list" % npc_id
		for attitude: String in entry["attitudes"]:
			if not CaseTemplate.ATTITUDES.has(StringName(attitude)):
				return "npc '%s' has unknown attitude '%s'" % [npc_id, attitude]
	return ""


func _validate_facts(data: Dictionary, npc_ids: Array[String]) -> String:
	var facts: Array = data["red_herrings"].duplicate()
	for variant: Variant in data["variants"]:
		if typeof(variant) != TYPE_DICTIONARY or typeof((variant as Dictionary).get("chain")) != TYPE_ARRAY:
			return "every variant needs a 'chain' list"
		facts.append_array((variant as Dictionary)["chain"] as Array)
	var seen: Dictionary[String, bool] = {}
	for fact: Variant in facts:
		if typeof(fact) != TYPE_DICTIONARY:
			return "every fact must be an object"
		var entry: Dictionary = fact
		if not _is_text(entry.get("id")) or not _is_text(entry.get("text")):
			return "every fact needs 'id' and 'text'"
		var fact_id: String = entry["id"]
		if seen.has(fact_id):
			return "fact id '%s' is repeated" % fact_id
		seen[fact_id] = true
		if not _is_text_list(entry.get("holders")):
			return "fact '%s' needs a non-empty 'holders' list" % fact_id
		for holder: String in entry["holders"]:
			if not _is_valid_holder(holder, npc_ids):
				return "fact '%s' has unknown holder '%s'" % [fact_id, holder]
	return ""


func _validate_variants(variants: Array) -> String:
	var seen: Dictionary[String, bool] = {}
	for variant: Dictionary in variants:
		if not _is_text(variant.get("id")) or not _is_text(variant.get("description")):
			return "every variant needs 'id' and 'description'"
		var variant_id: String = variant["id"]
		if seen.has(variant_id):
			return "variant id '%s' is repeated" % variant_id
		seen[variant_id] = true
		var chain: Array = variant["chain"]
		if chain.size() < CaseTemplate.MIN_CHAIN or chain.size() > CaseTemplate.MAX_CHAIN:
			return "variant '%s' chain has %d facts (allowed %d-%d)" % [
				variant_id, chain.size(), CaseTemplate.MIN_CHAIN, CaseTemplate.MAX_CHAIN]
		var fix_space: Variant = variant.get("fix_space")
		if typeof(fix_space) != TYPE_DICTIONARY \
				or not _is_text_list((fix_space as Dictionary).get("fixes")) \
				or not _is_text_list((fix_space as Dictionary).get("prevention")):
			return "variant '%s' needs 'fix_space' with non-empty 'fixes' and 'prevention'" % variant_id
		if not _is_solvable(chain):
			return "variant '%s' can never be solved: its chain needs an NPC holder and at least two different holders" % variant_id
	return ""


## A valid assignment exists exactly when the chain's holders, taken together, include an
## NPC and at least two different holders (CaseGenerator relies on this).
func _is_solvable(chain: Array) -> bool:
	var all_holders: Dictionary[String, bool] = {}
	for fact: Dictionary in chain:
		for holder: String in fact["holders"]:
			all_holders[holder] = true
	var has_npc: bool = all_holders.keys().any(func(h: String) -> bool: return h.begins_with("npc:"))
	return has_npc and all_holders.size() >= 2


func _is_valid_holder(holder: String, npc_ids: Array[String]) -> bool:
	if holder.begins_with("npc:"):
		return npc_ids.has(holder.trim_prefix("npc:"))
	if holder.begins_with("artifact:"):
		return CaseTemplate.ARTIFACT_TYPES.has(StringName(holder.trim_prefix("artifact:")))
	return false


func _is_text(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not (value as String).strip_edges().is_empty()


func _is_text_list(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY or (value as Array).is_empty():
		return false
	return (value as Array).all(func(item: Variant) -> bool: return _is_text(item))


# --- building typed objects (only after validation passed) ---

func _build(data: Dictionary) -> CaseTemplate:
	var template: CaseTemplate = CaseTemplate.new()
	template.id = StringName(data["id"] as String)
	template.title = data["title"]
	for entry: Dictionary in data["npcs"]:
		var npc: CaseTemplate.Npc = CaseTemplate.Npc.new()
		npc.id = StringName(entry["id"] as String)
		npc.display_name = entry["name"]
		npc.role = entry["role"]
		for attitude: String in entry["attitudes"]:
			npc.attitudes.append(StringName(attitude))
		template.npcs.append(npc)
	for entry: Dictionary in data["variants"]:
		var variant: CaseTemplate.Variant = CaseTemplate.Variant.new()
		variant.id = StringName(entry["id"] as String)
		variant.description = entry["description"]
		for fact: Dictionary in entry["chain"]:
			variant.chain.append(_build_fact(fact))
		variant.fixes.assign(entry["fix_space"]["fixes"])
		variant.prevention.assign(entry["fix_space"]["prevention"])
		template.variants.append(variant)
	for fact: Dictionary in data["red_herrings"]:
		template.red_herrings.append(_build_fact(fact))
	return template


func _build_fact(entry: Dictionary) -> CaseTemplate.Fact:
	var fact: CaseTemplate.Fact = CaseTemplate.Fact.new()
	fact.id = StringName(entry["id"] as String)
	fact.text = entry["text"]
	fact.holders.assign(entry["holders"])
	return fact
