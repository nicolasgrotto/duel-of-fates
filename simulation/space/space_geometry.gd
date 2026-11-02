class_name SpaceGeometry
extends RefCounted

const EPSILON: float = 0.000001


static func segment_circle_fraction(start: Vector2, end: Vector2, center: Vector2, radius: float) -> float:
	var offset: Vector2 = start - center
	var constant: float = offset.length_squared() - radius * radius
	if constant <= 0.0:
		return 0.0
	var direction: Vector2 = end - start
	var squared: float = direction.length_squared()
	if squared <= EPSILON:
		return INF
	var projection: float = offset.dot(direction)
	var discriminant: float = projection * projection - squared * constant
	if discriminant < 0.0:
		return INF
	var fraction: float = (-projection - sqrt(discriminant)) / squared
	return fraction if fraction >= 0.0 and fraction <= 1.0 else INF
