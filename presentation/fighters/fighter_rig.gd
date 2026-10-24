class_name FighterRig
extends Node2D

const MATERIAL_SHADER: Shader = preload("res://presentation/fighters/fighter_material.gdshader")
const BACK_SHADE: Color = Color(0.68, 0.68, 0.72)
const BODY_DEPTH: int = 32
const WOUND_SHADE: Color = Color(0.78, 0.72, 0.72)
const ARM_PREFER: Vector2 = Vector2(-0.35, 1.0)
const LEG_PREFER: Vector2 = Vector2(1.0, 0.1)
const HEAD_PARTS: Array[String] = ["head", "hair", "beard", "hood", "mask"]
const EYE_OFFSET: Vector2 = Vector2(6.0, -15.3)

var art: FighterArt
var character: CharacterData
var costume: CostumeData
var shader_material: ShaderMaterial
var visible_parts: PackedStringArray = []
var floor_y: float = 0.0
var wind: float = 0.0

var _skeleton: Skeleton2D
var _bones: Dictionary = {}
var _sprites: Dictionary = {}
var _cloths: Array[ClothStrip] = []
var _cloth_anchors: Array[String] = []
var _hilt: HiltView
var _marks: CutMarks
var _cuts: Array[String] = []
var _layers: Array[CanvasItem] = []
var _lost_main_hand: bool = false
var _missing: MoveData.Limb = MoveData.Limb.NONE
var _wound: FighterState.Wound = FighterState.Wound.NONE
var _open_hand: bool = false

var chest: Vector2 = Vector2.ZERO
var head_base: Vector2 = Vector2.ZERO
var front_hand: Vector2 = Vector2.ZERO
var back_hand: Vector2 = Vector2.ZERO
var front_elbow: Vector2 = Vector2.ZERO
var front_knee: Vector2 = Vector2.ZERO
var back_elbow: Vector2 = Vector2.ZERO
var back_knee: Vector2 = Vector2.ZERO
var head_rotation: float = 0.0


func build(data: CharacterData, look: CostumeData) -> void:
	character = data
	art = data.art
	costume = look
	visible_parts = costume.parts_for(art)
	shader_material = ShaderMaterial.new()
	shader_material.shader = MATERIAL_SHADER
	shader_material.set_shader_parameter(&"palette", costume.colors)
	scale = Vector2.ONE * art.dim("scale")
	z_index = BODY_DEPTH
	_skeleton = Skeleton2D.new()
	add_child(_skeleton)
	for bone_name in ["pelvis", "torso", "head", "chest", "shoulder_front", "shoulder_back",
			"upper_arm_front", "forearm_front", "hand_front", "upper_arm_back", "forearm_back", "hand_back",
			"thigh_front", "shin_front", "boot_front", "thigh_back", "shin_back", "boot_back"]:
		var bone: Bone2D = Bone2D.new()
		bone.name = bone_name
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(1.0)
		bone.rest = Transform2D.IDENTITY
		_skeleton.add_child(bone)
		_bones[bone_name] = bone
	_add_cloths("back")
	_add_sprite("thigh_back", "thigh", -12, BACK_SHADE)
	_add_sprite("shin_back", "shin", -12, BACK_SHADE)
	_add_sprite("shin_back", "knee", -11, BACK_SHADE)
	_add_sprite("boot_back", "boot", -11, BACK_SHADE)
	_add_sprite("upper_arm_back", "upper_arm", -10, BACK_SHADE)
	_add_sprite("shoulder_back", "pad", -9, BACK_SHADE)
	_add_sprite("forearm_back", "forearm", -9, BACK_SHADE)
	_add_sprite("hand_back", "hand", -8, BACK_SHADE)
	_add_sprite("torso", "torso", 0, Color.WHITE)
	_add_sprite("thigh_front", "thigh", 2, Color.WHITE)
	_add_sprite("shin_front", "shin", 3, Color.WHITE)
	_add_sprite("shin_front", "knee", 3, Color.WHITE)
	_add_sprite("boot_front", "boot", 3, Color.WHITE)
	_add_cloths("front")
	_add_sprite("chest", "collar", 6, Color.WHITE)
	_add_sprite("chest", "neckerchief", 6, Color.WHITE)
	for i in HEAD_PARTS.size():
		_add_sprite("head", HEAD_PARTS[i], 7 + i, Color.WHITE)
	_add_sprite("upper_arm_front", "upper_arm", 11, Color.WHITE)
	_add_sprite("shoulder_front", "pad", 12, Color.WHITE)
	var forearm: String = "forearm_front" if art.has_part("forearm_front") else "forearm"
	_add_sprite("forearm_front", forearm, 13, Color.WHITE)
	_add_sprite("hand_front", "hand", 15, Color.WHITE)
	_hilt = HiltView.new()
	_hilt.z_index = 14
	_hilt.setup(data.weapon, costume)
	add_child(_hilt)
	_marks = CutMarks.new()
	_marks.z_index = 16
	add_child(_marks)


