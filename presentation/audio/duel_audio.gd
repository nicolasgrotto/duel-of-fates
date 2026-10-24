class_name DuelAudio
extends Node

const HUM_DB: float = -14.0
const HUM_ACTIVE_DB: float = -6.0
const HUM_ACTIVE_PITCH: float = 1.12
const HUM_FOLLOW: float = 12.0
const HEARTBEAT_RATIO: float = 0.25
const HEARTBEAT_INTERVAL: float = 0.9
const STEP_INTERVAL: float = 0.32
const KNOCKOUT_MUFFLE: float = 1.1
const LOCK_DUCK: float = 0.5
const PITCH_JITTER: float = 0.05
const SOUNDS: Dictionary = {
	CombatEvent.Type.BLOCK: &"block",
	CombatEvent.Type.GUARD_BREAK: &"guard_break",
	CombatEvent.Type.PARRY: &"parry",
	CombatEvent.Type.RESPONSE: &"parry",
	CombatEvent.Type.ARMOR_ABSORBED: &"hit_light",
	CombatEvent.Type.PERFECT_PARRY: &"perfect_parry",
	CombatEvent.Type.CLASH: &"clash",
	CombatEvent.Type.BLADE_LOCK_STARTED: &"clash",
	CombatEvent.Type.BLADE_PRESS_STARTED: &"clash",
	CombatEvent.Type.BLADE_LOCK_PRESSED: &"lock_press",
	CombatEvent.Type.SHOVE: &"shove",
	CombatEvent.Type.EVADE_SUCCESS: &"evade",
	CombatEvent.Type.WOUND: &"wound",
}

const POWER_DB: float = -3.0
const CHANNEL_DB: float = -8.0
const SANCTUARY_EXPIRY_TICKS: int = 4
const POWER_STARTS: Dictionary = {
	PowerData.Kind.STORM: &"power_storm_rise",
	PowerData.Kind.MASS_TELEKINESIS: &"power_mass_rumble",
	PowerData.Kind.ARSENAL: &"power_mass_rumble",
	PowerData.Kind.WRATH: &"power_wrath",
}
const POWER_ACTIVES: Dictionary = {
	PowerData.Kind.REPULSE: &"power_repulse",
	PowerData.Kind.SUPREME_PUSH: &"power_supreme_push",
	PowerData.Kind.PULL: &"power_pull",
	PowerData.Kind.THROW: &"power_rock_lift",
	PowerData.Kind.FRACTURE: &"power_fracture",
	PowerData.Kind.MIND_TWIST: &"power_mind_twist",
	PowerData.Kind.SANCTUARY: &"power_sanctuary",
	PowerData.Kind.ABSORPTION: &"power_absorption",
	PowerData.Kind.HEAL: &"power_heal",
	PowerData.Kind.FOCUS: &"power_focus",
	PowerData.Kind.CHOKE: &"power_choke",
	PowerData.Kind.FREEZE: &"power_freeze",
	PowerData.Kind.STORM: &"power_thunder",
	PowerData.Kind.FLOW_CLEAVE: &"power_cleave",
}
const CHANNEL_LOOPS: Dictionary = {
	PowerData.Kind.BARRIER: &"power_barrier_loop",
	PowerData.Kind.LIGHTNING: &"power_lightning_loop",
	PowerData.Kind.DRAIN: &"power_drain_loop",
}
const POWER_HITS: Dictionary = {
	PowerData.Kind.LIGHTNING: &"power_lightning_snap",
	PowerData.Kind.THROW: &"power_rock_impact",
	PowerData.Kind.MASS_TELEKINESIS: &"power_rock_impact",
	PowerData.Kind.FRACTURE: &"power_fracture_burst",
}
const HAZARD_STRIKES: Dictionary = {
	Hazard.Kind.BOLT: &"power_bolt_strike",
	Hazard.Kind.ROCK_DROP: &"power_rock_impact",
}
const HAZARD_MARKS: Dictionary = {
	Hazard.Kind.BOLT: &"power_mark_tick",
	Hazard.Kind.ROCK_DROP: &"power_whistle",
}

