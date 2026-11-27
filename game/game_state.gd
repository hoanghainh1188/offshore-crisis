extends Node
## Autoload "GameState": per-run state that must outlive screen swaps and be reachable
## from any system. Pause the clock with GameState.clock.pause(&"reason").

## Emitted once per fact, the first time it is revealed (specs/fact-discovery).
signal fact_revealed(fact_id: StringName)

const CASE_TEMPLATE_PATH: String = "res://case/templates/wrong_delivery.json"

var clock: RunClock = RunClock.new()
## The run's hidden case; null until Start (specs/run-flow).
var truth_sheet: TruthSheet = null
## Revealed fact ids in the order they were first found.
var revealed_fact_ids: Array[StringName] = []

var _template: CaseTemplate = null


func _process(delta: float) -> void:
	clock.tick(delta)


## Starts a fresh run state. Tests call this so runs do not leak into each other.
func reset_run() -> void:
	clock = RunClock.new()
	truth_sheet = null
	revealed_fact_ids = []


## Generates this run's Truth Sheet and logs only the seed.
func start_case(seed_value: int) -> void:
	if _template == null:
		_template = CaseTemplateLoader.new().load_template(CASE_TEMPLATE_PATH)
	truth_sheet = CaseGenerator.new().generate(_template, seed_value)
	revealed_fact_ids = []
	print(CaseLog.format(seed_value))


## Adds a fact to the revealed list. Returns false for repeats and for ids that are not
## in this run's Truth Sheet, which are ignored without an announcement.
func reveal_fact(fact_id: StringName) -> bool:
	if truth_sheet == null or not truth_sheet.knowledge.has(fact_id):
		return false
	if revealed_fact_ids.has(fact_id):
		return false
	revealed_fact_ids.append(fact_id)
	fact_revealed.emit(fact_id)
	return true