func _add_sprite(bone_name: String, part: String, z: int, shade: Color) -> void:
	if not art.has_part(part):
		return
	var optional: bool = part in ["hair", "beard", "hood", "mask", "pad", "collar", "neckerchief", "knee"]
	if optional and not visible_parts.has(part):
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = art.canvas_texture(part)
	sprite.centered = false
	sprite.offset = -art.pivot(part)
	sprite.scale = Vector2.ONE / art.pixels_per_unit
	sprite.z_index = z
	sprite.self_modulate = shade
	sprite.material = shader_material
	_bones[bone_name].add_child(sprite)
	var key: String = bone_name + ":" + part
	_sprites[key] = sprite


func _add_cloths(layer: String) -> void:
	for spec in art.cloths:
		if spec.get("layer", "front") != layer or not visible_parts.has(spec["name"]):
			continue
		var cloth: ClothStrip = ClothStrip.new()
		cloth.configure(spec, art.canvas_texture(spec["name"]))
		cloth.material = shader_material
		cloth.z_index = -20 if layer == "back" else 4
		add_child(cloth)
		_cloths.append(cloth)
		_cloth_anchors.append(spec.get("anchor", "waist"))


func apply(pose: RigPose, facing: int, delta: float) -> void:
	var up: Vector2 = Vector2.UP.rotated(pose.torso_angle)
	var torso_length: float = art.dim("torso_length")
	var pelvis: Vector2 = pose.pelvis
	chest = pelvis + up * torso_length
	head_base = chest + up * art.dim("neck")
	head_rotation = pose.torso_angle + pose.head_angle
	_place("pelvis", pelvis, 0.0)
	_place("torso", pelvis, pose.torso_angle)
	_place("chest", chest, pose.torso_angle)
	_place("head", head_base, head_rotation)
	var front_shoulder: Vector2 = chest + Vector2(2.0, 4.0).rotated(pose.torso_angle)
	var back_shoulder: Vector2 = chest + Vector2(-3.0, 4.0).rotated(pose.torso_angle)
	_place("shoulder_front", front_shoulder, pose.torso_angle)
	_place("shoulder_back", back_shoulder, pose.torso_angle)
	front_hand = pose.grip
	back_hand = pose.off_hand
	front_elbow = _arm("front", front_shoulder, front_hand)
	back_elbow = _arm("back", back_shoulder, back_hand)
	var hip_front: Vector2 = pelvis + Vector2(3.0, 0.0)
	var hip_back: Vector2 = pelvis + Vector2(-3.0, 0.0)
	front_knee = _leg("front", hip_front, pose.front_foot)
	back_knee = _leg("back", hip_back, pose.back_foot)
	_set_open_hand(pose.open_hand)
	_hilt.update_pose(pose, front_hand, back_hand)
	_simulate_cloths(pose, pelvis, facing, delta)
	_update_marks(delta)


func _set_open_hand(open: bool) -> void:
	if open == _open_hand or not art.has_part("hand_open") or not _sprites.has("hand_back:hand"):
		return
	_open_hand = open
	var part: String = "hand_open" if open else "hand"
	var sprite: Sprite2D = _sprites["hand_back:hand"]
	sprite.texture = art.canvas_texture(part)
	sprite.offset = -art.pivot(part)


