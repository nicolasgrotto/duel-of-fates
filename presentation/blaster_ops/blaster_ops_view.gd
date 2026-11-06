class_name BlasterOpsView
extends InfiltrationView

enum WeaponState { BLADE = 1, BLASTER = 2, BELT_HILT = 4, SUPPORT_HAND = 8 }
const AURA_SEGMENTS: int = 12
const AURA_DASH: float = 0.28
const SHELL_SIZE: float = 10.0
var operations: BlasterOpsSimulation
var emitter: bool = false
var _precision_left: float = 0.0
var _power_left: float = 0.0
var _power_kind: PowerData.Kind = PowerData.Kind.REPULSE
var _power_position: Vector2 = Vector2.ZERO
var _power_aim: Vector2 = Vector2.RIGHT
var _power_entry: BlasterOpsPowerData
var _blast_positions: PackedVector2Array = []
var _blast_radius: PackedFloat32Array = []
var _blast_left: PackedFloat32Array = []
var _blast_hostile: PackedByteArray = []
var _next_blast: int = 0


func setup(simulation: InfiltrationSimulation, look: InfiltrationLook) -> void:
	super.setup(simulation, look)
	operations = simulation as BlasterOpsSimulation
	var capacity: int = operations.operations.blast_capacity
	_blast_positions.resize(capacity)
	_blast_radius.resize(capacity)
	_blast_left.resize(capacity)
	_blast_left.fill(0.0)
	_blast_hostile.resize(capacity)


static func weapon_state(loadout: BlasterOpsLoadout, blade_drawn: bool, integrated: bool = false) -> int:
	if loadout.blaster == null:
		return WeaponState.BLADE
	if not loadout.switchable:
		return WeaponState.BLADE | (0 if integrated else WeaponState.BLASTER)
	if blade_drawn:
		return WeaponState.BLADE
	return WeaponState.BLASTER | WeaponState.BELT_HILT | (WeaponState.SUPPORT_HAND if loadout.two_handed else 0)


func on_event(event: InfiltrationEvent) -> void:
	super.on_event(event)
	if event.type == InfiltrationEvent.Type.PRECISION_DODGED:
		_precision_left = operations.operations.precision_flash_seconds
	elif event.type == InfiltrationEvent.Type.POWER_RELEASED:
		_power_left = operations.operations.power_effect_seconds
		_power_kind = int(event.amount) as PowerData.Kind
		_power_position = event.position
		_power_aim = operations.state.power_aim
		_power_entry = operations.loadout.slot(operations.state.cast_slot)
	elif event.type == InfiltrationEvent.Type.AREA_BLAST:
		_blast_positions[_next_blast] = event.position
		_blast_radius[_next_blast] = event.amount
		_blast_left[_next_blast] = operations.operations.blast_seconds
		_blast_hostile[_next_blast] = event.target
		_next_blast = (_next_blast + 1) % _blast_left.size()
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
		for index in _blast_left.size():
			_blast_left[index] = maxf(_blast_left[index] - delta, 0.0)


func _draw() -> void:
	if operations == null:
		return
	if not sim.mission is BlasterOpsMissionState or debug:
		_draw_security()
	if sim.mission != null:
		_draw_mission()
		if sim.mission is BlasterOpsMissionState:
			_draw_incursion()
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
			_draw_enemy_support(actor, data as BlasterOpsEnemyData)
			_draw_actor(actor, data.sprite, true, data.texture)
			_draw_awareness(actor)
			var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
			if data.front_damage_ratio < 1.0:
				draw_arc(point, actor.radius + 8.0, actor.aim.angle() - deg_to_rad(data.front_degrees * 0.5), actor.aim.angle() + deg_to_rad(data.front_degrees * 0.5), 8, PALETTE.infiltration_edge, sim.config.units_per_pixel * 2.0)
			if (actor as BlasterOpsActor).stun_ticks > 0:
				draw_arc(point, actor.radius + 6.0, 0.0, TAU, 8, PALETTE.flow_tiers[0], sim.config.units_per_pixel)
			if actor.health < data.health:
				draw_line(point + Vector2(-18, 34), point + Vector2(-18 + 36.0 * actor.health / data.health, 34), PALETTE.secondary, sim.config.units_per_pixel)
	if sim.player.health > 0.0:
		_draw_dodge()
		_draw_actor(sim.player, SPRITE_PLAYER)
		var weapons: int = weapon_state(operations.loadout, operations.state.blade_drawn, emitter)
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


func _prisoner_visible(index: int) -> bool:
	if not sim.mission is BlasterOpsMissionState:
		return true
	return not (sim.mission as BlasterOpsMissionState).definition.is_reserve(index) or sim.mission.recruited[index] != 0


func _prisoner_texture(index: int) -> Texture2D:
	if sim.mission is BlasterOpsMissionState:
		var role: BlasterOpsAllyData = (sim.mission as BlasterOpsMissionState).definition.ally_role(index)
		if role != null:
			return role.texture
	return PRISONER


func _prisoner_max_health(index: int) -> float:
	return operations._ally_max_health(index) if sim.mission is BlasterOpsMissionState else sim.config.prisoner_health


