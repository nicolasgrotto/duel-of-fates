class_name PowerEffects

const ROCK_SPACING: float = 0.12
const ROCK_LIFT: float = 18.0
const SECOND_CLEAVE_DELAY: float = 0.15
const APEX_TIER: int = 3
const FISSURE_REACH: float = 120.0
const FISSURE_DELAY: float = 0.2
const RAIN_SPREAD: Array[float] = [0.0, -90.0, 90.0, -45.0, 45.0, -150.0, 150.0]
const RAIN_SPACING: float = 0.22
const RAIN_MARK: float = 0.5
const RAIN_RADIUS: float = 42.0
const STORM_MARK: float = 0.5
const STORM_NEAR: float = 50.0
const STORM_SPREAD: float = 420.0


static func activate(sim: MatchSimulation, caster: FighterState) -> void:
	var power: PowerData = caster.power
	var target: FighterState = sim.opponent_of(caster)
	caster.power_ticks = 0
	caster.power_cooldown = Ticks.from_seconds(sim.config.flow.shared_cooldown)
	var own_cooldown: float = power.cooldown_for(caster.flow_level)
	if own_cooldown > 0.0:
		caster.power_cooldowns[caster.power_slot] = Ticks.from_seconds(own_cooldown)
	var event: CombatEvent = sim.emit(CombatEvent.Type.POWER_ACTIVE, caster.index, target.index)
	event.power = power
	event.amount = caster.flow_tier
	event.position = Vector2(caster.x + caster.facing * 30.0, caster.y + 100.0)
	match power.kind:
		PowerData.Kind.REPULSE:
			_repulse(sim, caster, target, power)
		PowerData.Kind.PULL:
			_pull(sim, caster, target, power)
		PowerData.Kind.THROW:
			caster.spawned = 0
		PowerData.Kind.MIND_TWIST:
			_mind_twist(sim, caster, target, power)
		PowerData.Kind.SUPREME_PUSH:
			_supreme_push(sim, caster, target, power)
		PowerData.Kind.FRACTURE:
			_fracture(sim, caster, power)
		PowerData.Kind.HEAL:
			_heal(sim, caster, power)
		PowerData.Kind.FOCUS:
			caster.focus_ticks = Ticks.from_seconds(power.duration * caster.flow_potency)
		PowerData.Kind.SANCTUARY:
			caster.sanctuary_ticks = Ticks.from_seconds(power.duration)
			caster.sanctuary_hp = power.strength * caster.flow_potency
		PowerData.Kind.MASS_TELEKINESIS:
			_mass_telekinesis(sim, caster, target, power)
		PowerData.Kind.FLOW_CLEAVE:
			_spawn_cleave(sim, caster, power)
			caster.spawned = 1
		PowerData.Kind.FREEZE:
			_freeze(sim, caster, target, power)
		PowerData.Kind.CHOKE:
			if not _choke(sim, caster, target, power):
				_to_recovery(caster)
				return
		PowerData.Kind.WRATH:
			caster.wrath_ticks = Ticks.from_seconds(power.duration * caster.flow_potency)
			caster.wrath_armor = sim.config.flow.wrath_armor
		PowerData.Kind.ARSENAL:
			caster.arsenal_count = int(power.tier_value(caster.flow_tier))
			caster.arsenal_ticks = Ticks.from_seconds(power.duration)
	if power.is_channeled() or power.kind == PowerData.Kind.STORM:
		caster.power_phase = FighterState.Phase.ACTIVE
		caster.state = FighterState.State.CHANNELING
		caster.pulse_ticks = 0
		caster.spawned = 0
	elif power.kind == PowerData.Kind.THROW:
		caster.power_phase = FighterState.Phase.ACTIVE
	else:
		_to_recovery(caster)


