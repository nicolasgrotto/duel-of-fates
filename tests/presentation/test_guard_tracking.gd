extends TestCase

const CONTACT_TOLERANCE: float = 28.0
const ARM_TEST = preload("res://tests/presentation/test_arm_pose.gd")


func _characters() -> Array[CharacterData]:
	return ARM_TEST.new()._characters()


func _check_reach(data: CharacterData, pose: RigPose, context: String) -> void:
	var check: TestCase = ARM_TEST.new()
	check._check_reach(data, pose, context)
	failures.append_array(check.failures)


func _world(point: Vector2, fighter: FighterState) -> Vector2:
	return Vector2(fighter.x, -fighter.y) + point * Vector2(fighter.facing, 1.0) * fighter.character.art.dim("scale")


func _distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)), b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d))), minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)), d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b))))


func _exchange(data: CharacterData, move: MoveData, facing: int = 1, blocking: CharacterData = null) -> void:
	var fixture: DuelFixture = DuelFixture.create(null, null, 7, [data, blocking if blocking != null else DuelFixture.GUARDIAN])
	fixture.skip_intro()
	fixture.place(60.0)
	for fighter in fixture.sim.fighters:
		fighter.x *= facing
		fighter.facing *= facing
	var attacker: FighterState = fixture.fighter(0)
	var defender: FighterState = fixture.fighter(1)
	var attack_solver: PoseSolver = PoseSolver.new()
	attack_solver.setup(data, data.art)
	var defense_solver: PoseSolver = PoseSolver.new()
	defense_solver.setup(defender.character, defender.character.art)
	var attack_pose: RigPose = RigPose.new()
	var defense_pose: RigPose = RigPose.new()
	var attack_weapon: WeaponPose = WeaponPose.new()
	var defense_weapon: WeaponPose = WeaponPose.new()
	fixture.hold(1, Intent.Command.BLOCK)
	var contacts: int = 0
	for tick in 85:
		if tick == 24:
			ActionStarter.start_attack(fixture.sim, attacker, move)
			attacker.chain_index = maxi(data.light_chain.find(move), 0)
			if move.is_aerial():
				attacker.on_ground = false
				attacker.y = 32.0
				attacker.vy = 220.0
		fixture.step()
		attack_solver.advance(Ticks.DELTA)
		attack_solver.solve(attacker, defender, attack_pose)
		attack_weapon.compute(data.weapon, attack_pose)
		var base: Vector2 = attack_weapon.blade_base
		var tip: Vector2 = attack_weapon.tip()
		if data.weapon.kind == WeaponData.Kind.DUAL and move.blade_hand == MoveData.BladeHand.OFF:
			base = attack_weapon.second_base
			tip = base + attack_weapon.second_direction * attack_weapon.second_length
		var a: Vector2 = _world(base, attacker)
		var b: Vector2 = _world(tip, attacker)
		defense_solver.guard.observe_segment((a - Vector2(defender.x, -defender.y)) * Vector2(defender.facing, 1.0), (b - Vector2(defender.x, -defender.y)) * Vector2(defender.facing, 1.0))
		defense_solver.advance(Ticks.DELTA)
		defense_solver.solve(defender, attacker, defense_pose)
		_check_reach(defender.character, defense_pose, "%s %s" % [data.id, move.id])
		defense_weapon.compute(defender.character.weapon, defense_pose)
		for index in fixture.sim.event_count:
			if fixture.sim.events[index].type == CombatEvent.Type.BLOCK:
				contacts += 1
				var haft: bool = defender.character.weapon.kind == WeaponData.Kind.STAFF or defender.character.weapon.kind == WeaponData.Kind.LANCE
				var guard_from: Vector2 = defense_weapon.hilt_from if haft else defense_weapon.blade_base
				var guard_to: Vector2 = defense_weapon.hilt_to if haft else defense_weapon.tip()
				if defense_solver.guard_hand == PoseSolver.GuardHand.OFF:
					guard_from = defense_weapon.second_base
					guard_to = defense_weapon.second_base + defense_weapon.second_direction * defense_weapon.second_length
				var distance: float = _distance(a, b, _world(guard_from, defender), _world(guard_to, defender))
				assert_true(distance <= CONTACT_TOLERANCE, "%s %s against %s facing %d distance %.1f" % [data.id, move.id, defender.character.id, facing, distance])
	assert_gt(contacts, 0.0, "%s %s actually blocks" % [data.id, move.id])


func test_rendered_guard_meets_real_block_events_for_the_cast() -> void:
	for data in _characters():
		var moves: Array[MoveData] = data.light_chain.duplicate()
		moves.append_array([data.heavy, data.forward_heavy, data.aerial_light, data.aerial_heavy, data.technique_forward])
		if data.ability != null and data.ability.move != null and data.ability.move.technique_style == MoveData.TechniqueStyle.LUNGE:
			moves.append(data.ability.move)
		for move in moves:
			if move != null and move.can_clash() and move.technique_style != MoveData.TechniqueStyle.THROW:
				_exchange(data, move)
		_exchange(data, data.heavy, -1)
		_exchange(DuelFixture.GUARDIAN, DuelFixture.GUARDIAN.light_chain[0], 1, data)
		_exchange(DuelFixture.GUARDIAN, DuelFixture.GUARDIAN.heavy, -1, data)