var sim: MatchSimulation
var views: Array[FighterView] = []
var player_index: int = 0

var _hums: Array[AudioStreamPlayer2D] = []
var _hum_pitch: PackedFloat32Array = []
var _lock_loop: AudioStreamPlayer2D
var _was_active: Array[bool] = [false, false]
var _step_timers: PackedFloat32Array = [0.0, 0.0]
var _heartbeat_timer: float = 0.0
var _channels: Array[AudioStreamPlayer2D] = []
var _channel_ids: Array[StringName] = [&"", &""]
var _was_frozen: Array[bool] = [false, false]
var _sanctuary_ticks: PackedInt32Array = [0, 0]
var _wrath_armor: PackedInt32Array = [0, 0]


func setup(simulation: MatchSimulation, fighter_views: Array[FighterView], local_player: int) -> void:
	sim = simulation
	views = fighter_views
	player_index = local_player
	if _hums.is_empty():
		for i in 2:
			var hum: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			hum.stream = AudioDirector.stream(&"blade_hum")
			hum.bus = &"Blades"
			hum.attenuation = AudioDirector.ATTENUATION
			hum.max_distance = AudioDirector.MAX_DISTANCE
			add_child(hum)
			_hums.append(hum)
		_lock_loop = AudioStreamPlayer2D.new()
		_lock_loop.stream = AudioDirector.stream(&"lock_loop")
		_lock_loop.bus = &"Effects"
		add_child(_lock_loop)
		for i in 2:
			var channel: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			channel.bus = &"Effects"
			channel.volume_db = CHANNEL_DB
			add_child(channel)
			_channels.append(channel)
	_hum_pitch.resize(2)
	for i in 2:
		var weapon: WeaponData = sim.fighters[i].character.weapon
		_hum_pitch[i] = weapon.hum_pitch
		_hums[i].pitch_scale = weapon.hum_pitch
		_hums[i].volume_db = HUM_DB
		if not _hums[i].playing:
			_hums[i].play()


func _exit_tree() -> void:
	stop()


func stop() -> void:
	for hum in _hums:
		hum.stop()
		hum.stream = null
	if _lock_loop != null:
		_lock_loop.stop()
		_lock_loop.stream = null
	for channel in _channels:
		channel.stop()
		channel.stream = null


func on_ticked() -> void:
	for i in 2:
		var fighter: FighterState = sim.fighters[i]
		var active: bool = fighter.is_active()
		if active and not _was_active[i] and fighter.move != null and fighter.move.is_blade():
			var swing: StringName = &"swing_heavy" if fighter.move.is_heavy() else &"swing_light"
			AudioDirector.play(swing, views[i].blade.center(), 0.0, randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER), &"Blades")
		_was_active[i] = active


