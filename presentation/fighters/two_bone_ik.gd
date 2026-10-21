class_name TwoBoneIk


static func solve(root: Vector2, target: Vector2, first: float, second: float, prefer: Vector2) -> Vector2:
	var to_target: Vector2 = target - root
	var distance: float = clampf(to_target.length(), 0.001, first + second - 0.001)
	var base_angle: float = to_target.angle()
	var cosine: float = clampf((first * first + distance * distance - second * second) / (2.0 * first * distance), -1.0, 1.0)
	var offset: float = acos(cosine)
	var joint_a: Vector2 = root + Vector2.from_angle(base_angle + offset) * first
	var joint_b: Vector2 = root + Vector2.from_angle(base_angle - offset) * first
	return joint_a if joint_a.dot(prefer) >= joint_b.dot(prefer) else joint_b
