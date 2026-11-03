class_name BlasterOpsMissionPilot
extends RefCounted

var intent: InfiltrationIntent = InfiltrationIntent.new()
var _navigation: InfiltrationNavigation
var _revision: int = -1


func _init(sim: BlasterOpsSimulation) -> void:
	_navigation = InfiltrationNavigation.new(sim.map)


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
	if nearest >= 0:
		var target: InfiltrationActor = sim.targets[nearest]
		intent.aim = (target.position - sim.player.position).normalized()
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
