class_name ArmGeometry

const FRONT_SHOULDER: Vector2 = Vector2(2.0, 4.0)
const BACK_SHOULDER: Vector2 = Vector2(-3.0, 4.0)


static func shoulder(pose: RigPose, art: FighterArt, front: bool) -> Vector2:
	var offset: Vector2 = FRONT_SHOULDER if front else BACK_SHOULDER
	return pose.pelvis + (Vector2.UP * art.dim("torso_length") + offset).rotated(pose.torso_angle)


static func to_body(point: Vector2, pose: RigPose) -> Vector2:
	return (point - pose.pelvis).rotated(-pose.torso_angle)


static func constrain(pose: RigPose, character: CharacterData) -> void:
	var art: FighterArt = character.art
	if art == null:
		return
	var front: Vector2 = shoulder(pose, art, true)
	var back: Vector2 = shoulder(pose, art, false)
	var length: float = art.dim("upper_arm") + art.dim("forearm")
	var radius: float = length * lerpf(character.family.arm_reach, character.family.arm_extension, pose.arm_extension)
	if pose.hand_spacing > 0.0:
		var offset: Vector2 = pose.blade_direction() * pose.hand_spacing
		pose.grip = _within_both(pose.grip, front, back + offset, radius)
		pose.off_hand = pose.grip - offset
	else:
		pose.grip = front + (pose.grip - front).limit_length(radius)
		pose.off_hand = back + (pose.off_hand - back).limit_length(radius)


static func _within_both(point: Vector2, first: Vector2, second: Vector2, radius: float) -> Vector2:
	var candidate: Vector2 = first + (point - first).limit_length(radius)
	if candidate.distance_squared_to(second) <= radius * radius:
		return candidate
	candidate = second + (point - second).limit_length(radius)
	if candidate.distance_squared_to(first) <= radius * radius:
		return candidate
	var between: Vector2 = second - first
	var middle: Vector2 = (first + second) * 0.5
	var height: float = sqrt(maxf(radius * radius - between.length_squared() * 0.25, 0.0))
	var side: Vector2 = between.normalized().orthogonal() * height
	var a: Vector2 = middle + side
	var b: Vector2 = middle - side
	return a if point.distance_squared_to(a) < point.distance_squared_to(b) else b