func _place(bone_name: String, at: Vector2, angle: float) -> void:
	var bone: Bone2D = _bones[bone_name]
	bone.position = at
	bone.rotation = angle


func _arm(side: String, shoulder: Vector2, hand: Vector2) -> Vector2:
	var upper: float = art.dim("upper_arm")
	var lower: float = art.dim("forearm")
	var elbow: Vector2 = TwoBoneIk.solve(shoulder, hand, upper, lower, ARM_PREFER)
	var reach: Vector2 = elbow + (hand - elbow).limit_length(lower)
	_place("upper_arm_" + side, shoulder, (elbow - shoulder).angle())
	_place("forearm_" + side, elbow, (reach - elbow).angle())
	_place("hand_" + side, reach, (reach - elbow).angle())
	return elbow


func _leg(side: String, hip: Vector2, foot: Vector2) -> Vector2:
	var ankle: Vector2 = foot + Vector2(0.0, -art.dim("ankle"))
	var knee: Vector2 = TwoBoneIk.solve(hip, ankle, art.dim("thigh"), art.dim("shin"), LEG_PREFER)
	var reach: Vector2 = knee + (ankle - knee).limit_length(art.dim("shin"))
	_place("thigh_" + side, hip, (knee - hip).angle())
	_place("shin_" + side, knee, (reach - knee).angle())
	_place("boot_" + side, reach, 0.0)
	return knee


func _simulate_cloths(pose: RigPose, pelvis: Vector2, facing: int, delta: float) -> void:
	for i in _cloths.size():
		_cloths[i].floor_y = floor_y
		_cloths[i].wind = wind
		var anchor: Vector2 = _cloth_anchor(_cloth_anchors[i], pose, pelvis)
		_cloths[i].simulate(to_global(anchor), pose.torso_angle * facing, facing, delta)


func _cloth_anchor(anchor: String, pose: RigPose, pelvis: Vector2) -> Vector2:
	match anchor:
		"shoulders":
			return chest + Vector2(-5.0, 3.0).rotated(pose.torso_angle)
		"neck":
			return head_base + Vector2(-5.0, -2.0).rotated(pose.torso_angle)
		"waist_back":
			return pelvis + Vector2(-8.0, -3.0).rotated(pose.torso_angle)
	return pelvis + Vector2(1.0, -3.0).rotated(pose.torso_angle)


func reset_cloths() -> void:
	for cloth in _cloths:
		cloth.reset()


func set_hilt_button(color: Color) -> void:
	_hilt.button_color = color


func set_blade_out(out: bool) -> void:
	_hilt.hidden_main = out


func set_flash(amount: float) -> void:
	shader_material.set_shader_parameter(&"flash", amount)


func set_wound(wound: FighterState.Wound) -> void:
	if wound == _wound:
		return
	_wound = wound
	var arm: bool = wound == FighterState.Wound.ARM
	var leg: bool = wound == FighterState.Wound.LEG
	for key in _sprites:
		var sprite: Sprite2D = _sprites[key]
		var on_arm: bool = key.begins_with("forearm_front") or key.begins_with("upper_arm_front")
		var on_leg: bool = key.begins_with("shin_front") or key.begins_with("thigh_front")
		if (arm and on_arm) or (leg and on_leg):
			sprite.self_modulate = WOUND_SHADE
		elif on_arm or on_leg:
			sprite.self_modulate = Color.WHITE