static func sustain(sim: MatchSimulation, caster: FighterState, intent: Intent) -> void:
	var power: PowerData = caster.power
	var target: FighterState = sim.opponent_of(caster)
	caster.vx = 0.0
	match power.kind:
		PowerData.Kind.THROW:
			_throw_step(sim, caster, power)
			return
		PowerData.Kind.STORM:
			_storm_step(sim, caster, target, power)
			return
	if power.is_channeled():
		var held: bool = intent.is_held(Intent.Command.POWER) if caster.power_slot != FighterState.FOURTH_SLOT else intent.is_held(Intent.Command.POWER) or intent.is_held(Intent.Command.SPECIAL)
		var expired: bool = caster.power_ticks >= Ticks.from_seconds(power.max_channel)
		caster.flow -= power.cost_per_second * Ticks.DELTA
		if not held or expired or caster.flow <= 0.0:
			caster.flow = maxf(caster.flow, 0.0)
			end_channel(sim, caster)
			return
	match power.kind:
		PowerData.Kind.LIGHTNING:
			_lightning_pulse(sim, caster, target, power)
		PowerData.Kind.CHOKE:
			_choke_step(sim, caster, target, power)
		PowerData.Kind.DRAIN:
			_drain_step(sim, caster, target, power)


static func recovering(sim: MatchSimulation, caster: FighterState) -> void:
	var power: PowerData = caster.power
	if power.kind == PowerData.Kind.FLOW_CLEAVE and caster.flow_tier >= APEX_TIER and caster.spawned == 1:
		if caster.power_ticks >= Ticks.from_seconds(SECOND_CLEAVE_DELAY):
			_spawn_cleave(sim, caster, power)
			caster.spawned = 2


static func end_channel(sim: MatchSimulation, caster: FighterState) -> void:
	if caster.state != FighterState.State.CHANNELING:
		return
	_release_choke(sim, caster)
	_to_recovery(caster)
	var event: CombatEvent = sim.emit(CombatEvent.Type.POWER_ENDED, caster.index, sim.opponent_of(caster).index)
	event.power = caster.power


static func release(sim: MatchSimulation, caster: FighterState) -> void:
	_release_choke(sim, caster)


static func _to_recovery(caster: FighterState) -> void:
	caster.power_phase = FighterState.Phase.RECOVERY
	caster.power_ticks = 0
	caster.state = FighterState.State.CASTING


static func in_front(sim: MatchSimulation, caster: FighterState, target: FighterState, reach: float) -> bool:
	var dx: float = (target.x - caster.x) * caster.facing
	if dx < 0.0:
		return false
	var gap: float = dx - sim.config.body_width
	return gap <= reach and absf(target.y - caster.y) <= sim.config.flow.vertical_reach


static func around(sim: MatchSimulation, caster: FighterState, target: FighterState, reach: float) -> bool:
	var gap: float = absf(target.x - caster.x) - sim.config.body_width
	return gap <= reach and absf(target.y - caster.y) <= sim.config.flow.vertical_reach


static func _impact(sim: MatchSimulation, caster: FighterState, power: PowerData) -> PowerImpact:
	sim.impact.reset(power, caster)
	return sim.impact


