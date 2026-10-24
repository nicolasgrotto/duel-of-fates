extends TestCase

const DUEL_SCREEN: GDScript = preload("res://screens/duel/duel_screen.gd")


func test_every_rotation_arena_has_its_own_ambience_and_music() -> void:
	var ambiences: Array[AudioStream] = []
	var music: Array[MusicData] = []
	for index in DuelMode.ROTATION_SIZE:
		var arena: ArenaData = DuelMode.ARENAS[index]
		assert_true(arena.ambience != null, "%s has an ambience" % arena.id)
		assert_false(ambiences.has(arena.ambience), "%s repeats an ambience" % arena.id)
		assert_false(music.has(arena.music), "%s repeats a music variation" % arena.id)
		ambiences.append(arena.ambience)
		music.append(arena.music)


func test_bosses_bring_their_own_theme() -> void:
	var setup: DuelSetup = DuelSetup.new()
	setup.arena = DuelMode.DEFAULT_ARENA
	setup.characters = [DuelFixture.GUARDIAN, DuelFixture.character(&"awakened_shadow")]
	var boss_theme: MusicData = setup.characters[1].theme
	assert_true(boss_theme != null)
	assert_eq(DUEL_SCREEN.duel_music(setup), boss_theme)
	setup.characters = [DuelFixture.GUARDIAN, DuelFixture.SHADOW]
	assert_eq(DUEL_SCREEN.duel_music(setup), setup.arena.music)
