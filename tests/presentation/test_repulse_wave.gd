extends TestCase

const VFX: PowerVfxConfig = preload("res://data/balance/power_vfx_config.tres")
const REPULSE: PowerData = preload("res://data/powers/repulse.tres")
const SUPREME: PowerData = preload("res://data/powers/supreme_push.tres")

class PalmView:
	extends FighterView
	var palm: Vector2 = Vector2(32.0, -98.0)
	func hand_position(_front: bool) -> Vector2:
		return palm
	func body_center() -> Vector2:
		return Vector2(0.0, -75.0)

var powers: PowerView
var palm: PalmView
var fixture: DuelFixture


func before_each() -> void:
	fixture = DuelFixture.versus(&"guardian", &"shadow")
	fixture.fighter(0).x = 0.0
	powers = PowerView.new()
	powers.vfx = VFX
	powers.sim = fixture.sim
	powers._ready()
	palm = PalmView.new()
	powers.views.assign([palm, palm])


func _finish() -> void:
	powers.free()
	palm.free()


func _activate(power: PowerData) -> void:
	var event: CombatEvent = CombatEvent.new()
	event.type = CombatEvent.Type.POWER_ACTIVE
	event.source = 0
	event.power = power
	powers.on_event(event)


func test_wave_starts_at_the_rendered_palm_after_the_activation_pose_updates() -> void:
	_activate(REPULSE)
	assert_eq(powers._pending_sources[0], 0)
	palm.palm = Vector2(40.0, -100.0)
	powers._process(Ticks.DELTA)
	assert_eq(powers._positions[0], palm.palm)
	assert_eq(powers._ages[0], 0.0)
	assert_eq(powers.shockwave_tip(0, 0.0), palm.palm)
	_finish()


func test_tiers_and_reduced_effects_never_extend_the_simulated_reach() -> void:
	for side in [-1, 1]:
		fixture.fighter(0).facing = side
		palm.palm.x = side * 40.0
		for tier in 4:
			fixture.fighter(0).flow_tier = tier
			for reduced in [false, true]:
				powers.reduced = reduced
				var index: int = powers._next
				_activate(REPULSE)
				powers._process(Ticks.DELTA)
				var end: float = side * (REPULSE.reach + fixture.sim.config.body_width * 0.5)
				for sample in 21:
					var tip: Vector2 = powers.shockwave_tip(index, sample / 20.0)
					assert_true(tip.x * side <= end * side, "wave remains within the real reach")
				assert_almost(powers.shockwave_tip(index, 1.0).x, end)
				assert_eq(powers._colors[index], powers.tier_color(tier))
	_finish()


func test_supreme_push_creates_two_mirrored_waves_from_the_body() -> void:
	_activate(SUPREME)
	powers._process(Ticks.DELTA)
	assert_eq(powers._next, 2)
	assert_eq(powers._positions[0], palm.body_center())
	assert_eq(powers._positions[1], palm.body_center())
	assert_almost(powers.shockwave_tip(0, 1.0).x, -powers.shockwave_tip(1, 1.0).x)
	assert_eq(powers._kinds[0], PowerView.Burst.SHOCKWAVE)
	assert_eq(powers._kinds[1], PowerView.Burst.SHOCKWAVE)
	_finish()


func test_arc_is_convex_toward_the_target_tapered_and_on_the_pixel_grid() -> void:
	for sample in 17:
		var along: float = -1.0 + sample / 8.0
		var front: Vector2 = PowerView.shockwave_point(Vector2.ZERO, 1.0, 180.0, 40.0, along, 0.0)
		var back: Vector2 = PowerView.shockwave_point(Vector2.ZERO, 1.0, 180.0, 40.0, along, 18.0)
		var mirrored: Vector2 = PowerView.shockwave_point(Vector2.ZERO, -1.0, 180.0, 40.0, along, 0.0)
		assert_true(front.x >= back.x)
		assert_true(front.x <= 0.0)
		assert_eq(front, Vector2(-mirrored.x, mirrored.y))
		assert_eq(front.snapped(Vector2(2.0, 2.0)), front)
		if absf(along) == 1.0:
			assert_eq(front, back, "the tips taper to zero width")
	assert_gt(powers.shockwave_height(3, 1.0), powers.shockwave_height(0, 1.0))
	assert_gt(powers.shockwave_height(0, 1.0), powers.shockwave_height(0, 0.0))
	powers.reduced = true
	assert_eq(powers.shockwave_echoes(3), 0)
	powers.reduced = false
	assert_eq(powers.shockwave_echoes(0), 1)
	assert_eq(powers.shockwave_echoes(3), 2)
	_finish()


func test_preparation_never_emits_a_shockwave() -> void:
	var event: CombatEvent = CombatEvent.new()
	event.type = CombatEvent.Type.POWER_STARTED
	event.source = 0
	event.power = REPULSE
	powers.on_event(event)
	assert_eq(powers._next, 0)
	_finish()


func test_reduced_effects_remove_flashes_and_reduce_repulse_dust() -> void:
	powers.reduced = true
	powers._burst(PowerView.Burst.FLASH, Vector2.ZERO, 0.0, 0.2, 30.0, powers.tier_color(0))
	assert_eq(powers._next, 0)
	var debris: DebrisLayer = DebrisLayer.new()
	debris.config = VFX
	debris.sim = fixture.sim
	debris.reduced = true
	debris._ready()
	var event: CombatEvent = CombatEvent.new()
	event.type = CombatEvent.Type.POWER_ACTIVE
	event.source = 0
	event.power = REPULSE
	debris.on_event(event)
	assert_eq(debris._next, VFX.repulse_reduced_dust)
	assert_lt(debris._next, VFX.repulse_dust)
	debris.free()
	_finish()
