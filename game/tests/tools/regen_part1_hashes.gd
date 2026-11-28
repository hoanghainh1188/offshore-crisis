extends SceneTree
## Rewrites tests/fixtures/artifacts/part1_document_hashes.json from the current build.
## Run only when part 1 document text (ticket, chat log, meeting notes filler or fact text)
## is changed on purpose; otherwise the fixture guards against accidental changes.
##   godot --headless --path game -s res://tests/tools/regen_part1_hashes.gd

const TEMPLATE_PATH: String = "res://case/templates/wrong_delivery.json"
const FILLER_PATH: String = "res://artifacts/artifact_filler.json"
const OUT_PATH: String = "res://tests/fixtures/artifacts/part1_document_hashes.json"
const SEEDS: int = 300
const PART1_TYPES: Array[StringName] = [&"ticket", &"chat_log", &"meeting_notes"]


func _init() -> void:
	var template: CaseTemplate = CaseTemplateLoader.new().load_template(TEMPLATE_PATH)
	var filler: ArtifactFiller = ArtifactFiller.load_from(FILLER_PATH)
	if template == null or filler == null:
		push_error("regen_part1_hashes: could not load template or filler")
		quit(1)
		return
	var out: Dictionary = {}
	for seed_value: int in range(1, SEEDS + 1):
		var sheet: TruthSheet = CaseGenerator.new().generate(template, seed_value)
		var row: Dictionary = {}
		for type: StringName in PART1_TYPES:
			row[String(type)] = "\n".join(ArtifactDocument.build(sheet, type, filler).lines).md5_text()
		out[str(seed_value)] = row
	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(out, " ", true) + "\n")
	file.close()
	print("regen_part1_hashes: wrote %d seeds to %s" % [SEEDS, OUT_PATH])
	quit(0)
