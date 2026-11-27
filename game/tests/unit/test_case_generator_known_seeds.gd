extends GutTest
## Pins the case for two seeds. If this fails after a change to CaseGenerator's draw order
## or to wrong_delivery.json, every seed now gives a different case: update the expected
## values on purpose and say so in the change notes (old playtest seeds stop matching).

var _template: CaseTemplate


func before_all() -> void:
	_template = CaseTemplateLoader.new().load_template("res://case/templates/wrong_delivery.json")


func test_seed_42() -> void:
	var sheet: TruthSheet = CaseGenerator.new().generate(_template, 42)
	assert_eq(sheet.root_cause_id, &"polite_yes")
	assert_eq(sheet.knowledge, {
		&"fact_py_meeting_proposal": "artifact:meeting_notes",
		&"fact_py_hai_recorded": "artifact:meeting_notes",
		&"fact_py_check_internally": "npc:tanaka",
		&"rh_late_regression_run": "artifact:chat_log",
		&"rh_junior_null_fix": "artifact:git_log",
	} as Dictionary[StringName, String])
	assert_eq(_ids(sheet.red_herrings), [&"rh_late_regression_run", &"rh_junior_null_fix"] as Array[StringName])
	assert_eq(sheet.attitudes, {
		&"linh": &"honest", &"minh": &"nervous", &"trang": &"honest",
		&"hana": &"honest", &"tanaka": &"indirect",
	} as Dictionary[StringName, StringName])


func test_seed_1234() -> void:
	var sheet: TruthSheet = CaseGenerator.new().generate(_template, 1234)
	assert_eq(sheet.root_cause_id, &"lost_in_translation")
	assert_eq(sheet.knowledge, {
		&"fact_lit_ticket_calendar": "npc:linh",
		&"fact_lit_jp_spec_closing": "npc:hana",
		&"fact_lit_unconfirmed_note": "artifact:chat_log",
		&"rh_late_regression_run": "npc:trang",
	} as Dictionary[StringName, String])
	assert_eq(_ids(sheet.red_herrings), [&"rh_late_regression_run"] as Array[StringName])
	assert_eq(sheet.attitudes, {
		&"linh": &"defensive", &"minh": &"nervous", &"trang": &"honest",
		&"hana": &"protective", &"tanaka": &"indirect",
	} as Dictionary[StringName, StringName])


func _ids(facts: Array[CaseTemplate.Fact]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for fact: CaseTemplate.Fact in facts:
		ids.append(fact.id)
	return ids