static func _repulse(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if not in_front(sim, caster, target, power.reach):
		return
	var impact: PowerImpact = _impact(sim, caster, power)
	impact.damage = power.damage
	impact.push = power.tier_value(caster.flow_tier)
	impact.stagger = power.stagger
	PowerHit.resolve(sim, caster, target, power, impact)


static func _pull(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if not in_front(sim, caster, target, power.tier_value(caster.flow_tier)):
		return
	var impact: PowerImpact = _impact(sim, caster, power)
	impact.damage = power.damage
	var gap: float = absf(target.x - caster.x) - sim.config.body_width
	impact.push = -sim.config.slide_speed_for(gap)
	impact.stagger = power.stagger
	PowerHit.resolve(sim, caster, target, power, impact)


static func _mind_twist(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if not in_front(sim, caster, target, power.reach):
		return
	var impact: PowerImpact = _impact(sim, caster, power)
	impact.ignore_guard = true
	if PowerHit.resolve(sim, caster, target, power, impact) == PowerHit.Result.HIT:
		var table: InteractionTable = power.interaction if power.interaction != null else sim.basic_table
		target.twisted_ticks = Ticks.from_seconds(power.duration * table.band_for(caster.flow_level - target.flow_level).scale)


static func _supreme_push(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if not around(sim, caster, target, power.reach):
		return
	var impact: PowerImpact = _impact(sim, caster, power)
	impact.damage = power.escape_damage if caster.power_escape else power.damage
	impact.push = power.tier_value(caster.flow_tier)
	impact.stagger = power.stagger
	PowerHit.resolve(sim, caster, target, power, impact)


static func _fracture(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	var limit: float = sim.config.half_width()
	var start: float = caster.x + caster.facing * sim.config.body_width * 0.5
	var width: float = power.reach
	var group: int = sim.next_hazard_group()
	var x: float = start + caster.facing * width * 0.5
	while absf(x) <= limit:
		var distance: float = absf(x - start)
		var delay: float = distance / power.speed + power.duration
		sim.spawn_hazard(Hazard.Kind.FRACTURE, caster, x, width * 0.5, delay, group, power.damage, power)
		x += caster.facing * width


static func _heal(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	var lost: float = caster.max_health - caster.health
	var total: float = minf(power.strength * caster.flow_potency, lost * sim.config.flow.heal_lost_ratio)
	caster.heal_ticks = Ticks.from_seconds(power.duration)
	caster.heal_per_tick = total / maxf(caster.heal_ticks, 1)


static func _mass_telekinesis(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	var impacts: int = int(power.tier_value(caster.flow_tier))
	var group: int = sim.next_hazard_group()
	for i in impacts:
		var offset: float = RAIN_SPREAD[i % RAIN_SPREAD.size()] + sim.rng.randf_range(-power.reach * 0.1, power.reach * 0.1)
		var delay: float = RAIN_MARK + i * RAIN_SPACING
		sim.spawn_hazard(Hazard.Kind.ROCK_DROP, caster, target.x + offset, RAIN_RADIUS, delay, group + i, power.damage, power)
	sim.skip_hazard_groups(impacts)
	caster.rain_ticks = Ticks.from_seconds(RAIN_MARK + impacts * RAIN_SPACING)


static func _spawn_cleave(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.CLEAVE, caster, power)
	if projectile == null:
		return
	projectile.damage = power.damage
	projectile.vx = caster.facing * power.speed
	projectile.max_distance = power.reach
	projectile.size = 28.0


static func _throw_step(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	var count: int = int(power.tier_value(caster.flow_tier))
	var spacing: int = Ticks.from_seconds(ROCK_SPACING)
	if caster.spawned < count and caster.power_ticks >= caster.spawned * spacing:
		var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.ROCK, caster, power)
		if projectile != null:
			projectile.damage = power.damage_for(caster.flow_level)
			projectile.vx = caster.facing * power.speed_for(caster.flow_level)
			projectile.max_distance = power.reach
			projectile.y += (caster.spawned % 2) * ROCK_LIFT
			projectile.size = 8.0 + caster.flow_level * 1.4
		caster.spawned += 1
	if caster.spawned >= count:
		_to_recovery(caster)


static func _freeze(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if not in_front(sim, caster, target, power.reach):
		return
	var impact: PowerImpact = _impact(sim, caster, power)
	var band: InteractionBand = power.interaction.band_for(caster.flow_level - target.flow_level)
	if PowerHit.resolve(sim, caster, target, power, impact) == PowerHit.Result.HIT:
		_hold(sim, target, Ticks.from_seconds(power.duration * band.scale), false)


static func _choke(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> bool:
	if not in_front(sim, caster, target, power.reach):
		return false
	var impact: PowerImpact = _impact(sim, caster, power)
	var band: InteractionBand = power.interaction.band_for(caster.flow_level - target.flow_level)
	if PowerHit.resolve(sim, caster, target, power, impact) != PowerHit.Result.HIT:
		return false
	_hold(sim, target, Ticks.from_seconds(power.max_channel * band.scale), true)
	caster.pulse_ticks = 0
	return true


static func _choke_step(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if target.state != FighterState.State.HELD or not target.held_by_choke:
		end_channel(sim, caster)
		return
	var band: InteractionBand = power.interaction.band_for(caster.flow_level - target.flow_level)
	target.held_ticks -= 1
	if target.held_ticks <= 0:
		end_channel(sim, caster)
		return
	var lift: float = sim.config.flow.choke_lift
	target.y = minf(target.y + sim.config.flow.choke_lift_speed * Ticks.DELTA, lift)
	target.vy = 0.0
	target.on_ground = false
	if sim.apply_damage(target, power.damage * band.scale * Ticks.DELTA):
		sim.kill(target, caster, null)
		end_channel(sim, caster)


static func _release_choke(sim: MatchSimulation, caster: FighterState) -> void:
	if caster.power == null or caster.power.kind != PowerData.Kind.CHOKE:
		return
	var target: FighterState = sim.opponent_of(caster)
	if target.state == FighterState.State.HELD and target.held_by_choke:
		target.held_ticks = 0
		target.held_by_choke = false
		sim.change_state(target, FighterState.State.JUMPING)


static func _hold(sim: MatchSimulation, target: FighterState, ticks: int, choke: bool) -> void:
	sim.change_state(target, FighterState.State.HELD)
	target.held_ticks = maxi(ticks, 1)
	target.held_by_choke = choke
	target.vx = 0.0


static func _lightning_pulse(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	caster.pulse_ticks -= 1
	if caster.pulse_ticks > 0:
		return
	caster.pulse_ticks = Ticks.from_seconds(power.pulse_interval)
	if not in_front(sim, caster, target, power.reach):
		return
	var impact: PowerImpact = _impact(sim, caster, power)
	impact.damage = power.damage
	impact.hold = power.stagger
	impact.guard_vigor = power.guard_vigor
	impact.grants_flow = false
	PowerHit.resolve(sim, caster, target, power, impact)


static func _drain_step(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	if not in_front(sim, caster, target, power.reach) or not target.is_alive():
		end_channel(sim, caster)
		return
	var difference: int = caster.flow_level - target.flow_level
	var band: InteractionBand = sim.basic_table.band_for(difference)
	if band.resisted:
		end_channel(sim, caster)
		return
	var stolen_flow: float = minf(power.strength * band.scale * Ticks.DELTA, target.flow)
	var stolen_vigor: float = minf(power.damage * band.scale * Ticks.DELTA, target.vigor)
	target.flow -= stolen_flow
	target.vigor -= stolen_vigor
	var returned: float = sim.config.flow.drain_return_ratio
	sim.gain_flow(caster, stolen_flow * returned)
	sim.gain_vigor(caster, stolen_vigor * returned)


static func _storm_step(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	var interval: int = Ticks.from_seconds(power.pulse_interval)
	var mark: int = Ticks.from_seconds(STORM_MARK)
	var storm_ticks: int = Ticks.from_seconds(power.duration)
	if caster.power_ticks + mark <= storm_ticks and (caster.power_ticks - 1) % interval == 0:
		_storm_wave(sim, caster, target, power)
	if caster.power_ticks >= storm_ticks:
		end_channel(sim, caster)


static func _storm_wave(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> void:
	var bolts: int = int(power.tier_value(caster.flow_tier))
	var group: int = sim.next_hazard_group()
	for i in bolts:
		var x: float = target.x + (STORM_NEAR if i == 0 else -STORM_NEAR)
		if i >= 2:
			x = target.x + sim.rng.randf_range(-STORM_SPREAD, STORM_SPREAD)
		x = clampf(x, -sim.config.half_width(), sim.config.half_width())
		sim.spawn_hazard(Hazard.Kind.BOLT, caster, x, 26.0, STORM_MARK, group, power.damage, power)


static func apex_fissures(sim: MatchSimulation, caster: FighterState, from_x: float, power: PowerData) -> void:
	var group: int = sim.next_hazard_group()
	for side in [-1.0, 1.0]:
		var x: float = from_x + side * FISSURE_REACH * 0.5
		sim.spawn_hazard(Hazard.Kind.FRACTURE, caster, x, FISSURE_REACH * 0.5, FISSURE_DELAY, group, power.damage, power)


static func launch_arsenal(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	caster.arsenal_count -= 1
	var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.ARSENAL, caster, power)
	if projectile == null:
		return
	projectile.damage = sim.config.flow.arsenal_damage
	projectile.vx = caster.facing * sim.config.flow.arsenal_launch_speed
	projectile.max_distance = sim.config.arena_width
	projectile.size = 14.0
