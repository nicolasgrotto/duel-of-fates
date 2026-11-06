class_name InfiltrationMissionState
extends RefCounted

enum Outcome { ACTIVE, COMPLETED, PLAYER_DOWN, PRISONER_DOWN }
enum Bonus { NO_ALARM = 1, NO_TAKEDOWNS = 2, TIME = 4, ALL_RESCUED = 8 }

var data: InfiltrationMissionData
var outcome: Outcome = Outcome.ACTIVE
var copied: PackedByteArray = []
var recruited: PackedByteArray = []
var extracted: PackedByteArray = []
var alarm_raised: bool = false
var takedowns: int = 0
var finished_tick: int = 0


func _init(mission: InfiltrationMissionData) -> void:
	data = mission
	copied.resize(data.terminals.size())
	recruited.resize(data.prisoner_spawns.size())
	extracted.resize(recruited.size())


func nearby_object(sim: InfiltrationSimulation) -> int:
	for index in data.terminals.size():
		if copied[index] == 0 and _reachable(sim, data.terminals[index]):
			return index
	if prisoners_locked(sim):
		return -1
	for index in sim.prisoners.size():
		if recruited[index] == 0 and sim.prisoners[index].health > 0.0 and _reachable(sim, sim.prisoners[index].position):
			return data.terminals.size() + index
	return -1


func prisoners_locked(sim: InfiltrationSimulation) -> bool:
	if not data.panels_unlock_prisoners:
		return false
	for panel in sim.panels:
		if not panel.disabled:
			return true
	return false


func locked_prisoner_nearby(sim: InfiltrationSimulation) -> bool:
	if not prisoners_locked(sim):
		return false
	for actor in sim.prisoners:
		if actor.health > 0.0 and _reachable(sim, actor.position):
			return true
	return false


func _reachable(sim: InfiltrationSimulation, point: Vector2) -> bool:
	return sim.player.position.distance_to(point) <= sim.config.interaction_range and InfiltrationGeometry.wall_fraction(sim.map, sim.player.position, point) == INF


func interact(sim: InfiltrationSimulation) -> void:
	var index: int = nearby_object(sim)
	if index < 0:
		return
	if index < copied.size():
		copied[index] = 1
		sim.emit_mission_event(InfiltrationEvent.Type.INFORMATION_COPIED, index, data.terminals[index])
	else:
		index -= copied.size()
		recruited[index] = 1
		sim.emit_mission_event(InfiltrationEvent.Type.PRISONER_RECRUITED, index, sim.prisoners[index].position)


func advance(sim: InfiltrationSimulation, escorts: Array[InfiltrationIntent]) -> void:
	alarm_raised = alarm_raised or sim.alarm_active()
	for index in sim.prisoners.size():
		var actor: InfiltrationActor = sim.prisoners[index]
		actor.previous = actor.position
		actor.velocity = Vector2.ZERO
		if actor.health <= 0.0 or recruited[index] == 0 or extracted[index] != 0:
			continue
		if index < escorts.size():
			var movement: Vector2 = escorts[index].movement.limit_length() * follower_speed(index, sim.config.escort_speed) * Ticks.DELTA
			actor.position = InfiltrationGeometry.move_body(sim.map, actor.position, movement, sim.config.body_radius, sim.targets)
			actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
			if actor.velocity.length_squared() > 0.0:
				actor.aim = actor.velocity.normalized()
		if can_extract(index) and actor.position.distance_to(data.extraction) <= data.extraction_radius:
			extracted[index] = 1
			sim.emit_mission_event(InfiltrationEvent.Type.PRISONER_EXTRACTED, index, actor.position)
	if surviving_prisoners(sim) < data.required_prisoners():
		_finish(sim, Outcome.PRISONER_DOWN)
	elif sim.player.health <= 0.0:
		_finish(sim, Outcome.PLAYER_DOWN)
	elif completed_objectives(sim) == data.objective_count() and _followers_arrived(sim) and sim.player.position.distance_to(data.extraction) <= data.extraction_radius:
		_finish(sim, Outcome.COMPLETED)


func can_extract(_index: int) -> bool:
	return true


func follower_speed(_index: int, base: float) -> float:
	return base


func surviving_prisoners(sim: InfiltrationSimulation) -> int:
	var count: int = 0
	for actor in sim.prisoners:
		count += int(actor.health > 0.0)
	return count


func rescued() -> int:
	var count: int = 0
	for value in extracted:
		count += value
	return count


func _followers_arrived(sim: InfiltrationSimulation) -> bool:
	for index in sim.prisoners.size():
		if recruited[index] != 0 and extracted[index] == 0 and sim.prisoners[index].health > 0.0:
			return false
	return true


func _finish(sim: InfiltrationSimulation, result: Outcome) -> void:
	outcome = result
	finished_tick = sim.tick
	sim.emit_mission_event(InfiltrationEvent.Type.MISSION_FINISHED, int(result), sim.player.position)


func completed_objectives(sim: InfiltrationSimulation) -> int:
	var count: int = 0
	if data.disable_alarms:
		for panel in sim.panels:
			count += int(panel.disabled)
	for value in copied:
		count += value
	return count + mini(rescued(), data.required_prisoners())


func bonuses(tick: int) -> int:
	var mask: int = (0 if alarm_raised else Bonus.NO_ALARM) | (0 if takedowns > 0 else Bonus.NO_TAKEDOWNS) | (Bonus.TIME if tick <= Ticks.from_seconds(data.bonus_seconds) else 0)
	return mask | (Bonus.ALL_RESCUED if not extracted.is_empty() and rescued() == extracted.size() else 0)


func capture() -> Dictionary:
	return {"outcome": int(outcome), "copied": copied.duplicate(), "recruited": recruited.duplicate(), "extracted": extracted.duplicate(), "alarm_raised": alarm_raised, "takedowns": takedowns, "finished_tick": finished_tick}


func restore(state: Dictionary) -> void:
	outcome = state.outcome as Outcome
	copied = state.copied.duplicate()
	recruited = state.recruited.duplicate()
	extracted = state.extracted.duplicate()
	alarm_raised = state.alarm_raised
	takedowns = state.takedowns
	finished_tick = state.finished_tick
