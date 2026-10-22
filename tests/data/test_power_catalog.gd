extends TestCase

const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")
const GUARDIAN: CharacterData = preload("res://data/characters/guardian/guardian.tres")
const SHADOW: CharacterData = preload("res://data/characters/shadow/shadow.tres")


func test_catalog_holds_every_power() -> void:
	var count: int = 0
	for file in DirAccess.get_files_at("res://data/powers"):
		if file.ends_with(".tres") and file != "catalog.tres":
			count += 1
	assert_eq(CATALOG.powers.size(), count)


func test_allowed_powers_follow_path_and_level() -> void:
	for power in CATALOG.allowed_for(GUARDIAN):
		assert_true(power.path != PowerData.Path.ECLIPSE, "%s is Eclipse" % power.id)
		assert_true(power.min_level <= GUARDIAN.flow, "%s needs more Flow" % power.id)
	for power in CATALOG.allowed_for(SHADOW):
		assert_true(power.path != PowerData.Path.AURORA, "%s is Aurora" % power.id)


func test_base_sets_are_allowed() -> void:
	for character in [GUARDIAN, SHADOW]:
		for power in CATALOG.base_set(character):
			assert_true(PowerCatalog.is_allowed(power, character), "%s not allowed" % power.id)


func test_cycling_onto_an_equipped_power_swaps_slots() -> void:
	var chosen: Array[PowerData] = CATALOG.base_set(GUARDIAN)
	var allowed: Array[PowerData] = CATALOG.allowed_for(GUARDIAN)
	var first: PowerData = chosen[0]
	var second: PowerData = chosen[1]
	var step: int = allowed.find(second) - allowed.find(first)
	CATALOG.cycle(chosen, 0, step, GUARDIAN)
	assert_eq(chosen[0], second)
	assert_eq(chosen[1], first)
