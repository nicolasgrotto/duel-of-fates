class_name HeadlessDuel
extends RefCounted

const MAX_SECONDS: float = 300.0

var sim: MatchSimulation
var controllers: Array[FighterController] = []
var intents: Array[Intent] = [Intent.new(), Intent.new()]
var fight_ticks: int = 0
var knockouts: int = 0
var hits_before_knockout: int = 0
var event_counts: Dictionary = {}
var _hits_this_round: Array[int] = [0, 0]


func _init(config: CombatConfig, characters: Array[CharacterData], difficulties: Array[AiDifficultyData], match_seed: int) -> void:
	sim = MatchSimulation.new(config, MatchRules.new(), characters, match_seed)
	for i in characters.size():
		controllers.append(AiController.new(difficulties[i], characters[i].ai_profile, match_seed * 31 + i))
	sim.start_match()


func run() -> int:
	var max_ticks: int = Ticks.from_seconds(MAX_SECONDS)
	while sim.phase != MatchSimulation.Phase.OVER and sim.tick < max_ticks:
		for i in controllers.size():
			controllers[i].produce(sim, i, intents[i])
		sim.step(intents[0], intents[1])
		if sim.phase == MatchSimulation.Phase.FIGHT:
			fight_ticks += 1
		_count_events()
	return sim.match_winner


func _count_events() -> void:
	for i in sim.event_count:
		var event: CombatEvent = sim.events[i]
		event_counts[event.type] = event_counts.get(event.type, 0) + 1
		match event.type:
			CombatEvent.Type.HIT:
				_hits_this_round[event.target] += 1
			CombatEvent.Type.ROUND_ENDED:
				if event.target != CombatEvent.NO_FIGHTER:
					knockouts += 1
					hits_before_knockout += _hits_this_round[event.target]
				_hits_this_round[0] = 0
				_hits_this_round[1] = 0


func count(type: CombatEvent.Type) -> int:
	return event_counts.get(type, 0)