func test_guard_defaults_breathe_and_preserve_family_identity() -> void:
	var signatures: Dictionary = {}
	for data in _characters():
		var fighter: FighterState = FighterState.new()
		fighter.setup(0, data, DuelFixture.CONFIG)
		fighter.state = FighterState.State.BLOCKING
		var other: FighterState = FighterState.new()
		other.setup(1, data, DuelFixture.CONFIG)
		var solver: PoseSolver = PoseSolver.new()
		solver.setup(data, data.art)
		var pose: RigPose = RigPose.new()
		for tick in 60:
			solver.advance(Ticks.DELTA)
			solver.solve(fighter, other, pose)
		var first: Vector2 = pose.pelvis
		signatures[data.family.resource_path] = Vector3(pose.grip.x, pose.grip.y, pose.blade_angle)
		for tick in 30:
			solver.advance(Ticks.DELTA)
			solver.solve(fighter, other, pose)
		assert_true(first.distance_to(pose.pelvis) > 0.01, "%s breathes" % data.id)
	assert_eq(signatures.values().size(), 9)
	for a in signatures:
		for b in signatures:
			if a != b:
				assert_true(signatures[a].distance_to(signatures[b]) > 1.0, "%s differs from %s" % [a, b])


func test_fast_retargets_preserve_tracker_position_and_angle() -> void:
	var tracker: GuardTracker = GuardTracker.new()
	tracker.configure(DuelFixture.GUARDIAN.family)
	tracker.begin(Vector2(20.0, -40.0), -60.0)
	var previous: Vector2 = tracker.position
	var previous_angle: float = tracker.angle
	for tick in 150:
		var low: bool = (tick / 6) % 2 == 0
		tracker.observe_segment(Vector2(60.0, -100.0 if low else -150.0), Vector2(-20.0, -150.0 if low else -75.0))
		tracker.predicted_base = tracker.live_base
		tracker.predicted_tip = tracker.live_tip
		tracker.advance(Ticks.DELTA)
		tracker.follow(Vector2(20.0, -40.0), -60.0, Vector2(0.0, -70.0), 0.0, 1.0, DuelFixture.GUARDIAN.weapon, true, false, 0.0)
		tracker.integrate()
		assert_lt(previous.distance_to(tracker.position), 24.0, "grip retarget stays continuous")
		assert_lt(absf(rad_to_deg(wrapf(tracker.angle - previous_angle, -PI, PI))), 42.0, "angle retarget stays continuous")
		var held: Vector2 = tracker.position
		tracker.begin(Vector2.ZERO, 0.0)
		assert_eq(tracker.position, held, "successive hits never reset the tracker")
		previous = tracker.position
		previous_angle = tracker.angle
	tracker.recoil(true, false)
	assert_gt(tracker.velocity.length(), 0.0)


func test_wasp_chain_and_light_heavy_string_remain_continuous() -> void:
	for id in [&"wasp", &"guardian"]:
		var data: CharacterData = DuelFixture.character(id)
		var attacker: FighterState = FighterState.new()
		attacker.setup(0, data, DuelFixture.CONFIG)
		attacker.x = -43.0
		var defender: FighterState = FighterState.new()
		defender.setup(1, DuelFixture.GUARDIAN, DuelFixture.CONFIG)
		defender.state = FighterState.State.BLOCKING
		defender.x = 43.0
		defender.facing = -1
		var attack: PoseSolver = PoseSolver.new()
		attack.setup(data, data.art)
		var guard: PoseSolver = PoseSolver.new()
		guard.setup(defender.character, defender.character.art)
		var first: RigPose = RigPose.new()
		var second: RigPose = RigPose.new()
		var weapon: WeaponPose = WeaponPose.new()
		for warmup in 40:
			guard.advance(Ticks.DELTA)
			guard.solve(defender, attacker, second)
		var previous: Vector2 = second.grip
		var previous_angle: float = second.blade_angle
		var moves: Array[MoveData] = data.light_chain.duplicate()
		if id == &"guardian":
			moves = [data.light_chain[0], data.heavy]
		for move in moves:
			attacker.move = move
			attacker.chain_index = maxi(data.light_chain.find(move), 0)
			attacker.state = FighterState.State.HEAVY_ATTACK if move.is_heavy() else FighterState.State.ATTACKING
			for phase in [FighterState.Phase.STARTUP, FighterState.Phase.ACTIVE, FighterState.Phase.RECOVERY]:
				attacker.move_phase = phase
				var duration: int = move.startup_ticks() if phase == FighterState.Phase.STARTUP else move.active_ticks() if phase == FighterState.Phase.ACTIVE else move.recovery_ticks()
				for tick in duration:
					attacker.phase_ticks = tick
					attack.advance(Ticks.DELTA)
					attack.solve(attacker, defender, first)
					weapon.compute(data.weapon, first)
					var base: Vector2 = weapon.second_base if move.blade_hand == MoveData.BladeHand.OFF else weapon.blade_base
					var tip: Vector2 = base + weapon.second_direction * weapon.second_length if move.blade_hand == MoveData.BladeHand.OFF else weapon.tip()
					guard.guard.observe_segment((_world(base, attacker) - Vector2(defender.x, 0.0)) * Vector2(-1.0, 1.0), (_world(tip, attacker) - Vector2(defender.x, 0.0)) * Vector2(-1.0, 1.0))
					guard.advance(Ticks.DELTA)
					guard.solve(defender, attacker, second)
					assert_lt(previous.distance_to(second.grip), 24.0, "%s %s grip continuity" % [id, move.id])
					assert_lt(absf(wrapf(second.blade_angle - previous_angle, -180.0, 180.0)), 65.0, "%s %s angle continuity" % [id, move.id])
					assert_true(guard.guard.active, "tracker remains engaged through recovery and next move")
					previous = second.grip
					previous_angle = second.blade_angle
