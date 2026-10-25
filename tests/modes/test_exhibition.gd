extends TestCase

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const MAX_TICKS: int = 3600
const SHOWCASE: Dictionary = {
	&"blades": {
		"finisher": Finisher.Kind.TWIN_BLADES,
		"events": [CombatEvent.Type.BLOCK, CombatEvent.Type.CLASH, CombatEvent.Type.BLADE_LOCK_STARTED, CombatEvent.Type.EVADE_SUCCESS, CombatEvent.Type.PERFECT_PARRY],
		"dodges": [FighterState.DodgeKind.SPIN],
	},
	&"flow": {
		"finisher": Finisher.Kind.PULL_CUT,
		"events": [CombatEvent.Type.POWER_BLOCKED, CombatEvent.Type.CLASH, CombatEvent.Type.BLOCK, CombatEvent.Type.POWER_HIT],
		"powers": [&"lightning", &"barrier", &"wrath", &"mass_telekinesis", &"pull"],
	},
	&"dance": {
		"finisher": Finisher.Kind.WHIRL,
		"events": [CombatEvent.Type.JUMP, CombatEvent.Type.BLOCK, CombatEvent.Type.CLASH],
		"dodges": [FighterState.DodgeKind.SPIN],
	},
}


func _play(index: int) -> Dictionary:
	var mode: ExhibitionMode = ExhibitionMode.new()
	mode.index = index
	var setup: DuelSetup = mode.build_setup()
	var sim: MatchSimulation = MatchSimulation.new(CONFIG, setup.rules, setup.characters, setup.match_seed)
	for i in 2:
		var custom: Array[PowerData] = []
		custom.assign(setup.power_sets[i])
		sim.fighters[i].equip_powers(custom)
	sim.start_match()
	var controllers: Array[ChoreographyController] = [ChoreographyController.new(setup.bout, 0), ChoreographyController.new(setup.bout, 1)]
	var intents: Array[Intent] = [Intent.new(), Intent.new()]
	var seen: Dictionary = {"events": {}, "dodges": {}, "powers": {}, "finisher": Finisher.Kind.NONE, "rejected": 0, "ended": false}
	for tick in MAX_TICKS:
		for i in 2:
			controllers[i].produce(sim, i, intents[i])
		sim.step(intents[0], intents[1])
		for e in sim.event_count:
			var event: CombatEvent = sim.events[e]
			seen["events"][event.type] = true
			match event.type:
				CombatEvent.Type.DODGE:
					seen["dodges"][int(event.amount)] = true
				CombatEvent.Type.POWER_STARTED:
					seen["powers"][event.power.id] = true
				CombatEvent.Type.DEATH:
					seen["finisher"] = event.finisher
				CombatEvent.Type.ACTION_REJECTED:
					seen["rejected"] += 1
		if sim.phase == MatchSimulation.Phase.OVER:
			seen["ended"] = true
			break
	return seen


func test_every_bout_plays_its_showcase_and_finisher() -> void:
	var bouts: Array[ExhibitionBout] = ExhibitionMode.EXHIBITION.bouts
	assert_eq(bouts.size(), SHOWCASE.size())
	for index in bouts.size():
		var id: StringName = bouts[index].id
		var expected: Dictionary = SHOWCASE[id]
		var seen: Dictionary = _play(index)
		assert_true(seen["ended"], "%s reaches the end of the match" % id)
		assert_eq(seen["finisher"], expected["finisher"], "%s ends on its finisher" % id)
		assert_eq(seen["rejected"], 0, "%s never asks for an action the fighter cannot do" % id)
		for type in expected["events"]:
			assert_true(seen["events"].has(type), "%s shows %s" % [id, CombatEvent.Type.keys()[type]])
		for kind in expected.get("dodges", []):
			assert_true(seen["dodges"].has(kind), "%s shows the %s dodge" % [id, FighterState.DodgeKind.keys()[kind]])
		for power in expected.get("powers", []):
			assert_true(seen["powers"].has(power), "%s casts %s" % [id, power])


func test_bouts_replay_identically() -> void:
	for index in ExhibitionMode.EXHIBITION.bouts.size():
		assert_eq(_play(index), _play(index), "bout %d is deterministic" % index)


func test_exhibition_chains_bouts_and_returns_to_the_menu() -> void:
	var mode: ExhibitionMode = ExhibitionMode.new()
	assert_eq(mode.build_setup().controllers, [DuelSetup.ControllerKind.CHOREOGRAPHY, DuelSetup.ControllerKind.CHOREOGRAPHY])
	assert_true(mode.build_setup().rules.free_powers)
	assert_eq(mode.build_setup().rules.rounds_to_win, 1)
