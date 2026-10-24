class_name DuelFixture
extends RefCounted

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const GUARDIAN: CharacterData = preload("res://data/characters/guardian/guardian.tres")
const SHADOW: CharacterData = preload("res://data/characters/shadow/shadow.tres")

var sim: MatchSimulation
var intents: Array[Intent] = [Intent.new(), Intent.new()]
var events_log: Array[Dictionary] = []


static func create(rules: MatchRules = null, config: CombatConfig = null, match_seed: int = 7, cast: Array[CharacterData] = []) -> DuelFixture:
	var fixture: DuelFixture = DuelFixture.new()
	var characters: Array[CharacterData] = [GUARDIAN, SHADOW]
	if not cast.is_empty():
		characters = cast
	fixture.sim = MatchSimulation.new(config if config != null else CONFIG, rules if rules != null else MatchRules.new(), characters, match_seed)
	fixture.sim.start_match()
	return fixture


static func versus(first: StringName, second: StringName) -> DuelFixture:
	var cast: Array[CharacterData] = [character(first), character(second)]
	var fixture: DuelFixture = create(null, null, 7, cast)
	fixture.skip_intro()
	return fixture


static func character(id: StringName) -> CharacterData:
	return load("res://data/characters/%s/%s.tres" % [id, id]) as CharacterData


func give_power(index: int, id: StringName, slot: int = 0) -> PowerData:
	var power: PowerData = load("res://data/powers/%s.tres" % id)
	fighter(index).powers[slot] = power
	fighter(index).flow = 100.0
	return power


func set_level(index: int, level: int) -> void:
	fighter(index).set_flow_level(level, sim.config)


func cast(index: int, direction: int = 0) -> void:
	intents[index].move_x = direction * fighter(index).facing
	press(index, Intent.Command.POWER)
	step(1)
	intents[index].move_x = 0


static func config_copy() -> CombatConfig:
	return CONFIG.duplicate(true) as CombatConfig


func fighter(index: int) -> FighterState:
	return sim.fighters[index]


func skip_intro() -> void:
	while sim.phase != MatchSimulation.Phase.FIGHT:
		step()


func place(gap: float) -> void:
	var half: float = (gap + sim.config.body_width) * 0.5
	fighter(0).x = -half
	fighter(1).x = half
	fighter(0).facing = 1
	fighter(1).facing = -1


func press(index: int, button: Intent.Command) -> void:
	intents[index].press(button)


func hold(index: int, button: Intent.Command) -> void:
	intents[index].hold(button)


func release(index: int) -> void:
	intents[index].clear()


func step(count: int = 1) -> void:
	for i in count:
		sim.step(intents[0], intents[1])
		for event_index in sim.event_count:
			var event: CombatEvent = sim.events[event_index]
			events_log.append({
				"type": event.type,
				"source": event.source,
				"target": event.target,
				"amount": event.amount,
				"limb": event.limb,
				"finisher": event.finisher,
				"heavy": event.heavy,
				"tick": sim.tick,
			})
		for intent in intents:
			intent.pressed = 0


func step_until(predicate: Callable, max_ticks: int = 600) -> bool:
	for i in max_ticks:
		if predicate.call():
			return true
		step()
	return predicate.call()


func count_events(type: CombatEvent.Type) -> int:
	var total: int = 0
	for entry in events_log:
		if entry["type"] == type:
			total += 1
	return total


func last_event(type: CombatEvent.Type) -> Dictionary:
	for i in range(events_log.size() - 1, -1, -1):
		if events_log[i]["type"] == type:
			return events_log[i]
	return {}


func clear_log() -> void:
	events_log.clear()