func on_event(event: CombatEvent) -> void:
	var at: Vector2 = Vector2(event.position.x, -event.position.y)
	if SOUNDS.has(event.type):
		AudioDirector.play(SOUNDS[event.type], at, 0.0, randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER))
	match event.type:
		CombatEvent.Type.HIT:
			AudioDirector.play(&"hit_heavy" if event.heavy else &"hit_light", at, 0.0, randf_range(0.95, 1.05))
		CombatEvent.Type.PERFECT_PARRY:
			AudioDirector.muffle(sim.config.perfect_parry_slow_motion)
		CombatEvent.Type.BLADE_LOCK_STARTED, CombatEvent.Type.BLADE_PRESS_STARTED:
			_lock_loop.global_position = at
			_lock_loop.play()
		CombatEvent.Type.BLADE_LOCK_ENDED, CombatEvent.Type.BLADE_PRESS_ENDED:
			_lock_loop.stop()
			AudioDirector.play(&"lock_tie" if event.source == CombatEvent.NO_FIGHTER else &"lock_win", at)
		CombatEvent.Type.DEATH:
			AudioDirector.play(&"knockout", at)
			AudioDirector.play(&"extinguish", views[event.target].blade.center(), 0.0, 1.0, &"Blades")
			AudioDirector.muffle(KNOCKOUT_MUFFLE)
			AudioDirector.duck_music(KNOCKOUT_MUFFLE * 2.0)
		CombatEvent.Type.ROUND_STARTED:
			for view in views:
				AudioDirector.play(&"ignition", view.global_position, -2.0, 1.0, &"Blades")
		CombatEvent.Type.DODGE:
			AudioDirector.play(&"dodge", views[event.source].global_position)
		CombatEvent.Type.JUMP:
			AudioDirector.play(&"jump", views[event.source].global_position, -4.0)
		CombatEvent.Type.LAND:
			AudioDirector.play(&"land", views[event.source].global_position, -6.0)
		CombatEvent.Type.ACTION_REJECTED:
			AudioDirector.play(&"rejected", views[event.source].global_position, -2.0, 1.0, &"Interface")
		CombatEvent.Type.FEINT:
			AudioDirector.play(&"swing_light", views[event.source].global_position, -8.0, 0.8)
		CombatEvent.Type.EXHAUSTION:
			AudioDirector.play(&"exhaustion", views[event.source].global_position)
	_on_flow_event(event, at)


func _on_flow_event(event: CombatEvent, at: Vector2) -> void:
	match event.type:
		CombatEvent.Type.POWER_STARTED:
			AudioDirector.play(POWER_STARTS.get(event.power.kind, &"power_cast"), views[event.source].global_position, POWER_DB)
		CombatEvent.Type.POWER_ACTIVE:
			if POWER_ACTIVES.has(event.power.kind):
				AudioDirector.play(POWER_ACTIVES[event.power.kind], views[event.source].global_position, POWER_DB)
		CombatEvent.Type.POWER_HIT:
			var kind: PowerData.Kind = event.power.kind if event.power != null else PowerData.Kind.REPULSE
			AudioDirector.play(POWER_HITS.get(kind, &"hit_light"), at, POWER_DB, randf_range(0.95, 1.05))
		CombatEvent.Type.POWER_BLOCKED:
			var barrier: bool = sim.fighters[event.target].power_kind_active(PowerData.Kind.BARRIER)
			AudioDirector.play(&"power_barrier_absorb" if barrier else &"block", at, POWER_DB)
		CombatEvent.Type.POWER_RESISTED:
			AudioDirector.play(&"power_resisted", at)
		CombatEvent.Type.POWER_ABSORBED:
			AudioDirector.play(&"power_absorption", at, POWER_DB, 1.2)
		CombatEvent.Type.POWER_REJECTED:
			AudioDirector.play(&"rejected", views[event.source].global_position, -2.0, 1.0, &"Interface")
		CombatEvent.Type.HAZARD_MARKED:
			if HAZARD_MARKS.has(int(event.amount)):
				AudioDirector.play(HAZARD_MARKS[int(event.amount)], at, -8.0)
		CombatEvent.Type.HAZARD_TRIGGERED:
			if HAZARD_STRIKES.has(int(event.amount)):
				AudioDirector.play(HAZARD_STRIKES[int(event.amount)], at, POWER_DB, randf_range(0.9, 1.1))
		CombatEvent.Type.PROJECTILE_SPAWNED:
			match int(event.amount):
				Projectile.Kind.ARSENAL:
					AudioDirector.play(&"power_arsenal_launch", views[event.source].global_position, POWER_DB, randf_range(0.9, 1.1))
				Projectile.Kind.BLADE:
					AudioDirector.play(&"swing_heavy", views[event.source].global_position, 0.0, 1.2, &"Blades")
		CombatEvent.Type.PROJECTILE_REFLECTED:
			AudioDirector.play(&"power_cleave_return", at)
		CombatEvent.Type.TECHNIQUE_CLASH:
			AudioDirector.play(&"clash", at, 2.0, 0.8)
			AudioDirector.play(&"power_supreme_push", at, -4.0, 1.4)


