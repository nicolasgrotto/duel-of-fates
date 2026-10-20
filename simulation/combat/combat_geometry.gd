class_name CombatGeometry


static func hurtbox(config: CombatConfig, fighter: FighterState) -> Rect2:
	var half_width: float = config.body_width * 0.5
	return Rect2(fighter.x - half_width, fighter.y, config.body_width, config.body_height)


static func hitbox(config: CombatConfig, fighter: FighterState, move: MoveData) -> Rect2:
	return _forward_box(config, fighter, move.reach, move.hitbox_bottom, move.hitbox_top)


static func blade_box(config: CombatConfig, fighter: FighterState, move: MoveData) -> Rect2:
	return _forward_box(config, fighter, move.blade_reach, move.hitbox_bottom, move.hitbox_top)


static func _forward_box(config: CombatConfig, fighter: FighterState, length: float, bottom: float, top: float) -> Rect2:
	var front: float = fighter.x + fighter.facing * config.body_width * 0.5
	var left: float = front if fighter.facing > 0 else front - length
	return Rect2(left, fighter.y + bottom, length, top - bottom)


static func overlaps(a: Rect2, b: Rect2) -> bool:
	return a.position.x <= b.end.x and b.position.x <= a.end.x and a.position.y <= b.end.y and b.position.y <= a.end.y


static func faces(fighter: FighterState, other: FighterState) -> bool:
	var dx: float = other.x - fighter.x
	return dx == 0.0 or signf(dx) == fighter.facing


static func gap(config: CombatConfig, a: FighterState, b: FighterState) -> float:
	return absf(b.x - a.x) - config.body_width


static func away_from(source: FighterState, target: FighterState) -> int:
	var dx: float = target.x - source.x
	if dx == 0.0:
		return source.facing
	return int(signf(dx))
