class_name StatsTracker
extends RefCounted

const STAT_KEYS: Array[StringName] = [
	&"hits", &"damage", &"blocks", &"parries", &"perfect_parries", &"guard_breaks", &"shoves", &"best_combo",
]
const EXTRA_KEYS: Array[StringName] = [&"aerial_hits", &"feints", &"responses", &"bolt_hits"]

var stats: Array[Dictionary] = []
var fight_ticks: int = 0


func _init() -> void:
	for i in 2:
		var entry: Dictionary = {}
		for key in STAT_KEYS + EXTRA_KEYS:
			entry[key] = 0
		stats.append(entry)


func on_tick(sim: MatchSimulation) -> void:
	if sim.phase == MatchSimulation.Phase.FIGHT:
		fight_ticks += 1


func on_event(event: CombatEvent) -> void:
	match event.type:
		CombatEvent.Type.HIT:
			_add(event.source, &"hits", 1)
			_add(event.source, &"damage", roundi(event.amount))
			stats[event.source][&"best_combo"] = maxi(stats[event.source][&"best_combo"], event.combo)
			if event.move != null and event.move.is_aerial():
				_add(event.source, &"aerial_hits", 1)
		CombatEvent.Type.FEINT:
			_add(event.source, &"feints", 1)
		CombatEvent.Type.BOLT_HIT:
			_add(event.source, &"bolt_hits", 1)
		CombatEvent.Type.RESPONSE:
			_add(event.target, &"responses", 1)
		CombatEvent.Type.BLOCK:
			_add(event.target, &"blocks", 1)
		CombatEvent.Type.PARRY:
			_add(event.target, &"parries", 1)
		CombatEvent.Type.PERFECT_PARRY:
			_add(event.target, &"perfect_parries", 1)
		CombatEvent.Type.GUARD_BREAK:
			_add(event.source, &"guard_breaks", 1)
		CombatEvent.Type.SHOVE:
			_add(event.source, &"shoves", 1)


func _add(fighter_index: int, key: StringName, amount: int) -> void:
	if fighter_index >= 0:
		stats[fighter_index][key] += amount
