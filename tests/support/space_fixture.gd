class_name SpaceFixture
extends RefCounted

const CONFIG: SpaceConfig = preload("res://data/balance/space_config.tres")


static func make_sim() -> SpaceSimulation:
	var arena: SpaceArenaData = SpaceArenaData.new()
	arena.size = Vector2(2000, 1400)
	var pilot: SpaceShipPlacement = SpaceShipPlacement.new()
	pilot.ship = SpaceShipData.new()
	pilot.ship.primary = SpaceWeaponData.new()
	pilot.position = Vector2(500, 500)
	var drone: SpaceShipPlacement = SpaceShipPlacement.new()
	drone.ship = SpaceShipData.new()
	drone.ship.hull = 30.0
	drone.ship.shield = 0.0
	drone.ship.radius = 24.0
	drone.ship.immobile = true
	drone.ship.can_boost = false
	drone.position = Vector2(800, 500)
	drone.team = 1
	arena.ships = [pilot, drone]
	return SpaceSimulation.new(CONFIG, arena)


static func commands(count: int) -> Array[SpaceIntent]:
	var result: Array[SpaceIntent] = []
	for index in count:
		result.append(SpaceIntent.new())
	return result


static func incoming(sim: SpaceSimulation, damage: float, distance: float = 60.0) -> SpaceProjectile:
	var data: SpaceWeaponData = SpaceWeaponData.new()
	data.damage = damage
	sim.ships[1].data.primary = data
	for projectile in sim.projectiles:
		if projectile.active:
			continue
		projectile.active = true
		projectile.source = 1
		projectile.position = sim.ships[0].position - Vector2(distance, 0)
		projectile.previous = projectile.position
		projectile.velocity = Vector2(data.speed, 0)
		projectile.travelled = 0.0
		projectile.age = 0
		return projectile
	return null
