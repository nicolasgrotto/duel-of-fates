class_name BlasterOpsMissionState
extends InfiltrationMissionState

enum AllyOrder { FOLLOW, HOLD, GUARD }
enum OfferBlock { NONE, LIMIT, SUPPLIES, NO_BLASTER, NO_RESERVE, NO_ALLIES, FULL_HEALTH }

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
var barrier_charges: int = 0
var heavy_barrier_charges: int = 0
var last_hit_swing: int = -1
var repair_ticks: int = 0
var supplies: int = 0
var offer_counts: PackedInt32Array = []
var heat_scale: float = 1.0
var damage_scale: float = 1.0
var ally_scale: float = 1.0
var stage_index: int = -1
var stage_ticks: int = 0
var hold_ticks: int = 0
var wave_gap_ticks: int = 0
var ally_order: int = AllyOrder.FOLLOW
var ally_anchor: Vector2 = Vector2.ZERO


func _init(mission_data: BlasterOpsMissionData) -> void:
	super(mission_data)
	definition = mission_data
	intermission_ticks = Ticks.from_seconds(definition.intermission_seconds)
	barrier_charges = definition.barrier_charges
	heavy_barrier_charges = definition.heavy_barrier_charges
	supplies = definition.starting_supplies
	offer_counts.resize(BlasterOpsTraining.SUPPLY_OFFERS.size())


func has_supplies() -> bool:
	return not definition.supply_terminals.is_empty()


func earn_supplies(amount: int) -> void:
	if has_supplies():
		supplies += amount


func nearby_terminal(sim: BlasterOpsSimulation) -> int:
	for index in definition.supply_terminals.size():
		if _reachable(sim, definition.supply_terminals[index]):
			return index
	return -1


func offer_available(sim: BlasterOpsSimulation, index: int) -> bool:
	var block: OfferBlock = offer_block(sim, index)
	return block == OfferBlock.NONE or block == OfferBlock.SUPPLIES


func offer_block(sim: BlasterOpsSimulation, index: int) -> OfferBlock:
	var offer: BlasterOpsSupplyOffer = BlasterOpsTraining.SUPPLY_OFFERS[index]
	if offer.limit > 0 and offer_counts[index] >= offer.limit:
		return OfferBlock.LIMIT
	match offer.kind:
		BlasterOpsSupplyOffer.Kind.COOLANT:
			if sim.loadout.blaster == null:
				return OfferBlock.NO_BLASTER
		BlasterOpsSupplyOffer.Kind.REINFORCEMENT:
			if _next_reserve() < 0:
				return OfferBlock.NO_RESERVE
		BlasterOpsSupplyOffer.Kind.ALLY_UPGRADE:
			if not _has_allies(sim):
				return OfferBlock.NO_ALLIES
		BlasterOpsSupplyOffer.Kind.HEAL:
			if sim.player.health >= sim.operations.health:
				return OfferBlock.FULL_HEALTH
	return OfferBlock.SUPPLIES if supplies < offer.cost else OfferBlock.NONE


func living_allies(sim: BlasterOpsSimulation) -> int:
	var count: int = 0
	for index in sim.prisoners.size():
		if index != definition.protected_index and sim.prisoners[index].health > 0.0 and recruited[index] != 0 and extracted[index] == 0:
			count += 1
	return count


func purchase(sim: BlasterOpsSimulation, index: int) -> bool:
	if index < 0 or index >= BlasterOpsTraining.SUPPLY_OFFERS.size() or nearby_terminal(sim) < 0 or not offer_available(sim, index):
		return false
	var offer: BlasterOpsSupplyOffer = BlasterOpsTraining.SUPPLY_OFFERS[index]
	if supplies < offer.cost:
		return false
	supplies -= offer.cost
	offer_counts[index] += 1
	match offer.kind:
		BlasterOpsSupplyOffer.Kind.HEAL:
			sim.player.health = minf(sim.player.health + offer.amount, sim.operations.health)
		BlasterOpsSupplyOffer.Kind.BARRIER:
			barrier_charges += int(offer.amount)
		BlasterOpsSupplyOffer.Kind.BULWARK:
			heavy_barrier_charges += int(offer.amount)
		BlasterOpsSupplyOffer.Kind.COOLANT:
			heat_scale *= offer.amount
		BlasterOpsSupplyOffer.Kind.COMBAT_TUNE:
			damage_scale *= offer.amount
		BlasterOpsSupplyOffer.Kind.REINFORCEMENT:
			call_reinforcement(sim, definition.supply_terminals[nearby_terminal(sim)] + Vector2.DOWN * sim.map.tile_size)
		BlasterOpsSupplyOffer.Kind.ALLY_UPGRADE:
			ally_scale *= offer.amount
			_restore_allies(sim)
	return true


