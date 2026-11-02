class_name SpaceMissionState
extends RefCounted

enum Outcome { ACTIVE, COMPLETED, PLAYER_DOWN, ALLY_DOWN, TIMEOUT }

var data: SpaceMissionData
var outcome: Outcome = Outcome.ACTIVE
var wave: int = 0
var pending_wave: int = 1
var wave_ticks: int = 0
var phase: int = 0
var phase_ticks: int = 0
var phase_visits: PackedInt32Array = []
var finished_tick: int = 0


func _init(mission: SpaceMissionData) -> void:
	data = mission
	pending_wave = 1 if not data.waves.is_empty() else 0
	wave_ticks = Ticks.from_seconds(data.waves[0].delay) if pending_wave > 0 else 0
	phase_visits.resize(data.phases.size())
	if not phase_visits.is_empty():
		phase_visits[0] = 1


func before_tick(sim: SpaceSimulation) -> void:
	phase_ticks += 1
	if pending_wave <= 0:
		return
	wave_ticks = maxi(wave_ticks - 1, 0)
	if wave_ticks > 0:
		return
	var pending: bool = false
	for index in sim.ships.size():
		var placement: SpaceShipPlacement = sim.arena.ships[index]
		if placement.wave != pending_wave or sim.ships[index].spawned:
			continue
		if not sim.spawn_clear(index):
			pending = true
			continue
		sim.ships[index].reset(placement)
		sim.ships[index].spawned = true
	if wave != pending_wave:
		wave = pending_wave
		sim.emit_event(SpaceEvent.Type.WAVE_STARTED, -1, -1, Vector2.ZERO, float(wave))
	if not pending:
		pending_wave = 0


func advance(sim: SpaceSimulation) -> void:
	_advance_phase(sim)
	if sim.ships[0].hull <= 0.0:
		_finish(sim, Outcome.PLAYER_DOWN)
	elif data.protected_ship >= 0 and sim.ships[data.protected_ship].hull <= 0.0:
		_finish(sim, Outcome.ALLY_DOWN)
	elif sim.tick >= Ticks.from_seconds(data.limit_seconds):
		_finish(sim, Outcome.TIMEOUT)
	elif pending_wave == 0 and _wave_cleared(sim):
		if wave < data.waves.size():
			pending_wave = wave + 1
			wave_ticks = Ticks.from_seconds(data.waves[wave].delay)
		elif _objectives_cleared(sim):
			_finish(sim, Outcome.COMPLETED)


func _wave_cleared(sim: SpaceSimulation) -> bool:
	for index in sim.ships.size():
		var placement: SpaceShipPlacement = sim.arena.ships[index]
		if placement.wave == wave and placement.wave > 0 and placement.required and (not sim.ships[index].spawned or sim.ships[index].hull > 0.0):
			return false
	return true


func _objectives_cleared(sim: SpaceSimulation) -> bool:
	for index in range(1, sim.ships.size()):
		if sim.ships[index].team == sim.ships[0].team or not sim.arena.ships[index].required:
			continue
		if not sim.ships[index].spawned or sim.ships[index].hull > 0.0:
			return false
	return data.boss < 0 or sim.ships[data.boss].hull <= 0.0


func _advance_phase(sim: SpaceSimulation) -> void:
	if data.boss < 0 or data.phases.is_empty() or sim.ships[data.boss].hull <= 0.0:
		return
	var ratio: float = sim.ships[data.boss].hull / sim.ships[data.boss].data.hull
	while phase + 1 < data.phases.size() and ratio <= data.phases[phase + 1].threshold:
		phase += 1
		phase_ticks = 0
		phase_visits[phase] += 1
		for slot in 2:
			sim.ships[data.boss].charges[slot] = -1
			sim.ships[data.boss].cooldowns[slot] = 0
		sim.emit_event(SpaceEvent.Type.BOSS_PHASE_CHANGED, data.boss, phase, sim.ships[data.boss].position)


func weakpoint_open() -> bool:
	if data.phases.is_empty():
		return true
	var stage: SpaceBossPhase = data.phases[phase]
	var age: int = phase_ticks % maxi(Ticks.from_seconds(stage.cycle), 1)
	return age >= Ticks.from_seconds(stage.open_start) and age < Ticks.from_seconds(stage.open_start + stage.open_seconds)


func can_damage(sim: SpaceSimulation, index: int) -> bool:
	if data.boss < 0 or data.phases.is_empty():
		return true
	if index != data.boss and sim.arena.ships[index].role != SpaceShipPlacement.Role.WEAKPOINT:
		return true
	return index == data.phases[phase].weakpoint and weakpoint_open()


func on_destroyed(sim: SpaceSimulation, index: int) -> void:
	var placement: SpaceShipPlacement = sim.arena.ships[index]
	if placement.role == SpaceShipPlacement.Role.GENERATOR and placement.parent >= 0:
		sim.ships[placement.parent].shield = 0.0


func shield_online(sim: SpaceSimulation, index: int) -> bool:
	for section in sim.ships.size():
		var placement: SpaceShipPlacement = sim.arena.ships[section]
		if placement.parent == index and placement.role == SpaceShipPlacement.Role.GENERATOR and sim.ships[section].hull <= 0.0:
			return false
	return true


func rotation_ratio(sim: SpaceSimulation, index: int) -> float:
	for section in sim.ships.size():
		var placement: SpaceShipPlacement = sim.arena.ships[section]
		if placement.parent == index and placement.role == SpaceShipPlacement.Role.ENGINE and sim.ships[section].hull <= 0.0:
			return sim.config.damaged_engine_turn
	return 1.0


func next_target(sim: SpaceSimulation) -> int:
	if data.boss >= 0 and not data.phases.is_empty():
		return data.phases[phase].weakpoint
	var nearest: int = -1
	var distance: float = INF
	for index in range(1, sim.ships.size()):
		var ship: SpaceShipState = sim.ships[index]
		if ship.hull <= 0.0 or ship.team == sim.ships[0].team or not sim.arena.ships[index].required:
			continue
		var candidate: float = ship.position.distance_squared_to(sim.ships[0].position)
		if sim.arena.ships[index].role == SpaceShipPlacement.Role.GENERATOR:
			candidate *= 0.1
		if candidate < distance:
			distance = candidate
			nearest = index
	return nearest


func rating(sim: SpaceSimulation) -> int:
	if outcome != Outcome.COMPLETED:
		return 0
	return 1 + int(sim.ships[0].hull / sim.ships[0].data.hull >= sim.config.high_rating_hull) + int(finished_tick <= Ticks.from_seconds(data.par_seconds))


func _finish(sim: SpaceSimulation, result: Outcome) -> void:
	outcome = result
	finished_tick = sim.tick
	sim.emit_event(SpaceEvent.Type.MISSION_FINISHED, -1, int(result), sim.ships[0].position)


func capture() -> Dictionary:
	return {"outcome": int(outcome), "wave": wave, "pending_wave": pending_wave, "wave_ticks": wave_ticks, "phase": phase, "phase_ticks": phase_ticks, "phase_visits": phase_visits.duplicate(), "finished_tick": finished_tick}


func restore(state: Dictionary) -> void:
	for key in state:
		set(key, state[key].duplicate() if key == "phase_visits" else state[key])
