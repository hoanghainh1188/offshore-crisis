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
## Question ids asked this run; asking one again is free (specs/npc-dialogue).
var asked_question_ids: Array[StringName] = []
## Pins and links on the clue board; read by later screens, never scored (specs/clue-board).
var clue_board: ClueBoardState = ClueBoardState.new()
var dialogue_tuning: DialogueTuning = preload("res://dialogue/dialogue_tuning.tres")

var _template: CaseTemplate = null


func _process(delta: float) -> void:
	clock.tick(delta)


## Starts a fresh run state. Tests call this so runs do not leak into each other.
func reset_run() -> void:
	clock = RunClock.new()
	truth_sheet = null
	revealed_fact_ids = []
	asked_question_ids = []
	clue_board = ClueBoardState.new()


## Generates this run's Truth Sheet and logs only the seed.
func start_case(seed_value: int) -> void:
	truth_sheet = CaseGenerator.new().generate(case_template(), seed_value)
	revealed_fact_ids = []
	asked_question_ids = []
	clue_board = ClueBoardState.new()
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


## The "Wrong Delivery" template, loaded once (NPC names, roles and fact ids).
func case_template() -> CaseTemplate:
	if _template == null:
		_template = CaseTemplateLoader.new().load_template(CASE_TEMPLATE_PATH)
	return _template


func is_asked(question_id: StringName) -> bool:
	return asked_question_ids.has(question_id)


## Asks an NPC a question. The first time in a run it reveals the answer's fact (if any)
## and then costs in-game time; reveal comes first so a question that ends the day still
## counts what was learned. Asking again returns the same answer for free.
func ask_question(npc_id: StringName, question: DialogueData.Question) -> DialogueAnswer:
	var answer: DialogueAnswer = DialogueRules.answer(question, npc_id, truth_sheet)
	if is_asked(question.id):
		return answer
	asked_question_ids.append(question.id)
	if answer.reveals != &"":
		reveal_fact(answer.reveals)
	clock.advance_minutes(dialogue_tuning.cost_for(npc_id))
	return answer
