class_name InfiltrationGeometry
extends RefCounted

const EPSILON: float = 0.0001


static func move_body(map: InfiltrationMapData, start: Vector2, motion: Vector2, radius: float, targets: Array[InfiltrationActor], self_actor: InfiltrationActor = null, player: InfiltrationActor = null) -> Vector2:
	var result: Vector2 = start
	for axis in 2:
		var destination: float = result[axis] + motion[axis]
		var minimum: Vector2 = result.min(result + Vector2(motion.x if axis == 0 else 0.0, motion.y if axis == 1 else 0.0)) - Vector2.ONE * radius
		var maximum: Vector2 = result.max(result + Vector2(motion.x if axis == 0 else 0.0, motion.y if axis == 1 else 0.0)) + Vector2.ONE * radius
		for y in range(floori(minimum.y / map.tile_size), floori(maximum.y / map.tile_size) + 1):
			for x in range(floori(minimum.x / map.tile_size), floori(maximum.x / map.tile_size) + 1):
				if map.is_solid(x, y):
					destination = _clip_axis(result, destination, axis, radius, Rect2(Vector2(x, y) * map.tile_size, Vector2.ONE * map.tile_size))
		for target in targets:
			if target != self_actor and target.health > 0.0:
				destination = _clip_axis(result, destination, axis, radius, Rect2(target.position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))
		if player != null and player.health > 0.0:
			destination = _clip_axis(result, destination, axis, radius, Rect2(player.position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))
		result[axis] = destination
	return result


static func _clip_axis(start: Vector2, destination: float, axis: int, radius: float, obstacle: Rect2) -> float:
	var other: int = 1 - axis
	if start[other] + radius <= obstacle.position[other] + EPSILON or start[other] - radius >= obstacle.end[other] - EPSILON:
		return destination
	if destination > start[axis] and start[axis] + radius <= obstacle.position[axis] + EPSILON:
		return minf(destination, obstacle.position[axis] - radius)
	if destination < start[axis] and start[axis] - radius >= obstacle.end[axis] - EPSILON:
		return maxf(destination, obstacle.end[axis] + radius)
	return destination


static func segment_box_fraction(start: Vector2, end: Vector2, rectangle: Rect2) -> float:
	var direction: Vector2 = end - start
	var near: float = 0.0
	var far: float = 1.0
	for axis in 2:
		if absf(direction[axis]) < EPSILON:
			if start[axis] < rectangle.position[axis] or start[axis] > rectangle.end[axis]:
				return INF
			continue
		var first: float = (rectangle.position[axis] - start[axis]) / direction[axis]
		var second: float = (rectangle.end[axis] - start[axis]) / direction[axis]
		near = maxf(near, minf(first, second))
		far = minf(far, maxf(first, second))
		if near > far:
			return INF
	return near


static func wall_fraction(map: InfiltrationMapData, start: Vector2, end: Vector2, radius: float = 0.0) -> float:
	var minimum: Vector2 = start.min(end) - Vector2.ONE * radius
	var maximum: Vector2 = start.max(end) + Vector2.ONE * radius
	var result: float = INF
	for y in range(floori(minimum.y / map.tile_size), floori(maximum.y / map.tile_size) + 1):
		for x in range(floori(minimum.x / map.tile_size), floori(maximum.x / map.tile_size) + 1):
			if map.is_solid(x, y):
				var rectangle: Rect2 = Rect2(Vector2(x, y) * map.tile_size, Vector2.ONE * map.tile_size).grow(radius)
				result = minf(result, segment_box_fraction(start, end, rectangle))
	return result


static func in_sector(origin: Vector2, facing: Vector2, target: Vector2, reach: float, degrees: float, radius: float = 0.0) -> bool:
	var offset: Vector2 = target - origin
	if offset.length_squared() > (reach + radius) * (reach + radius):
		return false
	if offset.length_squared() <= EPSILON:
		return true
	return facing.dot(offset.normalized()) >= cos(deg_to_rad(degrees * 0.5))
