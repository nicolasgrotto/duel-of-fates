extends TestCase

const SERVICE: GDScript = preload("res://core/save_service.gd")
const TEST_PATH: String = "user://test_progress.cfg"


func _service() -> Node:
	var service: Node = SERVICE.new()
	service.path = TEST_PATH
	service.reset()
	return service


func before_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_progress_round_trips() -> void:
	var service: Node = _service()
	service.clear_arcade(&"guardian")
	assert_true(service.record_survival(7))
	assert_false(service.record_survival(5), "a worse run is not a record")
	assert_true(service.record_challenge(&"salt_flats", 41.5))
	assert_false(service.record_challenge(&"salt_flats", 50.0))
	service.unlock("costume:guardian:traveler")
	var reloaded: Node = _service()
	reloaded.load_progress()
	assert_true(reloaded.has_cleared_arcade(&"guardian"))
	assert_eq(reloaded.survival_best, 7)
	assert_almost(reloaded.challenge_best["salt_flats"], 41.5)
	assert_true(reloaded.is_unlocked("costume:guardian:traveler"))
	service.free()
	reloaded.free()


func test_newer_format_is_ignored() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 999)
	file.set_value("progress", "survival_best", 50)
	file.save(TEST_PATH)
	var service: Node = _service()
	service.load_progress()
	assert_eq(service.survival_best, 0)
	service.free()