func sever(limb: MoveData.Limb, front: bool, both_legs: bool) -> void:
	_missing = limb
	_cuts.clear()
	var side: String = "front" if front else "back"
	match limb:
		MoveData.Limb.ARM:
			_cuts.append("arm_" + side)
		MoveData.Limb.LEG:
			_cuts.append("leg_" + side)
			if both_legs:
				_cuts.append("leg_" + ("back" if front else "front"))
		MoveData.Limb.HEAD:
			_cuts.append("head")
	var hidden: Array[String] = []
	for cut in _cuts:
		match cut:
			"arm_front", "arm_back":
				var arm_side: String = cut.trim_prefix("arm_")
				hidden.append_array(["forearm_" + arm_side, "hand_" + arm_side])
			"leg_front", "leg_back":
				var leg_side: String = cut.trim_prefix("leg_")
				hidden.append_array(["shin_" + leg_side, "boot_" + leg_side])
			"head":
				hidden.append("head")
	for key in _sprites:
		for bone_name in hidden:
			if key.begins_with(bone_name + ":"):
				_sprites[key].visible = false
	_lost_main_hand = _cuts.has("arm_front")
	_hilt.visible = not _lost_main_hand
	_marks.start_cut()


func lost_main_hand() -> bool:
	return _lost_main_hand


func restore() -> void:
	_missing = MoveData.Limb.NONE
	_cuts.clear()
	_lost_main_hand = false
	_marks.clear()
	for key in _sprites:
		_sprites[key].visible = true
	_hilt.visible = true


func _update_marks(delta: float) -> void:
	_marks.cuts.clear()
	for cut in _cuts:
		match cut:
			"arm_front":
				_marks.cuts.append(PackedVector2Array([front_elbow, front_hand - front_elbow]))
			"arm_back":
				_marks.cuts.append(PackedVector2Array([back_elbow, back_hand - back_elbow]))
			"leg_front":
				_marks.cuts.append(PackedVector2Array([front_knee, Vector2.DOWN]))
			"leg_back":
				_marks.cuts.append(PackedVector2Array([back_knee, Vector2.DOWN]))
			"head":
				_marks.cuts.append(PackedVector2Array([head_base, head_base - chest]))
	_marks.wound.clear()
	match _wound:
		FighterState.Wound.ARM:
			_marks.wound.append_array([front_elbow, front_hand])
		FighterState.Wound.LEG:
			_marks.wound.append_array([front_knee, _bones["boot_front"].position])
	_marks.advance(delta)


func severed_parts(limb: MoveData.Limb) -> Array[String]:
	match limb:
		MoveData.Limb.ARM:
			return ["forearm", "hand"]
		MoveData.Limb.LEG:
			return ["shin", "boot"]
		MoveData.Limb.HEAD:
			var parts: Array[String] = ["head"]
			for part in ["hair", "beard", "hood", "mask"]:
				if visible_parts.has(part):
					parts.append(part)
			return parts
	return []


func limb_anchor(limb: MoveData.Limb, front: bool = true) -> Vector2:
	match limb:
		MoveData.Limb.ARM:
			return front_elbow if front else back_elbow
		MoveData.Limb.LEG:
			return front_knee if front else back_knee
	return head_base


func eye_position() -> Vector2:
	return head_base + (EYE_OFFSET * art.dim("head")).rotated(head_rotation)


func shows_eyes() -> bool:
	return character.eclipse_eyes and not visible_parts.has("mask") and _missing != MoveData.Limb.HEAD


func draw_reflection(canvas: CanvasItem, flip: Transform2D, tint: Color) -> void:
	if _layers.is_empty():
		_build_layers()
	for node in _layers:
		if not node.is_visible_in_tree():
			continue
		if node is ClothStrip:
			canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
			(node as ClothStrip).draw_into(canvas, flip, tint)
		else:
			var sprite: Sprite2D = node
			canvas.draw_set_transform_matrix(flip * sprite.get_global_transform() * Transform2D(0.0, sprite.offset))
			canvas.draw_texture((sprite.texture as CanvasTexture).diffuse_texture, Vector2.ZERO, tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


func _build_layers() -> void:
	var entries: Array = []
	for key in _sprites:
		entries.append([_sprites[key].z_index, _sprites[key]])
	for cloth in _cloths:
		entries.append([cloth.z_index, cloth])
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry in entries:
		_layers.append(entry[1])


func sprite_snapshots() -> Array:
	var shots: Array = []
	for key in _sprites:
		var sprite: Sprite2D = _sprites[key]
		if sprite.is_visible_in_tree():
			shots.append([sprite.texture, sprite.get_global_transform() * Transform2D(0.0, sprite.offset)])
	return shots
