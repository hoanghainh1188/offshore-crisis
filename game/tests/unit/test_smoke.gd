extends GutTest
## Keeps the test pipeline honest: if this fails, GUT itself is broken.


func test_gut_runs() -> void:
	assert_true(true, "GUT is wired up")
