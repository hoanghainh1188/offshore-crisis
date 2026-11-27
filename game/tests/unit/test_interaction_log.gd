extends GutTest
## Exact console lines from specs/world-interaction.


func test_npc_line() -> void:
	assert_eq(InteractionLog.format("npc", &"linh", "Linh"), '[interact] npc:linh "Linh"')


func test_object_line() -> void:
	assert_eq(
		InteractionLog.format("object", &"meeting_screen", "Meeting Room Screen"),
		'[interact] object:meeting_screen "Meeting Room Screen"'
	)
