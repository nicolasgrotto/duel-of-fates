class_name BodyResolver


static func resolve(sim: MatchSimulation) -> void:
	var a: FighterState = sim.fighters[0]
	var b: FighterState = sim.fighters[1]
	if _passes_through(a) or _passes_through(b):
		return
	var config: CombatConfig = sim.config
	if absf(a.y - b.y) >= config.body_height:
		return
	var dx: float = b.x - a.x
	var overlap: float = config.body_width - absf(dx)
	if overlap <= 0.0:
		return
	var direction: float = signf(dx) if dx != 0.0 else float(a.facing)
	var a_share: float = overlap * 0.5
	var b_share: float = overlap * 0.5
	var limit: float = _limit(sim)
	if _pinned(a, -direction, limit):
		a_share = 0.0
		b_share = overlap
	elif _pinned(b, direction, limit):
		a_share = overlap
		b_share = 0.0
	a.x -= direction * a_share
	b.x += direction * b_share
	clamp_to_walls(sim, a)
	clamp_to_walls(sim, b)


static func clamp_to_walls(sim: MatchSimulation, fighter: FighterState) -> void:
	var limit: float = _limit(sim)
	if fighter.x < -limit:
		fighter.x = -limit
		fighter.vx = maxf(fighter.vx, 0.0)
	elif fighter.x > limit:
		fighter.x = limit
		fighter.vx = minf(fighter.vx, 0.0)


static func _limit(sim: MatchSimulation) -> float:
	return sim.config.half_width() - sim.config.body_width * 0.5


static func _passes_through(fighter: FighterState) -> bool:
	return fighter.is_air_dashing() or not fighter.is_alive()


static func _pinned(fighter: FighterState, push_direction: float, limit: float) -> bool:
	return absf(fighter.x + push_direction) >= limit and signf(fighter.x) == signf(push_direction)
