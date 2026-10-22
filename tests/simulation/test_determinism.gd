extends TestCase

const TICKS: int = 3000


func _scripted_intents(script_seed: int) -> PackedInt32Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = script_seed
	var packed: PackedInt32Array = []
	var intent: Intent = Intent.new()
	for i in TICKS * 2:
		intent.clear()
		intent.move_x = rng.randi_range(-1, 1)
		for button in [Intent.Command.LIGHT, Intent.Command.HEAVY, Intent.Command.BLOCK, Intent.Command.JUMP, Intent.Command.DODGE, Intent.Command.EVADE, Intent.Command.POWER, Intent.Command.SPECIAL]:
			if rng.randf() < 0.06:
				intent.press(button)
			elif rng.randf() < 0.2:
				intent.hold(button)
		packed.append(intent.pack())
	return packed


func _run(fixture: DuelFixture, packed: PackedInt32Array, from_tick: int, to_tick: int) -> void:
	for i in range(from_tick, to_tick):
		fixture.intents[0].unpack(packed[i * 2])
		fixture.intents[1].unpack(packed[i * 2 + 1])
		fixture.sim.step(fixture.intents[0], fixture.intents[1])


func test_same_seed_and_intents_give_same_state() -> void:
	var packed: PackedInt32Array = _scripted_intents(99)
	var first: DuelFixture = DuelFixture.create(null, null, 1234)
	var second: DuelFixture = DuelFixture.create(null, null, 1234)
	_run(first, packed, 0, TICKS)
	_run(second, packed, 0, TICKS)
	assert_eq(first.sim.capture(), second.sim.capture())
	assert_gt(first.sim.tick, 0)


func test_restored_snapshot_replays_identically() -> void:
	var packed: PackedInt32Array = _scripted_intents(5)
	var original: DuelFixture = DuelFixture.create(null, null, 77)
	_run(original, packed, 0, TICKS >> 1)
	var snapshot: Dictionary = original.sim.capture()
	_run(original, packed, TICKS >> 1, TICKS)
	var replay: DuelFixture = DuelFixture.create(null, null, 1)
	replay.sim.restore(snapshot)
	_run(replay, packed, TICKS >> 1, TICKS)
	assert_eq(replay.sim.capture(), original.sim.capture())


func test_intent_packing_round_trips() -> void:
	var intent: Intent = Intent.new()
	intent.move_x = -1
	intent.press(Intent.Command.HEAVY)
	intent.hold(Intent.Command.BLOCK)
	var copy: Intent = Intent.new()
	copy.unpack(intent.pack())
	assert_eq(copy.move_x, -1)
	assert_eq(copy.pressed, intent.pressed)
	assert_eq(copy.held, intent.held)
	copy.unpack_relative(intent.pack_relative(-1), 1)
	assert_eq(copy.move_x, 1, "relative packing mirrors the direction")
