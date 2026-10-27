extends TestCase

const SERVICE: GDScript = preload("res://core/save_service.gd")
const TEST_PATH: String = "user://test_infiltration_progress.cfg"
const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")


func before_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_completion_merges_bonuses_and_retains_best_time_after_reload() -> void:
	var service: Node = SERVICE.new()
	service.path = TEST_PATH
	assert_true(service.record_infiltration(&"mission", 1200, 1))
	assert_false(service.record_infiltration(&"mission", 1400, 1))
	assert_true(service.record_infiltration(&"mission", 1500, 2))
	assert_true(service.record_infiltration(&"mission", 1000, 4))
	var reloaded: Node = SERVICE.new()
	reloaded.path = TEST_PATH
	reloaded.load_progress()
	assert_eq(reloaded.infiltration_best.mission.ticks, 1000)
	assert_eq(reloaded.infiltration_best.mission.bonuses, 7)
	assert_false(service.record_infiltration(&"invalid", 0, 7))
	service.free()
	reloaded.free()


func test_old_save_retains_campaign_and_unlocks_with_empty_infiltration() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "campaign", {"encounter": 4})
	file.set_value("progress", "unlocked", {"ending:any": true})
	file.set_value("progress", "hunt_best", {"last_lesson": 45.0})
	file.save(TEST_PATH)
	var service: Node = SERVICE.new()
	service.path = TEST_PATH
	service.load_progress()
	assert_true(service.infiltration_best.is_empty())
	assert_eq(service.campaign.encounter, 4)
	assert_true(service.is_unlocked("ending:any"))
	assert_eq(service.hunt_best.last_lesson, 45.0)
	service.free()


func test_mode_never_records_active_or_failed_attempt_and_seals_success() -> void:
	var path: String = SaveService.path
	var records: Dictionary = SaveService.infiltration_best
	SaveService.path = TEST_PATH
	SaveService.infiltration_best = {}
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[0]
	var mode: InfiltrationMode = InfiltrationMode.new(data)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, data.map, data)
	mode.finish(sim)
	assert_true(mode.result.is_empty())
	assert_true(SaveService.infiltration_best.is_empty())
	sim.player.health = 0.0
	sim.step(InfiltrationIntent.new())
	mode.finish(sim)
	assert_true(SaveService.infiltration_best.is_empty())
	mode = InfiltrationMode.new(data)
	sim = InfiltrationSimulation.new(CONFIG, data.map, data)
	sim.panels[0].disabled = true
	sim.player.position = data.extraction
	sim.step(InfiltrationIntent.new())
	mode.finish(sim)
	assert_eq(SaveService.infiltration_best[String(data.id)].ticks, 1)
	var result: Dictionary = mode.result.duplicate(true)
	sim.mission.finished_tick = 300
	mode.finish(sim)
	assert_eq(mode.result, result)
	SaveService.path = path
	SaveService.infiltration_best = records
