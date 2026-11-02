extends TestCase

const ARENA: SpaceArenaData = preload("res://data/space/training_arena.tres")


func test_training_arena_uses_original_sprites_valid_spawns_and_expected_stats() -> void:
	assert_eq(ARENA.ships.size(), 4)
	assert_eq(ARENA.ships[0].ship.sprite.get_size(), Vector2(40, 40))
	assert_eq(ARENA.ships[1].ship.sprite.get_size(), Vector2(32, 32))
	assert_almost(ARENA.ships[0].ship.hull, 100.0)
	assert_almost(ARENA.ships[0].ship.shield, 40.0)
	assert_almost(ARENA.ships[1].ship.hull / ARENA.ships[0].ship.primary.damage, 3.0)
	assert_true(ARENA.ships[0].ship.secondary == null)
	for placement in ARENA.ships:
		assert_true(placement.position.x >= placement.ship.radius and placement.position.y >= placement.ship.radius)
		assert_true(placement.position.x <= ARENA.size.x - placement.ship.radius and placement.position.y <= ARENA.size.y - placement.ship.radius)
	var saved_locale: String = TranslationServer.get_locale()
	for locale in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		assert_true(TranslationServer.translate(ARENA.title_key) != ARENA.title_key)
		for placement in ARENA.ships:
			assert_true(TranslationServer.translate(placement.ship.name_key) != placement.ship.name_key)
	TranslationServer.set_locale(saved_locale)


func test_five_missions_preserve_sections_obstacles_and_localized_content() -> void:
	assert_eq(SpaceMode.MISSIONS.size(), 5)
	var locale_before: String = TranslationServer.get_locale()
	for locale in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		for data in SpaceMode.MISSIONS:
			assert_eq(data.arena.size, Vector2(2800, 1800))
			assert_eq(data.arena.obstacles.size(), 3)
			for key in [data.title_key, data.briefing_key, data.objective_key]:
				assert_ne(TranslationServer.translate(key), key)
			var arena: SpaceArenaData = data.create_arena(SpaceLoadout.new(), SpaceMode.UPGRADES)
			for placement in arena.ships:
				assert_ne(TranslationServer.translate(placement.ship.name_key), placement.ship.name_key)
				assert_almost(placement.respawn_seconds, 0.0)
	TranslationServer.set_locale(locale_before)
	var escort: SpaceMissionData = SpaceMode.MISSIONS[2]
	assert_eq(escort.protected_ship, 1)
	assert_eq(escort.arena.ships[2].role, SpaceShipPlacement.Role.GENERATOR)
	assert_eq(escort.arena.ships[2].parent, 1)
	var boss: SpaceMissionData = SpaceMode.MISSIONS[4]
	assert_eq(boss.phases.size(), 3)
	assert_eq(boss.arena.ships[2].role, SpaceShipPlacement.Role.WEAKPOINT)
	assert_eq(boss.arena.ships[2].parent, 1)
