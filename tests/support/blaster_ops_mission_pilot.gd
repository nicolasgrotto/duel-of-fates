class_name BlasterOpsMissionPilot
extends RefCounted

var intent: InfiltrationIntent = InfiltrationIntent.new()
var _navigation: InfiltrationNavigation
var _revision: int = -1
const ENGAGE_RANGE: float = 260.0
const FREE_RANGE: float = 900.0
const LOW_HEALTH: float = 60.0
const HOLD_MARGIN: float = 220.0
const SHOOT_RANGE: float = 620.0
const KEEP_AWAY: float = 150.0
const HEAT_CEILING: float = 80.0


func _init(sim: BlasterOpsSimulation) -> void:
	_navigation = InfiltrationNavigation.new(sim.map)


func _objective(sim: BlasterOpsSimulation, progress: BlasterOpsMissionState) -> Vector2:
	var stage: BlasterOpsStageData = progress.current_stage()
	if stage == null:
		return Vector2.INF
	if stage.objective == BlasterOpsStageData.Objective.ESCORT:
		var actor: InfiltrationActor = sim.prisoners[progress.definition.protected_index]
		return actor.position + (stage.zone - actor.position).normalized() * 100.0
	return progress.objective_point(sim)


func _resupply(sim: BlasterOpsSimulation, progress: BlasterOpsMissionState) -> bool:
	var heal: int = 0
	if sim.player.health >= LOW_HEALTH or progress.supplies < BlasterOpsTraining.SUPPLY_OFFERS[heal].cost or not progress.has_supplies():
		return false
	var best: Vector2 = Vector2.INF
	var best_tiles: int = 0
	for terminal in progress.definition.supply_terminals:
		var tiles: int = _navigation.path_tiles(sim.player.position, terminal)
		if tiles != InfiltrationNavigation.NONE and tiles * sim.map.tile_size <= FREE_RANGE and (best == Vector2.INF or tiles < best_tiles):
			best = terminal
			best_tiles = tiles
	if best == Vector2.INF:
		return false
	intent.aim = (best - sim.player.position).normalized()
	if progress.nearby_terminal(sim) >= 0:
		intent.purchase = heal
	else:
		intent.movement = _navigation.direction(sim.player.position, best, sim.player.radius)
	return true


func _free_nearby_ally(sim: BlasterOpsSimulation, progress: BlasterOpsMissionState) -> bool:
	for index in sim.prisoners.size():
		if progress.recruited[index] != 0 or sim.prisoners[index].health <= 0.0:
			continue
		var point: Vector2 = sim.prisoners[index].position
		var tiles: int = _navigation.path_tiles(sim.player.position, point)
		if tiles == InfiltrationNavigation.NONE or tiles * sim.map.tile_size > FREE_RANGE:
			continue
		intent.aim = (point - sim.player.position).normalized()
		if sim.player.position.distance_to(point) <= sim.config.interaction_range:
			intent.pressed = InfiltrationIntent.INTERACT
		else:
			intent.movement = _navigation.direction(sim.player.position, point, sim.player.radius)
		return true
	return false


func _outside_hold(progress: BlasterOpsMissionState, point: Vector2) -> bool:
	var stage: BlasterOpsStageData = progress.current_stage()
	return stage != null and stage.objective == BlasterOpsStageData.Objective.HOLD and stage.zone_radius > 0.0 and point.distance_to(stage.zone) > stage.zone_radius + HOLD_MARGIN


func _guard_toward_nearest(sim: BlasterOpsSimulation) -> void:
	var nearest: float = INF
	for actor in sim.targets:
		if actor.health > 0.0 and actor.spawned and actor.position.distance_squared_to(sim.player.position) < nearest:
			nearest = actor.position.distance_squared_to(sim.player.position)
			intent.aim = (actor.position - sim.player.position).normalized()
	if nearest < INF:
		intent.held = Intent.Command.BLOCK


func _avoid_blast(sim: BlasterOpsSimulation) -> bool:
	for index in sim.targets.size():
		var actor: BlasterOpsActor = sim.targets[index] as BlasterOpsActor
		var data: BlasterOpsEnemyData = sim.target_data[index] as BlasterOpsEnemyData
		if data == null or actor.health <= 0.0 or data.bolt != null or data.blast_radius <= 0.0 or actor.telegraph_ticks < 0:
			continue
		if actor.position.distance_to(sim.player.position) <= data.blast_radius + sim.player.radius:
			var away: Vector2 = (sim.player.position - actor.position).normalized()
			intent.aim = -away
			intent.movement = away
			intent.held = InfiltrationIntent.RUN
			if sim.state.dodge_cooldown == 0:
				intent.pressed = Intent.Command.DODGE
			return true
	return false


