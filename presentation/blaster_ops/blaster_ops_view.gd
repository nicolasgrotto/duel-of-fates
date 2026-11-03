class_name BlasterOpsView
extends InfiltrationView

enum WeaponState { BLADE = 1, BLASTER = 2, BELT_HILT = 4, SUPPORT_HAND = 8 }
var operations: BlasterOpsSimulation
var emitter: bool = false
var _precision_left: float = 0.0
var _power_left: float = 0.0
var _power_kind: PowerData.Kind = PowerData.Kind.REPULSE
var _power_position: Vector2 = Vector2.ZERO
var _power_aim: Vector2 = Vector2.RIGHT


func setup(simulation: InfiltrationSimulation, look: InfiltrationLook) -> void:
	super.setup(simulation, look)
	operations = simulation as BlasterOpsSimulation


static func weapon_state(loadout: BlasterOpsLoadout, guard: bool, striking: bool, integrated: bool = false) -> int:
	if loadout.blaster == null:
		return WeaponState.BLADE
	if not loadout.blaster.two_handed():
		return WeaponState.BLADE | (0 if integrated else WeaponState.BLASTER)
	return WeaponState.BLADE if guard or striking else WeaponState.BLASTER | WeaponState.BELT_HILT | WeaponState.SUPPORT_HAND


func on_event(event: InfiltrationEvent) -> void:
	super.on_event(event)
	if event.type == InfiltrationEvent.Type.PRECISION_DODGED:
		_precision_left = operations.operations.precision_flash_seconds
	elif event.type == InfiltrationEvent.Type.POWER_RELEASED:
		_power_left = operations.operations.power_effect_seconds
		_power_kind = int(event.amount) as PowerData.Kind
		_power_position = event.position
		_power_aim = operations.state.power_aim
	elif event.type == InfiltrationEvent.Type.COVER_HIT:
		_spark_positions[_next_spark] = event.position
		_spark_left[_next_spark] = sim.config.spark_seconds
		_spark_kinds[_next_spark] = SparkKind.IMPACT
		_next_spark = (_next_spark + 1) % _spark_positions.size()


func _process(delta: float) -> void:
	super._process(delta)
	if animate:
		_precision_left = maxf(_precision_left - delta, 0.0)
		_power_left = maxf(_power_left - delta, 0.0)


func _draw() -> void:
	if operations == null:
		return
	_draw_security()
	if sim.mission != null:
		_draw_mission()
	_draw_telegraphs()
	_draw_powers()
	for index in sim.targets.size():
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0:
			continue
		if index < sim.map.targets.size():
			_draw_actor(actor, SPRITE_DUMMY)
		else:
			var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
			_draw_actor(actor, data.sprite, true, data.texture)
			_draw_awareness(actor)
			var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
			if data.front_damage_ratio < 1.0:
				draw_arc(point, actor.radius + 8.0, actor.aim.angle() - deg_to_rad(data.front_degrees * 0.5), actor.aim.angle() + deg_to_rad(data.front_degrees * 0.5), 8, PALETTE.infiltration_edge, sim.config.units_per_pixel * 2.0)
			if actor.health < data.health:
				draw_line(point + Vector2(-18, 34), point + Vector2(-18 + 36.0 * actor.health / data.health, 34), PALETTE.secondary, sim.config.units_per_pixel)
	if sim.player.health > 0.0:
		_draw_dodge()
		_draw_actor(sim.player, SPRITE_PLAYER)
		var weapons: int = weapon_state(operations.loadout, sim.player.guard, sim.player.swing_tick >= 0, emitter)
		if (weapons & WeaponState.BLADE) != 0:
			_draw_blade()
		if (weapons & WeaponState.BLASTER) != 0:
			_draw_weapon()
		if (weapons & WeaponState.BELT_HILT) != 0:
			_draw_belt_hilt()
		if emitter:
			_draw_emitter()
	_draw_operations_bolts()
	_draw_sparks()
	if debug:
		_draw_debug()
		for cover in operations.arena.covers:
			if cover.health > 0.0:
				draw_rect(Rect2(Vector2(cover.data.cell) * sim.map.tile_size, Vector2.ONE * sim.map.tile_size), PALETTE.potential, false, sim.config.units_per_pixel)


func _draw_weapon() -> void:
	var actor: InfiltrationActor = sim.player
	var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
	_blade.compose(sim.config, actor.aim, _guard_blend, 0.0, 0.0)
	var hand: Vector2 = _snap(point + _blade.off_hand)
	var length: float = operations.loadout.blaster.muzzle.x
	var metal: Color = _look.hilt_color
	draw_set_transform(hand, actor.aim.angle())
	draw_rect(Rect2(-6, -6, length + 6, 12), metal.darkened(0.5))
	draw_rect(Rect2(-4, -4, length + 2, 8), metal)
	draw_line(Vector2(-2, -4), Vector2(length - 4, -4), metal.lightened(0.2), sim.config.units_per_pixel)
	draw_rect(Rect2(length - 2, -4, 4, 8), PALETTE.bolt)
	draw_rect(Rect2(-4, 0, 8, 12), _look.skin_color)
	if operations.loadout.blaster.two_handed():
		draw_rect(Rect2(length * 0.5, 2, 8, 8), _look.skin_color)
	draw_set_transform(Vector2.ZERO)
	if operations.state.overheated:
		for index in 2:
			var offset: Vector2 = Vector2(index * 8.0, -38.0 - fmod(_time * 20.0, 10.0))
			draw_line(_snap(point + offset), _snap(point + offset + Vector2(0, -8)), PALETTE.secondary, sim.config.units_per_pixel)