func _next_reserve() -> int:
	for index in recruited.size():
		if definition.is_reserve(index) and recruited[index] == 0:
			return index
	return -1


func _has_allies(sim: BlasterOpsSimulation) -> bool:
	for index in recruited.size():
		if recruited[index] != 0 and index != definition.protected_index and sim.prisoners[index].health > 0.0:
			return true
	return false


func _restore_allies(sim: BlasterOpsSimulation) -> void:
	for index in recruited.size():
		if recruited[index] != 0 and sim.prisoners[index].health > 0.0:
			sim.prisoners[index].health = sim._ally_max_health(index)


func has_free_allies(sim: BlasterOpsSimulation) -> bool:
	return living_allies(sim) > 0


func guard_point(sim: BlasterOpsSimulation) -> Vector2:
	var protected: int = definition.protected_index
	if protected >= 0 and protected < sim.prisoners.size() and sim.prisoners[protected].health > 0.0 and recruited[protected] != 0:
		return sim.prisoners[protected].position
	for target in definition.defense_targets:
		if sim.targets[target].health > 0.0:
			return sim.targets[target].position
	var stage: BlasterOpsStageData = current_stage()
	if stage != null and stage.objective == BlasterOpsStageData.Objective.HOLD and stage.zone_radius > 0.0:
		return stage.zone
	return Vector2.INF


func cycle_ally_order(sim: BlasterOpsSimulation) -> void:
	if not has_free_allies(sim):
		return
	ally_order = posmod(ally_order + 1, AllyOrder.size())
	if ally_order == AllyOrder.GUARD and guard_point(sim) == Vector2.INF:
		ally_order = AllyOrder.FOLLOW
	if ally_order == AllyOrder.HOLD:
		ally_anchor = sim.player.position


func order_point(sim: BlasterOpsSimulation) -> Vector2:
	if waves_finished:
		return Vector2.INF
	match ally_order:
		AllyOrder.HOLD:
			return ally_anchor
		AllyOrder.GUARD:
			return guard_point(sim)
	return Vector2.INF


func can_deploy() -> bool:
	if barrier_charges + heavy_barrier_charges <= 0:
		return false
	return not definition.barrier_prep_only or intermission_ticks > 0


func setup(sim: BlasterOpsSimulation) -> void:
	if definition.protected_index >= 0:
		recruited[definition.protected_index] = 1
		sim.prisoners[definition.protected_index].health = definition.protected_health
	if definition.phase_target >= 0:
		phase_health = sim.target_data[definition.phase_target].health
		if not definition.phases.is_empty():
			sim.target_data[definition.phase_target] = definition.phases[0].enemy
	for index in sim.prisoners.size():
		var role: BlasterOpsAllyData = definition.ally_role(index)
		if role != null:
			sim.prisoners[index].health = role.health
		if definition.is_reserve(index):
			sim.prisoners[index].health = 0.0


func call_reinforcement(sim: BlasterOpsSimulation, point: Vector2) -> bool:
	for index in sim.prisoners.size():
		if definition.is_reserve(index) and recruited[index] == 0:
			var actor: InfiltrationActor = sim.prisoners[index]
			actor.position = point
			actor.previous = point
			var role: BlasterOpsAllyData = definition.ally_role(index)
			actor.health = role.health if role != null else sim.config.prisoner_health
			recruited[index] = 1
			sim.emit_mission_event(InfiltrationEvent.Type.PRISONER_RECRUITED, index, point)
			return true
	return false


func can_extract(index: int) -> bool:
	return waves_finished or (definition.stages.is_empty() and index == definition.protected_index)


func follower_speed(index: int, base: float) -> float:
	var role: BlasterOpsAllyData = definition.ally_role(index)
	return role.speed if role != null else base