func _shoot_at(sim: BlasterOpsSimulation, target: InfiltrationActor, distance: float) -> bool:
	if sim.loadout.blaster == null or sim.loadout.integrated or sim.state.overheated or sim.state.heat >= HEAT_CEILING:
		return false
	if distance > SHOOT_RANGE * SHOOT_RANGE or sim.wall_for(BlasterOpsFaction.Side.ALLIED, sim.player.position, target.position) != INF:
		return false
	if sim.loadout.switchable and sim.state.blade_drawn:
		intent.pressed = InfiltrationIntent.SWITCH_WEAPON if sim.state.switch_ticks == 0 else 0
		return true
	intent.held = Intent.Command.LIGHT
	if distance < KEEP_AWAY * KEEP_AWAY:
		intent.movement = -intent.aim
	return true


func _reachable(sim: BlasterOpsSimulation, point: Vector2) -> bool:
	return _navigation.path_tiles(sim.player.position, point) != InfiltrationNavigation.NONE


func _travel(sim: BlasterOpsSimulation, progress: BlasterOpsMissionState, point: Vector2) -> void:
	intent.aim = (point - sim.player.position).normalized()
	var stage: BlasterOpsStageData = progress.current_stage()
	if stage != null and stage.objective == BlasterOpsStageData.Objective.HOLD and sim.player.position.distance_to(point) <= stage.zone_radius * 0.6:
		_guard_toward_nearest(sim)
		return
	if progress.nearby_object(sim) >= 0 and sim.player.position.distance_to(point) <= sim.config.interaction_range:
		intent.pressed = InfiltrationIntent.INTERACT
		return
	if sim.player.position.distance_to(point) > 16.0:
		intent.movement = _navigation.direction(sim.player.position, point, sim.player.radius)


func produce(sim: BlasterOpsSimulation) -> InfiltrationIntent:
	intent.clear()
	if _revision != sim.cover_revision:
		_navigation.invalidate()
		_revision = sim.cover_revision
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var nearest: int = -1
	var distance: float = INF
	for index in sim.targets.size():
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health > 0.0 and actor.spawned and actor.position.distance_squared_to(sim.player.position) < distance:
			nearest = index
			distance = actor.position.distance_squared_to(sim.player.position)
	if _avoid_blast(sim):
		return intent
	if (nearest < 0 or distance > ENGAGE_RANGE * ENGAGE_RANGE) and _resupply(sim, progress):
		return intent
	if (nearest < 0 or distance > ENGAGE_RANGE * ENGAGE_RANGE) and _free_nearby_ally(sim, progress):
		return intent
	var objective: Vector2 = _objective(sim, progress)
	if objective != Vector2.INF and (nearest < 0 or distance > ENGAGE_RANGE * ENGAGE_RANGE or not _reachable(sim, sim.targets[nearest].position) or _outside_hold(progress, sim.targets[nearest].position)):
		_travel(sim, progress, objective)
		return intent
	if nearest >= 0:
		var target: InfiltrationActor = sim.targets[nearest]
		intent.aim = (target.position - sim.player.position).normalized()
		if _shoot_at(sim, target, distance):
			return intent
		var enemy: InfiltrationEnemyData = sim.target_data[nearest] as InfiltrationEnemyData
		if distance < sim.loadout.power.power.reach * sim.loadout.power.power.reach and sim.state.power_cooldown == 0:
			intent.pressed = Intent.Command.POWER
			intent.held = Intent.Command.BLOCK
			return intent
		if enemy.front_damage_ratio < 1.0 and distance < 150.0 * 150.0 and InfiltrationGeometry.in_sector(target.position, target.aim, sim.player.position, INF, enemy.front_degrees):
			intent.movement = intent.aim.orthogonal()
			intent.held = InfiltrationIntent.RUN
		elif distance > 96.0 * 96.0:
			intent.movement = _navigation.direction(sim.player.position, target.position, sim.player.radius)
			intent.held = Intent.Command.BLOCK
		else:
			intent.movement = intent.aim * 0.5 if distance > 70.0 * 70.0 else Vector2.ZERO
			intent.held = Intent.Command.LIGHT if sim.loadout.blaster == null else 0
			intent.pressed = Intent.Command.HEAVY if sim.player.swing_tick < 0 else 0
		for bolt in sim.bolts:
			if bolt.active and bolt.owner != 0 and bolt.position.distance_to(sim.player.position) < 130.0 and sim.player.parry_cooldown == 0 and sim.player.swing_tick < 0:
				intent.pressed = Intent.Command.BLOCK
				intent.held = Intent.Command.BLOCK
				break
		return intent
	var destination: Vector2 = progress.data.extraction
	if progress.definition.kind == BlasterOpsMissionData.Kind.ESCORT and progress.extracted[progress.definition.protected_index] == 0:
		var actor: InfiltrationActor = sim.prisoners[progress.definition.protected_index]
		destination = actor.position + (destination - actor.position).normalized() * 100.0
	else:
		for index in sim.prisoners.size():
			if progress.recruited[index] == 0 and sim.prisoners[index].health > 0.0:
				destination = sim.prisoners[index].position
				if sim.player.position.distance_to(destination) <= sim.config.interaction_range:
					intent.pressed = InfiltrationIntent.INTERACT
				break
	intent.aim = (destination - sim.player.position).normalized()
	if sim.player.position.distance_to(destination) > 16.0:
		intent.movement = _navigation.direction(sim.player.position, destination, sim.player.radius)
	return intent