func _draw_belt_hilt() -> void:
	var actor: InfiltrationActor = sim.player
	var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
	var grip: Vector2 = point - actor.aim * sim.config.blade_hand_forward + actor.aim.orthogonal() * sim.config.blade_hand_side
	_blade._draw_hilt(self, grip - actor.aim * sim.config.blade_hilt_half, grip + actor.aim * sim.config.blade_hilt_half, _look, sim.config)


func _draw_emitter() -> void:
	var actor: InfiltrationActor = sim.player
	var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha) + _blade.hand)
	draw_set_transform(point, actor.aim.angle())
	draw_rect(Rect2(-4, -8, 18, 8), _look.hilt_color)
	draw_rect(Rect2(12, -6, 4, 4), PALETTE.bolt)
	draw_set_transform(Vector2.ZERO)


func _draw_operations_bolts() -> void:
	for candidate in sim.bolts:
		var bolt: BlasterOpsBolt = candidate as BlasterOpsBolt
		if not bolt.active:
			continue
		var point: Vector2 = _snap(bolt.previous.lerp(bolt.position, alpha))
		var direction: Vector2 = bolt.velocity.normalized()
		var tail: Vector2 = _snap(point - direction * sim.config.bolt_length)
		var color: Color = _look.blade_color if bolt.reflected else PALETTE.bolt
		draw_line(tail, point, color, sim.config.blade_width)
		draw_line(tail, point, PALETTE.text, sim.config.units_per_pixel)
		if bolt.owner != 0:
			for side in [-1.0, 1.0]:
				draw_line(point, _snap(point - direction * 8.0 + direction.orthogonal() * side * 4.0), color, sim.config.units_per_pixel)


func _draw_telegraphs() -> void:
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: BlasterOpsActor = sim.targets[index] as BlasterOpsActor
		if actor.health <= 0.0 or actor.telegraph_ticks < 0:
			continue
		var data: BlasterOpsEnemyData = sim.target_data[index] as BlasterOpsEnemyData
		if data == null:
			continue
		var origin: Vector2 = _snap(actor.position)
		var aim: Vector2 = actor.telegraph_aim
		if data.melee_damage > 0.0:
			draw_arc(origin, data.melee_range, aim.angle() - deg_to_rad(data.attack_degrees * 0.5), aim.angle() + deg_to_rad(data.attack_degrees * 0.5), 10, PALETTE.danger, sim.config.units_per_pixel)
			continue
		var muzzle: Vector2 = _snap(origin + aim * (actor.radius + data.bolt.muzzle_forward))
		draw_circle(muzzle, 6.0, Color(PALETTE.bolt, 0.5))
		draw_rect(Rect2(muzzle - Vector2.ONE * 2.0, Vector2.ONE * 4.0), PALETTE.text)
		if data.aim_line:
			var end: Vector2 = origin + aim * data.bolt.max_range
			var wall: float = InfiltrationGeometry.wall_fraction(sim.map, origin, end)
			if wall != INF:
				end = origin.lerp(end, wall)
			draw_line(muzzle, _snap(end), Color(PALETTE.danger, 0.7), sim.config.units_per_pixel)


func _draw_dodge() -> void:
	var point: Vector2 = _snap(sim.player.previous.lerp(sim.player.position, alpha))
	if operations.state.dodge_age >= 0 and not reduced:
		var size: Vector2 = Vector2(sim.config.sprite_pixels) * sim.config.units_per_pixel
		for index in 2:
			var echo: Vector2 = _snap(point - operations.state.dodge_direction * operations.operations.dodge_echo_offset * (index + 1))
			draw_set_transform(echo, sim.player.aim.angle() + PI * 0.5)
			draw_texture_rect(_look.texture, Rect2(-size * 0.5, size), false, Color(1.0, 1.0, 1.0, 0.12 / (index + 1)))
			draw_set_transform(Vector2.ZERO)
	if _precision_left > 0.0:
		draw_arc(point, 24.0, 0.0, TAU, 12, Color(_look.blade_color, _precision_left / operations.operations.precision_flash_seconds), sim.config.units_per_pixel * 2.0)


func _draw_powers() -> void:
	var color: Color = PALETTE.flow_tiers[0]
	var point: Vector2 = _snap(sim.player.previous.lerp(sim.player.position, alpha))
	if operations.state.barrier_health > 0.0:
		for index in 8:
			var angle: float = TAU * index / 8.0
			draw_arc(point, 32.0, angle, angle + 0.5, 3, color, sim.config.units_per_pixel)
	if operations.state.power_ticks > 0:
		draw_arc(point, 26.0, 0.0, TAU, 12, Color(color, 0.4), sim.config.units_per_pixel)
	if _power_left <= 0.0 or _power_kind == PowerData.Kind.BARRIER:
		return
	var progress: float = 1.0 - _power_left / operations.operations.power_effect_seconds
	var radius: float = operations.loadout.power.power.reach * (progress if _power_kind == PowerData.Kind.REPULSE else 1.0 - progress)
	var half: float = deg_to_rad(operations.loadout.power.degrees * 0.5)
	draw_arc(_power_position, maxf(radius, 4.0), _power_aim.angle() - half, _power_aim.angle() + half, 18, Color(color, 1.0 - progress), sim.config.units_per_pixel * (1.0 if reduced else 2.0))
