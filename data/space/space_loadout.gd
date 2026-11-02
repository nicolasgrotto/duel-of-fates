class_name SpaceLoadout
extends Resource

@export var ship: SpaceShipData
@export var weapon_level: int = 0
@export var shield_level: int = 0
@export var speed_level: int = 0


func build_ship(config: SpaceUpgradeConfig, base: SpaceShipData) -> SpaceShipData:
	var source: SpaceShipData = ship if ship != null else base
	var result: SpaceShipData = source.duplicate() as SpaceShipData
	result.primary = source.primary.duplicate() as SpaceWeaponData
	var weapon: int = clampi(weapon_level, 0, config.max_level)
	var shield: int = clampi(shield_level, 0, config.max_level)
	var speed: int = clampi(speed_level, 0, config.max_level)
	result.primary.damage += config.weapon_damage * weapon
	result.primary.interval -= config.weapon_interval * weapon
	result.shield += config.shield_capacity * shield
	result.shield_regeneration += config.shield_regeneration * shield
	result.speed += config.speed * speed
	result.acceleration += config.acceleration * speed
	return result
