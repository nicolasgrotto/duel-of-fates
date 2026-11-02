class_name SpaceShipState
extends RefCounted

var data: SpaceShipData
var team: int = 0
var position: Vector2
var previous: Vector2
var velocity: Vector2 = Vector2.ZERO
var angle: float = 0.0
var previous_angle: float = 0.0
var hull: float = 0.0
var shield: float = 0.0
var shield_delay: int = 0
var contact_cooldown: int = 0
var boost_tick: int = -1
var boost_cooldown: int = 0
var boost_direction: Vector2 = Vector2.ZERO
var cooldowns: PackedInt32Array = [0, 0]
var charges: PackedInt32Array = [-1, -1]
var respawn_ticks: int = 0
var thrust: float = 0.0
var spawned: bool = true


func reset(placement: SpaceShipPlacement) -> void:
	data = placement.ship
	team = placement.team
	position = placement.position
	previous = position
	velocity = Vector2.ZERO
	angle = placement.angle
	previous_angle = angle
	hull = data.hull
	shield = data.shield
	shield_delay = 0
	contact_cooldown = 0
	boost_tick = -1
	boost_cooldown = 0
	boost_direction = Vector2.ZERO
	cooldowns.fill(0)
	charges.fill(-1)
	respawn_ticks = 0
	thrust = 0.0
	spawned = placement.wave == 0


func forward() -> Vector2:
	return Vector2.from_angle(angle)


func invulnerable(config: SpaceConfig) -> bool:
	return boost_tick >= Ticks.from_seconds(config.boost_invulnerable_start) and boost_tick < Ticks.from_seconds(config.boost_invulnerable_end)


func capture() -> Dictionary:
	return {"contact_cooldown": contact_cooldown, "team": team, "position": position, "previous": previous, "velocity": velocity, "angle": angle, "previous_angle": previous_angle, "hull": hull, "shield": shield, "shield_delay": shield_delay, "boost_tick": boost_tick, "boost_cooldown": boost_cooldown, "boost_direction": boost_direction, "cooldowns": cooldowns.duplicate(), "charges": charges.duplicate(), "respawn_ticks": respawn_ticks, "thrust": thrust, "spawned": spawned}


func restore(state: Dictionary) -> void:
	for key in state:
		if key == "cooldowns" or key == "charges":
			set(key, state[key].duplicate())
		else:
			set(key, state[key])
