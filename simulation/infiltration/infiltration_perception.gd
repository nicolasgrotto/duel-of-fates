class_name InfiltrationPerception
extends RefCounted


static func sees(sim: InfiltrationSimulation, index: int) -> bool:
	var actor: InfiltrationActor = sim.targets[index]
	var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
	return actor.health > 0.0 and InfiltrationGeometry.in_sector(actor.position, actor.aim, sim.player.position, data.vision_range, data.vision_degrees) and InfiltrationGeometry.wall_fraction(sim.map, actor.position, sim.player.position) == INF


static func visible_prisoner(sim: InfiltrationSimulation, index: int) -> int:
	if sim.mission == null:
		return -1
	var actor: InfiltrationActor = sim.targets[index]
	var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
	var nearest: int = -1
	var distance: float = INF
	for prisoner in sim.prisoners.size():
		var body: InfiltrationActor = sim.prisoners[prisoner]
		if body.health <= 0.0 or sim.mission.recruited[prisoner] == 0 or sim.mission.extracted[prisoner] != 0:
			continue
		var candidate: float = actor.position.distance_squared_to(body.position)
		if candidate >= distance or not InfiltrationGeometry.in_sector(actor.position, actor.aim, body.position, data.vision_range, data.vision_degrees):
			continue
		if InfiltrationGeometry.wall_fraction(sim.map, actor.position, body.position) == INF:
			distance = candidate
			nearest = prisoner
	return nearest


static func has_shot(sim: InfiltrationSimulation, index: int) -> bool:
	return sim.targets[index].target_prisoner >= 0 or sees(sim, index)


static func step(sim: InfiltrationSimulation) -> void:
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0:
			continue
		if actor.awareness != InfiltrationActor.Awareness.ALERTED or sim.alerted_bodies <= sim.config.sight_stagger_above or (sim.tick + index) % sim.config.alerted_sight_period == 0:
			actor.visible_player = sees(sim, index)
			actor.target_prisoner = visible_prisoner(sim, index)
		elif actor.target_prisoner >= 0 and not sim.prisoner_exposed(actor.target_prisoner):
			actor.target_prisoner = -1
		if actor.target_prisoner >= 0 and actor.visible_player and not (sim.target_data[index] as InfiltrationEnemyData).prefers_prisoners:
			if actor.position.distance_squared_to(sim.player.position) <= actor.position.distance_squared_to(sim.prisoners[actor.target_prisoner].position):
				actor.target_prisoner = -1
		if actor.target_prisoner >= 0:
			actor.last_known = sim.prisoners[actor.target_prisoner].position
			actor.memory_ticks = Ticks.from_seconds(sim.config.alert_memory)
			actor.suspicion = minf(actor.suspicion + sim.config.vision_gain * Ticks.DELTA, 1.0)
		elif actor.visible_player:
			actor.last_known = sim.player.position
			actor.memory_ticks = Ticks.from_seconds(sim.config.alert_memory)
			var scale: float = sim.config.sneak_visibility if sim.player.locomotion == InfiltrationActor.Locomotion.SNEAK else 1.0
			actor.suspicion = minf(actor.suspicion + sim.config.vision_gain * scale * Ticks.DELTA, 1.0)
		else:
			actor.memory_ticks = maxi(actor.memory_ticks - 1, 0)
			if actor.awareness != InfiltrationActor.Awareness.ALERTED or actor.memory_ticks == 0:
				actor.suspicion = maxf(actor.suspicion - sim.config.suspicion_decay * Ticks.DELTA, 0.0)
		update_awareness(sim, index)


static func noise(sim: InfiltrationSimulation, position: Vector2, radius: float, source: int) -> void:
	sim._emit(InfiltrationEvent.Type.NOISE_EMITTED, source, -1, position, radius)
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0 or source == index + 1 or actor.position.distance_squared_to(position) > radius * radius:
			continue
		if not actor.visible_player and actor.awareness != InfiltrationActor.Awareness.ALERTED:
			actor.last_known = position
			actor.suspicion = maxf(actor.suspicion, sim.config.noise_suspicion)
			update_awareness(sim, index)


static func alert(sim: InfiltrationSimulation, index: int, position: Vector2) -> void:
	var actor: InfiltrationActor = sim.targets[index]
	actor.suspicion = 1.0
	actor.last_known = position
	actor.memory_ticks = Ticks.from_seconds(sim.config.alert_memory)
	update_awareness(sim, index)


static func update_awareness(sim: InfiltrationSimulation, index: int) -> void:
	var actor: InfiltrationActor = sim.targets[index]
	var before: InfiltrationActor.Awareness = actor.awareness
	if actor.suspicion >= 1.0 or (before == InfiltrationActor.Awareness.ALERTED and actor.memory_ticks > 0):
		actor.awareness = InfiltrationActor.Awareness.ALERTED
	elif actor.suspicion >= sim.config.suspicious_threshold:
		actor.awareness = InfiltrationActor.Awareness.SUSPICIOUS
	else:
		actor.awareness = InfiltrationActor.Awareness.UNAWARE
	if before != actor.awareness:
		sim._emit(InfiltrationEvent.Type.AWARENESS_CHANGED, index + 1, -1, actor.position, float(actor.awareness))