func _draw_enemy_support(actor: InfiltrationActor, data: BlasterOpsEnemyData) -> void:
	if data == null:
		return
	var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
	if data.aura != BlasterOpsEnemyData.Aura.NONE:
		var color: Color = PALETTE.flow_tiers[1] if data.aura == BlasterOpsEnemyData.Aura.SHIELD else PALETTE.text
		for segment in AURA_SEGMENTS:
			var angle: float = TAU * segment / AURA_SEGMENTS
			draw_arc(point, data.aura_radius, angle, angle + AURA_DASH, 4, Color(color, 0.45), sim.config.units_per_pixel)
	if data.stride > 0.0:
		var side: Vector2 = actor.aim.orthogonal() * actor.radius * 0.7
		var cycle: float = sin(actor.position.dot(actor.aim) / data.stride * PI)
		for leg in [1.0, -1.0]:
			var foot: Vector2 = _snap(point + side * leg + actor.aim * data.stride * cycle * leg)
			draw_set_transform(foot, actor.aim.angle() + PI * 0.5)
			draw_rect(Rect2(-10.0, -16.0, 20.0, 32.0), PALETTE.infiltration_wall)
			draw_rect(Rect2(-10.0, -16.0, 20.0, 32.0), PALETTE.infiltration_seam, false, sim.config.units_per_pixel)
			draw_set_transform(Vector2.ZERO)


func _draw_incursion() -> void:
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var data: BlasterOpsMissionData = progress.definition
	if not progress.waves_finished:
		var exit: Vector2 = data.extraction
		draw_line(exit - Vector2.ONE * 14.0, exit + Vector2.ONE * 14.0, PALETTE.secondary, 4.0)
		draw_line(exit + Vector2(-14, 14), exit + Vector2(14, -14), PALETTE.secondary, 4.0)
	if data.protected_index >= 0 and data.kind == BlasterOpsMissionData.Kind.DEFENSE:
		var actor: InfiltrationActor = sim.prisoners[data.protected_index]
		var point: Vector2 = _snap(actor.position)
		draw_rect(Rect2(point - Vector2(28, 24), Vector2(56, 48)), PALETTE.infiltration_wall)
		draw_rect(Rect2(point - Vector2(22, 18), Vector2(44, 26)), PALETTE.accent, false, 4.0)
		draw_line(point + Vector2(-24, 30), point + Vector2(-24 + 48 * actor.health / data.protected_health, 30), PALETTE.text, 4.0)
	if data.phase_target >= 0:
		var actor: InfiltrationActor = sim.targets[data.phase_target]
		if actor.health > 0.0:
			var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
			draw_arc(point, actor.radius + 12.0, 0.0, TAU * actor.health / progress.phase_health, 24, PALETTE.flow_tiers[progress.phase_index], 4.0)
	for index in sim.prisoners.size():
		var actor: InfiltrationActor = sim.prisoners[index]
		if actor.health > 0.0 and progress.recruited[index] != 0 and actor.fire_ticks > 0 and index != data.protected_index:
			var point: Vector2 = _snap(actor.position)
			draw_line(point, _snap(point + actor.aim * 28.0), PALETTE.bolt, 4.0)


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
	if operations.loadout.two_handed:
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
		if bolt.data.size >= SHELL_SIZE:
			draw_circle(point, bolt.data.size, PALETTE.danger)
			draw_circle(point, bolt.data.size * 0.5, PALETTE.bolt)
			continue
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
		if data.bolt == null and data.blast_radius > 0.0:
			draw_arc(origin, data.blast_radius, 0.0, TAU, 24, PALETTE.danger, sim.config.units_per_pixel * 2.0)
			continue
		if data.melee_damage > 0.0 and data.bolt == null:
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
	if operations.state.absorb_ticks > 0:
		draw_arc(point, 34.0, 0.0, TAU, 16, PALETTE.flow_tiers[1], sim.config.units_per_pixel * 2.0)
	if operations.state.heal_ticks > 0:
		draw_arc(point, 30.0, -PI * 0.5, -PI * 0.5 + TAU * operations.state.heal_ticks * Ticks.DELTA, 16, PALETTE.text, sim.config.units_per_pixel)
	if operations.state.boost_ticks > 0:
		draw_arc(point, 28.0, 0.0, TAU, 12, PALETTE.ember, sim.config.units_per_pixel * (1.0 if reduced else 2.0))
	if operations.state.channel_target >= 0:
		draw_line(point, _snap(sim.targets[operations.state.channel_target].position), color, sim.config.units_per_pixel * 2.0)
	_draw_blasts()
	if _power_left <= 0.0 or _power_entry == null or _power_entry.effect != BlasterOpsPowerData.Effect.CONE:
		return
	var progress: float = 1.0 - _power_left / operations.operations.power_effect_seconds
	var radius: float = _power_entry.power.reach * (progress if _power_kind == PowerData.Kind.REPULSE else 1.0 - progress)
	var half: float = deg_to_rad(_power_entry.degrees * 0.5)
	draw_arc(_power_position, maxf(radius, 4.0), _power_aim.angle() - half, _power_aim.angle() + half, 18, Color(color, 1.0 - progress), sim.config.units_per_pixel * (1.0 if reduced else 2.0))


func _draw_blasts() -> void:
	for index in _blast_left.size():
		if _blast_left[index] <= 0.0:
			continue
		var remaining: float = _blast_left[index] / operations.operations.blast_seconds
		var color: Color = PALETTE.danger if _blast_hostile[index] == BlasterOpsFaction.Side.HOSTILE else PALETTE.flow_tiers[0]
		var radius: float = _blast_radius[index] * (1.0 - remaining * remaining)
		draw_arc(_blast_positions[index], maxf(radius, 4.0), 0.0, TAU, 20, Color(color, remaining), sim.config.units_per_pixel * (1.0 if reduced else 2.0))
