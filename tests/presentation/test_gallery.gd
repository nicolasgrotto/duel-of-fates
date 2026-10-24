extends TestCase

const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")
const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const STEADY_TIER: int = 2
const MAX_TICKS: int = 360

var fixture: DuelFixture
var panel: GalleryPanel


func before_each() -> void:
	var rules: MatchRules = MatchRules.new()
	rules.endless = true
	rules.free_powers = true
	var cast: Array[CharacterData] = [DuelFixture.GUARDIAN.duplicate(), DuelFixture.SHADOW.duplicate()]
	fixture = DuelFixture.create(rules, null, 7, cast)
	fixture.skip_intro()
	panel = GalleryPanel.new()
	panel.config = TRAINING
	panel._entries.assign(CATALOG.powers)
	panel._entries.append_array(CATALOG.techniques)
	panel._tier = STEADY_TIER


func _demonstrate(id: StringName) -> Dictionary:
	panel._entry_index = panel._entries.find(CATALOG.find(id))
	panel._stage(fixture.sim)
	fixture.clear_log()
	var affected: bool = false
	var drained_ticks: int = 0
	for tick in MAX_TICKS:
		panel.caster.produce(fixture.sim, 0, fixture.intents[0])
		panel.target.produce(fixture.sim, 1, fixture.intents[1])
		fixture.step(1)
		var target: FighterState = fixture.fighter(1)
		affected = affected or target.state == FighterState.State.HELD or target.twisted_ticks > 0
		if fixture.fighter(0).power_kind_active(PowerData.Kind.DRAIN):
			drained_ticks += 1
	return {"hits": fixture.count_events(CombatEvent.Type.POWER_HIT), "affected": affected, "drained": drained_ticks}


func test_targeted_powers_reach_the_standing_target() -> void:
	for id in [&"repulse", &"pull", &"mind_twist", &"supreme_push", &"freeze", &"choke", &"lightning"]:
		var result: Dictionary = _demonstrate(id)
		assert_gt(result["hits"], 0, "%s hits the gallery target" % id)
		if id == &"freeze" or id == &"choke" or id == &"mind_twist":
			assert_true(result["affected"], "%s takes hold of the gallery target" % id)
	panel.free()


func test_drain_holds_its_tether_on_the_target() -> void:
	var result: Dictionary = _demonstrate(&"drain")
	var drain: PowerData = CATALOG.find(&"drain")
	assert_gt(result["drained"], Ticks.from_seconds(drain.max_channel) / 2, "the tether holds instead of breaking out of reach")
	panel.free()


func test_powers_that_travel_keep_the_round_distance() -> void:
	panel._entry_index = panel._entries.find(CATALOG.find(&"throw"))
	panel._stage(fixture.sim)
	assert_almost(fixture.fighter(1).x - fixture.fighter(0).x, fixture.sim.config.round_start_distance)
	panel.free()


func test_every_technique_reaches_the_standing_target() -> void:
	for technique in CATALOG.techniques:
		panel._entry_index = panel._entries.find(technique)
		panel._stage(fixture.sim)
		fixture.clear_log()
		for tick in MAX_TICKS:
			panel.caster.produce(fixture.sim, 0, fixture.intents[0])
			panel.target.produce(fixture.sim, 1, fixture.intents[1])
			fixture.step(1)
		assert_gt(fixture.count_events(CombatEvent.Type.HIT), 0, "%s hits the gallery target" % technique.id)
	panel.free()


func test_mass_telekinesis_demonstration_lasts_until_the_rocks_land() -> void:
	panel._entry_index = panel._entries.find(CATALOG.find(&"mass_telekinesis"))
	panel._stage(fixture.sim)
	fixture.clear_log()
	var started: bool = false
	var finished_at: int = -1
	for tick in Ticks.from_seconds(TRAINING.gallery_max_time):
		panel.caster.produce(fixture.sim, 0, fixture.intents[0])
		panel.target.produce(fixture.sim, 1, fixture.intents[1])
		fixture.step(1)
		var busy: bool = panel.demonstrating(fixture.sim)
		started = started or busy
		if started and not busy:
			finished_at = tick
			break
	assert_true(started)
	assert_gt(finished_at, 0, "the demonstration ends on its own")
	assert_gt(fixture.count_events(CombatEvent.Type.HAZARD_TRIGGERED), 0, "the rocks land before the gallery restages")
	panel.free()


func _finish(entry: Resource) -> Dictionary:
	fixture.step_until(func() -> bool: return fixture.sim.phase == MatchSimulation.Phase.FIGHT, 900)
	panel._entry_index = panel._entries.find(entry)
	panel._stage(fixture.sim)
	fixture.clear_log()
	for tick in MAX_TICKS:
		panel.caster.produce(fixture.sim, 0, fixture.intents[0])
		panel.target.produce(fixture.sim, 1, fixture.intents[1])
		fixture.step(1)
		if fixture.count_events(CombatEvent.Type.DEATH) > 0:
			break
	return fixture.last_event(CombatEvent.Type.DEATH)


func test_finisher_toggle_plays_each_cinematic_finisher() -> void:
	panel._finishers = true
	var entries: Array[Resource] = []
	entries.assign(panel._entries.filter(GalleryPanel.has_finisher))
	assert_gt(entries.size(), 0)
	for entry in entries:
		var expected: Finisher.Kind = (entry as PowerData).finisher if entry is PowerData else (entry as MoveData).cinematic_finisher
		var death: Dictionary = _finish(entry)
		assert_false(death.is_empty(), "%s kills the gallery target" % entry.id)
		assert_eq(death.get("finisher", Finisher.Kind.NONE), expected, "%s plays its cinematic finisher" % entry.id)
	panel.free()


func test_gallery_target_survives_without_the_finisher_toggle() -> void:
	var death: Dictionary = _finish(CATALOG.find(&"lightning"))
	assert_true(death.is_empty(), "the target cannot die while the toggle is off")
	assert_false(fixture.sim.rules.endless_finishers)
	panel.free()


func test_gallery_finisher_restarts_the_round_without_ending_the_match() -> void:
	panel._finishers = true
	_finish(CATALOG.find(&"repulse"))
	var restarted: bool = fixture.step_until(func() -> bool: return fixture.sim.phase == MatchSimulation.Phase.FIGHT and fixture.fighter(1).is_alive(), 900)
	assert_true(restarted, "the round starts again after the finisher")
	assert_eq(fixture.count_events(CombatEvent.Type.MATCH_ENDED), 0)
	assert_eq(fixture.fighter(0).round_wins, 0)
	panel.free()
