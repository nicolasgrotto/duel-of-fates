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
