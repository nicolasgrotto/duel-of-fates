class_name BladeLockResolver


static func is_active(sim: MatchSimulation) -> bool:
	return sim.fighters[0].state == FighterState.State.BLADE_LOCK and sim.fighters[1].state == FighterState.State.BLADE_LOCK


static func start(sim: MatchSimulation, a: FighterState, b: FighterState) -> void:
	var lock_config: BladeLockConfig = sim.config.blade_lock
	var center: float = (a.x + b.x) * 0.5
	var side: int = 1 if a.x <= b.x else -1
	for fighter in [a, b]:
		sim.change_state(fighter, FighterState.State.BLADE_LOCK)
		ActionStarter.consume(fighter)
	a.x = center - side * lock_config.center_distance * 0.5
	b.x = center + side * lock_config.center_distance * 0.5
	a.facing = side
	b.facing = -side
	sim.lock_ticks = 0
	var event: CombatEvent = sim.emit(CombatEvent.Type.BLADE_LOCK_STARTED, a.index, b.index)
	event.position = Vector2(center, sim.config.body_height * 0.6)
	event.hitstop_ticks = sim.freeze_pair(a, b, lock_config.hitstop_start)


static func step(sim: MatchSimulation) -> void:
	if not is_active(sim):
		return
	var a: FighterState = sim.fighters[0]
	var b: FighterState = sim.fighters[1]
	if a.freeze_ticks > 0 or b.freeze_ticks > 0:
		return
	var lock_config: BladeLockConfig = sim.config.blade_lock
	sim.lock_ticks += 1
	var advantage: int = a.lock_presses - b.lock_presses
	if absi(advantage) >= lock_config.presses_to_win:
		_finish(sim, a, b, advantage)
	elif sim.lock_ticks >= Ticks.from_seconds(lock_config.max_duration):
		_finish(sim, a, b, advantage)


static func _finish(sim: MatchSimulation, a: FighterState, b: FighterState, advantage: int) -> void:
	var lock_config: BladeLockConfig = sim.config.blade_lock
	sim.lock_cooldown_ticks = Ticks.from_seconds(lock_config.cooldown)
	var winner: FighterState = null
	var loser: FighterState = null
	if advantage >= 1:
		winner = a
		loser = b
	elif advantage <= -1:
		winner = b
		loser = a
	var event: CombatEvent = sim.emit(
		CombatEvent.Type.BLADE_LOCK_ENDED,
		winner.index if winner != null else CombatEvent.NO_FIGHTER,
		loser.index if loser != null else CombatEvent.NO_FIGHTER,
	)
	event.position = Vector2((a.x + b.x) * 0.5, sim.config.body_height * 0.6)
	event.amount = advantage
	if winner == null:
		for fighter in [a, b]:
			sim.change_state(fighter, FighterState.State.IDLE)
	else:
		_resolve_winner(sim, winner, loser, event)
	sim.push_apart(a, b, lock_config.separation)
	event.hitstop_ticks = sim.freeze_pair(a, b, lock_config.hitstop_end)


static func _resolve_winner(sim: MatchSimulation, winner: FighterState, loser: FighterState, event: CombatEvent) -> void:
	var lock_config: BladeLockConfig = sim.config.blade_lock
	event.move = sim.lock_finish_move
	ActionStarter.start_attack(sim, winner, sim.lock_finish_move)
	var lethal: bool = sim.apply_damage(loser, lock_config.loser_damage)
	sim.drain_vigor(loser, lock_config.loser_vigor_loss)
	sim.change_state(loser, FighterState.State.STAGGERED)
	loser.stun_ticks = Ticks.from_seconds(lock_config.loser_stagger)
	if lethal:
		sim.kill(loser, winner, sim.lock_finish_move)


static func create_finish_move(config: CombatConfig) -> MoveData:
	var move: MoveData = MoveData.new()
	move.id = &"blade_lock_finish"
	move.kind = MoveData.Kind.LOCK_FINISH
	move.startup = 0.0
	move.active = 0.0
	move.recovery = config.blade_lock.winner_recovery
	move.damage = config.blade_lock.loser_damage
	move.vigor_cost = 0.0
	move.finisher_limb = MoveData.Limb.ARM
	return move
