extends TestCase

const PISTOL: BlasterData = preload("res://data/blasters/holster_pistol.tres")
const RIFLE: BlasterData = preload("res://data/blasters/back_rifle.tres")


func _fighter(blaster: BlasterData) -> FighterState:
	var hero: CharacterData = StoryCampaign.create("Iria", 0, 3, 0, 0, 1).protagonist()
	hero.weapon.blaster = blaster
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, hero, DuelFixture.CONFIG)
	return fighter


func _solve(fighter: FighterState) -> RigPose:
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(fighter.character, fighter.character.art)
	var pose: RigPose = RigPose.new()
	solver.solve(fighter, fighter, pose)
	return pose


func test_holster_neutral_guard_dodge_and_lock_leave_the_blaster_carried() -> void:
	for blaster in [PISTOL, RIFLE]:
		var fighter: FighterState = _fighter(blaster)
		for state in [FighterState.State.IDLE, FighterState.State.BLOCKING, FighterState.State.DODGING, FighterState.State.BLADE_LOCK, FighterState.State.DEAD]:
			fighter.state = state
			var pose: RigPose = _solve(fighter)
			assert_almost(pose.sidearm_draw, 0.0)
			assert_false(pose.sidearm_active)
			if state == FighterState.State.IDLE or state == FighterState.State.BLOCKING:
				assert_gt(pose.hand_spacing, 0.0)


func test_holster_draw_reaches_each_anchor_then_aims_and_returns() -> void:
	for blaster in [PISTOL, RIFLE]:
		var fighter: FighterState = _fighter(blaster)
		fighter.state = FighterState.State.ATTACKING
		fighter.move = fighter.character.technique_forward
		fighter.move_phase = FighterState.Phase.STARTUP
		fighter.phase_ticks = floori(blaster.draw_ticks() * 0.3)
		var draw: RigPose = _solve(fighter)
		assert_lt(ArmGeometry.to_body(draw.off_hand, draw).distance_to(blaster.reach_anchor()), 10.0)
		fighter.move_phase = FighterState.Phase.ACTIVE
		fighter.phase_ticks = 2
		var aim: RigPose = _solve(fighter)
		assert_almost(aim.sidearm_draw, 1.0)
		assert_almost(aim.hand_spacing, 0.0)
		fighter.move_phase = FighterState.Phase.RECOVERY
		fighter.phase_ticks = fighter.move.recovery_ticks() + blaster.holster_ticks()
		var returned: RigPose = _solve(fighter)
		assert_almost(returned.sidearm_draw, 0.0)
		assert_gt(returned.hand_spacing, 0.0)


func test_holster_long_size_uses_two_hands_and_lowered_blade_without_id_checks() -> void:
	var variant: BlasterData = RIFLE.duplicate() as BlasterData
	variant.id = &"custom_long_weapon"
	variant.carry_anchor = Vector2(-16.0, -30.0)
	var fighter: FighterState = _fighter(variant)
	fighter.state = FighterState.State.ATTACKING
	fighter.move = fighter.character.technique_forward
	fighter.move_phase = FighterState.Phase.ACTIVE
	var pose: RigPose = _solve(fighter)
	assert_true(variant.two_handed())
	assert_almost(pose.blade_angle, 85.0)
	assert_lt(pose.grip.distance_to(pose.off_hand), 24.0)
	assert_gt(pose.grip.x, pose.off_hand.x)
	assert_eq(variant.carry_anchor, Vector2(-16.0, -30.0))


func test_holster_equipment_keeps_rig_parts_at_its_own_carry_anchor() -> void:
	for blaster in [PISTOL, RIFLE]:
		var fighter: FighterState = _fighter(blaster)
		var pose: RigPose = _solve(fighter)
		var view: CarriedBlasterView = CarriedBlasterView.new()
		view.setup(blaster, ShaderMaterial.new())
		view.update_pose(pose)
		var expected: Vector2 = pose.pelvis + blaster.carry_anchor.rotated(pose.torso_angle)
		assert_eq(view.weapon.position, expected)
		assert_eq(view.support.position, expected)
		assert_true(view.weapon.texture != null and view.support.texture != null)
		view.free()