func _process(delta: float) -> void:
	if sim == null:
		return
	var lowest: float = 1.0
	for i in 2:
		var fighter: FighterState = sim.fighters[i]
		_update_hum(i, fighter, delta)
		_update_steps(i, fighter, delta)
		_update_flow(i, fighter)
		lowest = minf(lowest, fighter.health_ratio())
	if BladeLockResolver.is_active(sim):
		AudioDirector.duck_music(LOCK_DUCK)
	AudioDirector.set_music_intensity(1.0 - lowest)
	_update_heartbeat(delta)


func _update_hum(i: int, fighter: FighterState, delta: float) -> void:
	var hum: AudioStreamPlayer2D = _hums[i]
	var view: FighterView = views[i]
	hum.global_position = view.blade.center()
	var lit: float = view.blade.length_ratio
	var active: bool = fighter.is_active()
	var target_db: float = (HUM_ACTIVE_DB if active else HUM_DB) if lit > 0.0 else AudioDirector.SILENT_DB
	var target_pitch: float = _hum_pitch[i] * (HUM_ACTIVE_PITCH if active else 1.0) * lerpf(0.6, 1.0, lit)
	var weight: float = 1.0 - exp(-HUM_FOLLOW * delta)
	hum.volume_db = lerpf(hum.volume_db, target_db, weight)
	hum.pitch_scale = maxf(lerpf(hum.pitch_scale, target_pitch, weight), 0.05)


func _update_flow(i: int, fighter: FighterState) -> void:
	var loop: StringName = &""
	if fighter.state == FighterState.State.CHANNELING and fighter.power != null:
		loop = CHANNEL_LOOPS.get(fighter.power.kind, &"")
	var channel: AudioStreamPlayer2D = _channels[i]
	if loop != _channel_ids[i]:
		_channel_ids[i] = loop
		channel.stop()
		if loop != &"":
			channel.stream = AudioDirector.stream(loop)
			channel.play()
	channel.global_position = views[i].global_position
	var at: Vector2 = views[i].global_position
	var frozen: bool = fighter.state == FighterState.State.HELD and not fighter.held_by_choke
	if _was_frozen[i] and not frozen:
		AudioDirector.play(&"power_freeze_break", at, POWER_DB)
	_was_frozen[i] = frozen
	if _sanctuary_ticks[i] > SANCTUARY_EXPIRY_TICKS and fighter.sanctuary_ticks == 0:
		AudioDirector.play(&"power_sanctuary_break", at, POWER_DB)
	_sanctuary_ticks[i] = fighter.sanctuary_ticks
	if fighter.wrath_armor < _wrath_armor[i]:
		AudioDirector.play(&"power_wrath_armor", at, POWER_DB)
	_wrath_armor[i] = fighter.wrath_armor


func _update_steps(i: int, fighter: FighterState, delta: float) -> void:
	if fighter.state != FighterState.State.WALKING:
		_step_timers[i] = 0.0
		return
	_step_timers[i] -= delta
	if _step_timers[i] <= 0.0:
		_step_timers[i] = STEP_INTERVAL
		AudioDirector.play(&"step", views[i].global_position, -10.0, randf_range(0.9, 1.1))


func _update_heartbeat(delta: float) -> void:
	var fighter: FighterState = sim.fighters[player_index]
	if fighter.health_ratio() >= HEARTBEAT_RATIO or not fighter.is_alive() or sim.phase != MatchSimulation.Phase.FIGHT:
		_heartbeat_timer = 0.0
		return
	_heartbeat_timer -= delta
	if _heartbeat_timer <= 0.0:
		_heartbeat_timer = HEARTBEAT_INTERVAL
		AudioDirector.play(&"heartbeat", views[player_index].global_position, -4.0, 1.0, &"Music")