func interact(sim: InfiltrationSimulation) -> void:
	if nearby_object(sim) >= 0:
		super.interact(sim)
	elif nearby_terminal(sim as BlasterOpsSimulation) >= 0:
		return
	elif can_deploy():
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


func current_stage() -> BlasterOpsStageData:
	if stage_index < 0 or stage_index >= definition.stages.size() or waves_finished:
		return null
	return definition.stages[stage_index]


func objective_point(sim: BlasterOpsSimulation) -> Vector2:
	var stage: BlasterOpsStageData = current_stage()
	if stage == null:
		return data.extraction
	match stage.objective:
		BlasterOpsStageData.Objective.HOLD, BlasterOpsStageData.Objective.REACH, BlasterOpsStageData.Objective.ESCORT:
			if stage.zone_radius > 0.0:
				return stage.zone
		BlasterOpsStageData.Objective.INTERACT:
			for terminal in stage.terminals:
				if copied[terminal] == 0:
					return data.terminals[terminal]
		BlasterOpsStageData.Objective.DESTROY:
			var nearest: float = INF
			var point: Vector2 = Vector2.INF
			for target in stage.targets:
				var actor: InfiltrationActor = sim.targets[target]
				if actor.spawned and actor.health > 0.0 and actor.position.distance_squared_to(sim.player.position) < nearest:
					nearest = actor.position.distance_squared_to(sim.player.position)
					point = actor.position
			if point != Vector2.INF:
				return point
	return Vector2.INF


func escort_goal() -> Vector2:
	if definition.stages.is_empty():
		return data.extraction
	var stage: BlasterOpsStageData = current_stage()
	if stage != null and stage.objective == BlasterOpsStageData.Objective.ESCORT:
		return stage.zone
	return data.extraction if waves_finished else Vector2.INF


func _advance_stages(sim: BlasterOpsSimulation) -> void:
	if waves_finished:
		return
	if stage_index < 0:
		_enter_stage(0)
		intermission_ticks = maxi(intermission_ticks, Ticks.from_seconds(definition.intermission_seconds))
	var stage: BlasterOpsStageData = definition.stages[stage_index]
	if intermission_ticks > 0:
		intermission_ticks -= 1
		if intermission_ticks == 0 and stage.first_wave >= 0:
			_start_wave(sim, stage.first_wave)
			wave_gap_ticks = Ticks.from_seconds(stage.wave_gap_seconds)
		return
	stage_ticks += 1
	_spawn_pending(sim)
	_advance_stage_waves(sim, stage)
	if _stage_done(sim, stage):
		_complete_stage(sim, stage)


func _advance_stage_waves(sim: BlasterOpsSimulation, stage: BlasterOpsStageData) -> void:
	if wave_index >= stage.last_wave or stage.last_wave < 0:
		return
	wave_gap_ticks = maxi(wave_gap_ticks - 1, 0)
	var ready: bool = stage.wave_gap_seconds > 0.0 and wave_gap_ticks == 0
	if ready or (_wave_spawned(sim) and enemies_left(sim) == 0):
		_start_wave(sim, wave_index + 1)
		wave_gap_ticks = Ticks.from_seconds(stage.wave_gap_seconds)


func _stage_cleared(sim: BlasterOpsSimulation, stage: BlasterOpsStageData) -> bool:
	return wave_index >= stage.last_wave and _wave_spawned(sim) and enemies_left(sim) == 0


func _stage_done(sim: BlasterOpsSimulation, stage: BlasterOpsStageData) -> bool:
	if stage.requires_clear and not _stage_cleared(sim, stage):
		return false
	match stage.objective:
		BlasterOpsStageData.Objective.DESTROY:
			for target in stage.targets:
				if not sim.targets[target].spawned or sim.targets[target].health > 0.0:
					return false
			return true
		BlasterOpsStageData.Objective.HOLD:
			if stage.zone_radius <= 0.0 or sim.player.position.distance_to(stage.zone) <= stage.zone_radius:
				hold_ticks += 1
			return hold_ticks >= Ticks.from_seconds(stage.hold_seconds)
		BlasterOpsStageData.Objective.REACH:
			return sim.player.position.distance_to(stage.zone) <= stage.zone_radius
		BlasterOpsStageData.Objective.INTERACT:
			for terminal in stage.terminals:
				if copied[terminal] == 0:
					return false
			return true
		BlasterOpsStageData.Objective.ESCORT:
			return sim.prisoners[definition.protected_index].position.distance_to(stage.zone) <= stage.zone_radius
		BlasterOpsStageData.Objective.BOSS:
			return sim.targets[definition.phase_target].spawned and sim.targets[definition.phase_target].health <= 0.0
	return _stage_cleared(sim, stage)


