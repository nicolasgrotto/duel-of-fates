class_name BlasterOpsMissionState
extends InfiltrationMissionState

var definition: BlasterOpsMissionData
var wave_index: int = -1
var intermission_ticks: int = 0
var waves_finished: bool = false
var phase_index: int = 0
var phase_health: float = 0.0
var damage_taken: float = 0.0
var attempts: int = 0
var hits: int = 0
var barriers_placed: int = 0
var last_hit_swing: int = -1


func _init(mission_data: BlasterOpsMissionData) -> void:
	super(mission_data)
	definition = mission_data
	intermission_ticks = Ticks.from_seconds(definition.intermission_seconds)


func setup(sim: BlasterOpsSimulation) -> void:
	if definition.protected_index >= 0:
		recruited[definition.protected_index] = 1
		sim.prisoners[definition.protected_index].health = definition.protected_health
	if definition.phase_target >= 0:
		phase_health = sim.target_data[definition.phase_target].health
		if not definition.phases.is_empty():
			sim.target_data[definition.phase_target] = definition.phases[0].enemy


func interact(sim: InfiltrationSimulation) -> void:
	if nearby_object(sim) >= 0:
		super.interact(sim)
	elif definition.kind == BlasterOpsMissionData.Kind.DEFENSE and intermission_ticks > 0:
		(sim as BlasterOpsSimulation).deploy_barrier()


func advance(simulation: InfiltrationSimulation, escorts: Array[InfiltrationIntent]) -> void:
	var sim: BlasterOpsSimulation = simulation as BlasterOpsSimulation
	if definition.protected_index >= 0 and sim.prisoners[definition.protected_index].health <= 0.0:
		_finish(sim, Outcome.PRISONER_DOWN)
		return
	if sim.player.health <= 0.0:
		_finish(sim, Outcome.PLAYER_DOWN)
		return
	_advance_phases(sim)
	_advance_waves(sim)
	super.advance(sim, escorts)


func _advance_phases(sim: BlasterOpsSimulation) -> void:
	if definition.phase_target < 0 or definition.phases.is_empty():
		return
	var actor: BlasterOpsActor = sim.targets[definition.phase_target] as BlasterOpsActor
	if actor.health <= 0.0 or not actor.spawned:
		return
	while phase_index + 1 < definition.phases.size() and actor.health <= phase_health * definition.phases[phase_index + 1].health_ratio:
		phase_index += 1
		sim.target_data[definition.phase_target] = definition.phases[phase_index].enemy
		actor.telegraph_ticks = -1
		actor.burst_left = 0
		actor.fire_ticks = 0
		sim._emit(InfiltrationEvent.Type.PHASE_CHANGED, definition.phase_target + 1, phase_index, actor.position)


func _advance_waves(sim: BlasterOpsSimulation) -> void:
	if waves_finished:
		return
	if definition.kind == BlasterOpsMissionData.Kind.HOLD_OUT and wave_index == 0 and sim.tick >= Ticks.from_seconds(definition.hold_seconds):
		_start_wave(sim, 1)
	if intermission_ticks > 0:
		intermission_ticks -= 1
		if intermission_ticks == 0:
			_start_wave(sim, wave_index + 1)
		return
	if wave_index < 0:
		_start_wave(sim, 0)
	_spawn_pending(sim)
	if not _wave_spawned(sim) or enemies_left(sim) > 0:
		return
	if wave_index + 1 == definition.waves.size():
		waves_finished = true
		sim._emit(InfiltrationEvent.Type.EXTRACTION_OPENED, 0, -1, data.extraction)
	elif definition.kind != BlasterOpsMissionData.Kind.HOLD_OUT:
		intermission_ticks = Ticks.from_seconds(definition.intermission_seconds)


func _start_wave(sim: BlasterOpsSimulation, index: int) -> void:
	wave_index = index
	intermission_ticks = 0
	sim._emit(InfiltrationEvent.Type.WAVE_STARTED, 0, index, sim.player.position)
	_spawn_pending(sim)


func _spawn_pending(sim: BlasterOpsSimulation) -> void:
	for wave in range(wave_index + 1):
		for index in definition.waves[wave].indices:
			var actor: InfiltrationActor = sim.targets[index]
			if actor.spawned or not sim._spawn_clear(actor.position):
				continue
			actor.spawned = true
			actor.health = definition.phases[0].enemy.health if index == definition.phase_target and not definition.phases.is_empty() else sim.target_data[index].health
			InfiltrationPerception.alert(sim, index, sim.player.position)
			sim._emit(InfiltrationEvent.Type.REINFORCEMENT_ARRIVED, index + 1, -1, actor.position)


func _wave_spawned(sim: BlasterOpsSimulation) -> bool:
	for wave in range(wave_index + 1):
		for index in definition.waves[wave].indices:
			if not sim.targets[index].spawned:
				return false
	return true


func enemies_left(sim: InfiltrationSimulation) -> int:
	var count: int = 0
	for actor in sim.targets:
		count += int(actor.spawned and actor.health > 0.0)
	return count


func goal_done(sim: InfiltrationSimulation) -> bool:
	if definition.kind == BlasterOpsMissionData.Kind.HOLD_OUT:
		return sim.tick >= Ticks.from_seconds(definition.hold_seconds)
	if definition.kind == BlasterOpsMissionData.Kind.ESCORT:
		return extracted[definition.protected_index] != 0
	for index in definition.defense_targets:
		if sim.targets[index].health > 0.0 or not sim.targets[index].spawned:
			return false
	return waves_finished


func completed_objectives(sim: InfiltrationSimulation) -> int:
	return int(goal_done(sim)) + int(waves_finished)


func _followers_arrived(_sim: InfiltrationSimulation) -> bool:
	return true


func bonuses(tick: int) -> int:
	return (1 if tick <= Ticks.from_seconds(data.bonus_seconds) else 0) | (2 if damage_taken <= definition.damage_bonus else 0) | (4 if attempts > 0 and float(hits) / attempts >= definition.accuracy_bonus else 0)


func bonus_objective(sim: InfiltrationSimulation) -> bool:
	if definition.protected_index >= 0:
		return sim.prisoners[definition.protected_index].health >= definition.protected_health * 0.5
	if not sim.prisoners.is_empty():
		for index in recruited.size():
			if recruited[index] == 0 or sim.prisoners[index].health <= 0.0:
				return false
		return true
	return goal_done(sim)


func capture() -> Dictionary:
	var snapshot: Dictionary = super.capture()
	snapshot["incursion"] = {"wave_index": wave_index, "intermission_ticks": intermission_ticks, "waves_finished": waves_finished, "phase_index": phase_index, "phase_health": phase_health, "damage_taken": damage_taken, "attempts": attempts, "hits": hits, "barriers_placed": barriers_placed, "last_hit_swing": last_hit_swing}
	return snapshot


func restore(snapshot: Dictionary) -> void:
	super.restore(snapshot)
	for key in snapshot.incursion:
		set(key, snapshot.incursion[key])
