extends TestCase


func _rig() -> FighterRig:
	var data: CharacterData = DuelFixture.SHADOW
	var rig: FighterRig = FighterRig.new()
	rig.build(data, data.costumes[0])
	return rig


func test_prosthetic_limbs_switch_material_and_clear() -> void:
	var rig: FighterRig = _rig()
	rig.set_prosthetic(MoveData.Limb.ARM, true)
	var metal: int = 0
	for key in rig._sprites:
		if rig._sprites[key].material == rig.prosthetic_material:
			metal += 1
			assert_true(String(key).contains("_front:"), "only the lost side turns metal: %s" % key)
	assert_gt(metal, 0)
	rig.clear_prosthetics()
	for key in rig._sprites:
		assert_true(rig._sprites[key].material == rig.shader_material)
	rig.free()


func test_clip_reaches_both_materials() -> void:
	var rig: FighterRig = _rig()
	rig.set_clip(true, Vector2(1.0, 2.0), Vector2.UP)
	assert_true(rig.shader_material.get_shader_parameter(&"clip_enabled"))
	assert_true(rig.prosthetic_material.get_shader_parameter(&"clip_enabled"))
	assert_eq(rig.prosthetic_material.get_shader_parameter(&"clip_normal"), Vector2.UP)
	rig.free()


func test_finisher_kinds_choose_how_the_body_moves() -> void:
	var player: FinisherPlayer = FinisherPlayer.new()
	player.config = load("res://data/balance/effects_config.tres")
	for kind in [Finisher.Kind.DASH_THROUGH, Finisher.Kind.WAIST, Finisher.Kind.VERTICAL, Finisher.Kind.DIAGONAL, Finisher.Kind.PULL_CUT]:
		player.kind = kind
		assert_true(player.is_split(), "kind %d splits the body" % kind)
		assert_true(player.moves_body())
	player.kind = Finisher.Kind.BLAST
	assert_false(player.is_split())
	assert_true(player.moves_body())
	player.kind = Finisher.Kind.CHARRED
	assert_false(player.moves_body())
	assert_gt(player.fall_delay(), 0.0, "the x-ray plays before the charred body falls")
	player.free()