func _complete_stage(sim: BlasterOpsSimulation, stage: BlasterOpsStageData) -> void:
	for cover in stage.opens_covers:
		sim.open_door(cover)
	earn_supplies(stage.supply_reward)
	sim.player.health = minf(sim.player.health + stage.repair_on_complete, sim.operations.health)
	sim._emit(InfiltrationEvent.Type.STAGE_COMPLETED, 0, stage_index, sim.player.position)
	if stage_index + 1 >= definition.stages.size():
		stage_index = definition.stages.size()
		waves_finished = true
		sim._emit(InfiltrationEvent.Type.EXTRACTION_OPENED, 0, -1, data.extraction)
	else:
		_enter_stage(stage_index + 1)


func _enter_stage(index: int) -> void:
	stage_index = index
	stage_ticks = 0
	hold_ticks = 0
	intermission_ticks = maxi(Ticks.from_seconds(definition.stages[index].prep_seconds), 1)


func _advance_waves(sim: BlasterOpsSimulation) -> void:
	if waves_finished:
		return
	if not definition.stages.is_empty():
		_advance_stages(sim)
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
	if index > 0:
		earn_supplies(definition.supply_per_wave)
	wave_index = index
	intermission_ticks = 0
	sim._emit(InfiltrationEvent.Type.WAVE_STARTED, 0, index, sim.player.position)
	_spawn_pending(sim)


func _spawn_pending(sim: BlasterOpsSimulation) -> void:
	var active: int = enemies_left(sim)
	for wave in range(wave_index + 1):
		for index in definition.waves[wave].indices:
			var actor: InfiltrationActor = sim.targets[index]
			if actor.spawned or not sim._spawn_clear(actor.position):
				continue
			if active >= sim.operations.max_active_enemies:
				return
			active += 1
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
	if not definition.stages.is_empty():
		return waves_finished
	if definition.kind == BlasterOpsMissionData.Kind.HOLD_OUT:
		return sim.tick >= Ticks.from_seconds(definition.hold_seconds)
	if definition.kind == BlasterOpsMissionData.Kind.ESCORT:
		return extracted[definition.protected_index] != 0
	for index in definition.defense_targets:
		if sim.targets[index].health > 0.0 or not sim.targets[index].spawned:
			return false
	return waves_finished


func completed_objectives(sim: InfiltrationSimulation) -> int:
	if not definition.stages.is_empty():
		return maxi(stage_index, 0)
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
			if definition.is_reserve(index):
				continue
			if recruited[index] == 0 or sim.prisoners[index].health <= 0.0:
				return false
		return true
	return goal_done(sim)


func capture() -> Dictionary:
	var snapshot: Dictionary = super.capture()
	snapshot["incursion"] = {"wave_index": wave_index, "intermission_ticks": intermission_ticks, "waves_finished": waves_finished, "phase_index": phase_index, "phase_health": phase_health, "damage_taken": damage_taken, "attempts": attempts, "hits": hits, "barriers_placed": barriers_placed, "barrier_charges": barrier_charges, "heavy_barrier_charges": heavy_barrier_charges, "last_hit_swing": last_hit_swing, "repair_ticks": repair_ticks, "supplies": supplies, "offer_counts": offer_counts.duplicate(), "heat_scale": heat_scale, "damage_scale": damage_scale, "ally_scale": ally_scale, "stage_index": stage_index, "stage_ticks": stage_ticks, "hold_ticks": hold_ticks, "wave_gap_ticks": wave_gap_ticks, "ally_order": ally_order, "ally_anchor": ally_anchor}
	return snapshot


func restore(snapshot: Dictionary) -> void:
	super.restore(snapshot)
	for key in snapshot.incursion:
		set(key, snapshot.incursion[key])
