extends TestCase

const CHARACTERS_ROOT: String = "res://data/characters"
const SAMPLES: int = 24
const TOLERANCE: float = 12.0


func _characters() -> Array[CharacterData]:
	var found: Array[CharacterData] = []
	for folder in DirAccess.get_directories_at(CHARACTERS_ROOT):
		var path: String = "%s/%s/%s.tres" % [CHARACTERS_ROOT, folder, folder]
		if ResourceLoader.exists(path):
			var data: CharacterData = load(path)
			if data.art != null:
				found.append(data)
	return found


func _blade_moves(data: CharacterData) -> Array[MoveData]:
	var moves: Array[MoveData] = []
	moves.append_array(data.light_chain)
	for move in [data.heavy, data.forward_heavy, data.counter, data.aerial_light, data.aerial_heavy]:
		if move != null:
			moves.append(move)
	if data.ability != null and data.ability.move != null and data.ability.kind != AbilityData.Kind.STANCE:
		moves.append(data.ability.move)
	return moves


func _blade_crosses_hitbox(data: CharacterData, move: MoveData) -> bool:
	var config: CombatConfig = DuelFixture.CONFIG
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, data, config)
	fighter.state = FighterState.State.HEAVY_ATTACK if move.is_heavy() else FighterState.State.ATTACKING
	fighter.move = move
	fighter.move_phase = FighterState.Phase.ACTIVE
	fighter.chain_index = maxi(data.light_chain.find(move), 0)
	fighter.on_ground = not move.is_aerial()
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var pose: RigPose = RigPose.new()
	var geometry: WeaponPose = WeaponPose.new()
	var hitbox: Rect2 = CombatGeometry.hitbox(config, fighter, move).grow(TOLERANCE)
	var scale: float = data.art.dim("scale")
	for tick in move.active_ticks():
		fighter.phase_ticks = tick
		solver.solve(fighter, fighter, pose)
		geometry.compute(data.weapon, pose)
		for sample in SAMPLES + 1:
			var point: Vector2 = geometry.blade_base.lerp(geometry.tip(), float(sample) / SAMPLES) * scale
			if hitbox.has_point(Vector2(point.x, -point.y)):
				return true
	return false


func test_every_blade_crosses_its_hitbox_during_active() -> void:
	var characters: Array[CharacterData] = _characters()
	assert_gt(characters.size(), 1.0)
	for data in characters:
		for move in _blade_moves(data):
			assert_true(_blade_crosses_hitbox(data, move), "%s %s" % [data.id, move.id])


func test_trail_only_during_active() -> void:
	var data: CharacterData = DuelFixture.GUARDIAN
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, data, DuelFixture.CONFIG)
	fighter.state = FighterState.State.ATTACKING
	fighter.move = data.light_chain[0]
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var pose: RigPose = RigPose.new()
	fighter.move_phase = FighterState.Phase.STARTUP
	solver.solve(fighter, fighter, pose)
	assert_false(pose.trail)
	fighter.move_phase = FighterState.Phase.ACTIVE
	solver.solve(fighter, fighter, pose)
	assert_true(pose.trail)
