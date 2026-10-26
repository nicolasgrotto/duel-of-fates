extends TestCase

const SERVICE: GDScript = preload("res://core/save_service.gd")
const TEST_PATH: String = "user://test_hunt_progress.cfg"


func _service() -> Node:
	var service: Node = SERVICE.new()
	service.path = TEST_PATH
	service.reset()
	return service


func before_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_hunt_completion_best_time_and_unlocks_persist_once() -> void:
	var service: Node = _service()
	for hunt in HuntMode.HUNTS:
		assert_true(service.record_hunt(hunt.id, 61.5))
		assert_false(service.record_hunt(hunt.id, 61.5))
		assert_false(service.record_hunt(hunt.id, 70.0))
		assert_true(service.record_hunt(hunt.id, 48.25))
		for key in hunt.unlocks:
			assert_true(service.unlock(key))
			assert_false(service.unlock(key))
	var reloaded: Node = _service()
	reloaded.load_progress()
	for hunt in HuntMode.HUNTS:
		assert_almost(reloaded.hunt_best[String(hunt.id)], 48.25)
		for key in hunt.unlocks:
			assert_true(reloaded.is_unlocked(key))
	service.free()
	reloaded.free()


func test_old_progress_without_hunts_keeps_existing_unlocks() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "survival_best", 8)
	file.set_value("progress", "unlocked", {"character:elder": true})
	file.save(TEST_PATH)
	var service: Node = _service()
	service.load_progress()
	assert_true(service.hunt_best.is_empty())
	assert_eq(service.survival_best, 8)
	assert_true(service.is_unlocked("character:elder"))
	service.free()


func test_mode_requires_victory_and_condition_and_seals_rewards_per_attempt() -> void:
	var saved_path: String = SaveService.path
	var saved_hunts: Dictionary = SaveService.hunt_best
	var saved_unlocks: Dictionary = SaveService.unlocked
	SaveService.path = TEST_PATH
	SaveService.hunt_best = {}
	SaveService.unlocked = {}
	for hunt in HuntMode.HUNTS:
		var mode: HuntMode = HuntMode.new(hunt)
		mode.build_setup()
		mode.tracker.perfect_parries = 0
		mode.tracker.fight_ticks = Ticks.from_seconds(hunt.condition.seconds) + 1
		mode.finish(0, null, 0.0)
		assert_false(mode.won)
		assert_false(SaveService.hunt_best.has(String(hunt.id)))
		mode.build_setup()
		mode.tracker.perfect_parries = hunt.condition.count
		mode.tracker.fight_ticks = 1200
		mode.tracker.survived_singularity = true
		mode.finish(1, null, 0.0)
		assert_false(mode.won)
		assert_false(SaveService.hunt_best.has(String(hunt.id)))
		mode.build_setup()
		mode.tracker.perfect_parries = hunt.condition.count
		mode.tracker.fight_ticks = 1200
		mode.tracker.survived_singularity = true
		mode.finish(0, null, 0.0)
		assert_true(mode.won)
		assert_almost(SaveService.hunt_best[String(hunt.id)], 20.0)
		assert_eq(mode.unlock_messages().size(), hunt.unlocks.size())
		mode.tracker.fight_ticks = 60
		mode.finish(0, null, 0.0)
		assert_almost(SaveService.hunt_best[String(hunt.id)], 20.0)
		mode.build_setup()
		mode.tracker.perfect_parries = hunt.condition.count
		mode.tracker.fight_ticks = 900
		mode.tracker.survived_singularity = true
		mode.finish(0, null, 0.0)
		assert_true(mode.won)
		assert_true(mode.unlock_messages().is_empty())
		assert_almost(SaveService.hunt_best[String(hunt.id)], 15.0)
	assert_true(Unlocks.is_costume_unlocked(DuelMode.GUARDIAN, DuelMode.GUARDIAN.costumes[1]))
	assert_true(Unlocks.is_color_unlocked(DuelMode.GUARDIAN, 1))
	assert_true(Unlocks.is_color_unlocked(DuelMode.SHADOW, 2))
	SaveService.path = saved_path
	SaveService.hunt_best = saved_hunts
	SaveService.unlocked = saved_unlocks
