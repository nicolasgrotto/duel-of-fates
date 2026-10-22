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
