extends TestCase

const SERVICE: GDScript = preload("res://core/save_service.gd")


func test_points_only_come_from_first_valid_space_victories() -> void:
	var progress: SpaceProgress = SpaceProgress.new()
	assert_false(progress.record(&"arcade", 60, 3))
	assert_false(progress.record(&"open_corridor", 0, 3))
	assert_false(progress.record(&"open_corridor", 60, 0))
	assert_false(progress.buy(0))
	assert_true(progress.record(&"open_corridor", 900, 2))
	assert_false(progress.record(&"open_corridor", 1200, 3))
	assert_eq(progress.available(), 1)
	assert_eq(progress.records.open_corridor.ticks, 900)
	assert_eq(progress.records.open_corridor.rating, 3)


func test_purchase_caps_costs_refunds_and_changes_only_mode_stats() -> void:
	var progress: SpaceProgress = SpaceProgress.new()
	for id in SpaceProgress.IDS:
		progress.record(StringName(id), 900, 3)
	assert_true(progress.buy(0))
	assert_true(progress.buy(0))
	assert_false(progress.buy(0))
	assert_true(progress.buy(1))
	assert_true(progress.buy(2))
	assert_eq(progress.available(), 1)
	var base: SpaceShipData = SpaceMode.MISSIONS[0].arena.ships[0].ship
	var upgraded: SpaceShipData = progress.loadout().build_ship(SpaceProgress.CONFIG, base)
	assert_almost(upgraded.primary.damage, base.primary.damage + 4.0)
	assert_almost(upgraded.primary.interval, base.primary.interval - 0.04)
	assert_almost(upgraded.shield, base.shield + 20.0)
	assert_almost(upgraded.speed, base.speed + 35.0)
	assert_almost(base.primary.damage, 10.0)
	progress.reset_upgrades()
	assert_eq(progress.available(), 5)
	assert_eq(progress.loadout().weapon_level, 0)


func test_upgrades_persist_without_changing_other_modes() -> void:
	var service: Node = SERVICE.new()
	service.path = "user://test_space_progress.cfg"
	service.reset()
	service.survival_best = 7
	service.infiltration_best = {"first_access": {"ticks": 600, "bonuses": 3}}
	service.record_space(&"open_corridor", 900, 3)
	assert_true(service.buy_space_upgrade(0))
	var reloaded: Node = SERVICE.new()
	reloaded.path = service.path
	reloaded.load_progress()
	assert_eq(reloaded.space.levels[0], 1)
	assert_eq(reloaded.space.available(), 0)
	assert_eq(reloaded.survival_best, 7)
	assert_eq(reloaded.infiltration_best, service.infiltration_best)
	reloaded.reset_space_upgrades()
	service.load_progress()
	assert_eq(service.space.available(), 1)
	DirAccess.remove_absolute(service.path)
	service.free()
	reloaded.free()


func test_legacy_save_starts_space_empty() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "survival_best", 9)
	file.save("user://test_space_legacy.cfg")
	var service: Node = SERVICE.new()
	service.path = "user://test_space_legacy.cfg"
	service.load_progress()
	assert_eq(service.space.available(), 0)
	assert_eq(service.space.levels, PackedInt32Array([0, 0, 0]))
	assert_eq(service.survival_best, 9)
	DirAccess.remove_absolute(service.path)
	service.free()


func test_invalid_saved_upgrade_budget_is_clamped() -> void:
	var progress: SpaceProgress = SpaceProgress.new()
	progress.restore({"records": {"open_corridor": {"ticks": 60, "rating": 3}, "unknown": {"ticks": 60, "rating": 3}}, "levels": [99, 99, -4]})
	assert_eq(progress.available(), 0)
	assert_eq(progress.levels, PackedInt32Array([1, 0, 0]))


func test_external_run_reports_typed_result_once_without_save_or_navigation() -> void:
	var service: Node = Engine.get_main_loop().root.get_node("SaveService")
	var router: Node = Engine.get_main_loop().root.get_node("SceneRouter")
	var before: Dictionary = service.space.capture()
	var mode: SpaceMode = SpaceMode.new(SpaceMode.MISSIONS[4], SpaceLoadout.new(), true)
	var results: Array[SpaceMissionResult] = []
	mode.finished.connect(func(value: SpaceMissionResult) -> void: results.append(value))
	var sim: SpaceSimulation = mode.create_simulation()
	sim.ships[0].hull = 0.0
	sim.step(SpaceFixture.commands(sim.ships.size()))
	mode.finish(sim)
	mode.finish(sim)
	assert_eq(results.size(), 1)
	assert_eq(mode.result.outcome, SpaceMissionState.Outcome.PLAYER_DOWN)
	assert_eq(mode.result.mission_id, mode.data.id)
	assert_eq(service.space.capture(), before)
	assert_false(router._busy)


func test_external_victory_keeps_progress_untouched_and_reports_phase_history() -> void:
	var service: Node = Engine.get_main_loop().root.get_node("SaveService")
	var before: Dictionary = service.space.capture()
	var equipment: SpaceLoadout = SpaceLoadout.new()
	equipment.weapon_level = 2
	var mode: SpaceMode = SpaceMode.new(SpaceMode.MISSIONS[4], equipment, true)
	equipment.weapon_level = 0
	var sim: SpaceSimulation = mode.create_simulation()
	assert_almost(sim.ships[0].data.primary.damage, 14.0)
	sim.ships[1].hull = 0.0
	sim.step(SpaceFixture.commands(sim.ships.size()))
	mode.finish(sim)
	assert_true(mode.result.won())
	assert_false(mode.result.point_earned)
	assert_eq(mode.result.phase_visits, PackedInt32Array([1, 0, 0]))
	assert_eq(service.space.capture(), before)
