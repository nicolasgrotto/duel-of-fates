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
