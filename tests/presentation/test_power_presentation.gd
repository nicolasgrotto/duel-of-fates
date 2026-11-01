extends TestCase

const POWER_VFX: PowerVfxConfig = preload("res://data/balance/power_vfx_config.tres")

var fixture: DuelFixture
var debris: DebrisLayer


func before_each() -> void:
	fixture = DuelFixture.versus(&"elder", &"shadow")
	fixture.place(300.0)
	debris = DebrisLayer.new()
	debris.config = POWER_VFX
	debris.sim = fixture.sim
	debris._ready()


func _forward_events() -> void:
	for i in fixture.sim.event_count:
		debris.on_event(fixture.sim.events[i])


func _step_forwarding(count: int) -> void:
	for tick in count:
		fixture.step(1)
		_forward_events()


func test_meteor_waits_for_the_power_to_come_out() -> void:
	var power: PowerData = fixture.give_power(0, &"mass_telekinesis")
	fixture.cast(0)
	_forward_events()
	_step_forwarding(power.startup_ticks() - 4)
	assert_eq(debris.meteor_progress(0), -1.0, "no meteor during the vulnerable startup")
	_step_forwarding(8)
	assert_true(debris.meteor_progress(0) >= 0.0, "meteor starts once the power is active")
	debris.free()


func test_interrupted_cast_never_starts_the_meteor() -> void:
	var power: PowerData = fixture.give_power(0, &"mass_telekinesis")
	fixture.place(80.0)
	fixture.cast(0)
	_forward_events()
	fixture.press(1, Intent.Command.LIGHT)
	_step_forwarding(power.startup_ticks() + 30)
	assert_ne(fixture.fighter(0).state, FighterState.State.CASTING)
	assert_eq(debris.meteor_progress(0), -1.0)
	debris.free()


func test_freeze_tremor_steps_on_the_grid_and_moves() -> void:
	var seen: Dictionary = {}
	for frame in 60:
		var shift: float = FighterView.freeze_tremor(frame / 60.0, POWER_VFX.freeze_tremor, POWER_VFX.freeze_tremor_rate)
		assert_true(absf(shift) <= POWER_VFX.freeze_tremor, "tremor stays small")
		assert_almost(fposmod(shift, 2.0), 0.0, 0.001, "tremor snaps to the 2 u grid")
		seen[shift] = true
	assert_gt(seen.size(), 2.0, "the body strains both ways")


func test_freeze_motes_hang_inside_the_body_area() -> void:
	for i in POWER_VFX.freeze_motes:
		var offset: Vector2 = PowerView.freeze_mote_offset(i, POWER_VFX.freeze_mote_spread)
		assert_true(absf(offset.x) <= POWER_VFX.freeze_mote_spread.x * 0.5 and absf(offset.y) <= POWER_VFX.freeze_mote_spread.y * 0.5)
		assert_true(offset == PowerView.freeze_mote_offset(i, POWER_VFX.freeze_mote_spread), "motes stay still")


func test_freeze_holds_and_reads_as_frozen_not_choked() -> void:
	fixture.place(150.0)
	fixture.give_power(0, &"freeze")
	fixture.cast(0)
	assert_true(fixture.step_until(func() -> bool: return fixture.fighter(1).state == FighterState.State.HELD, 60))
	assert_true(PowerView.is_frozen(fixture.fighter(1)))
	assert_false(PowerView.is_frozen(fixture.fighter(0)))
