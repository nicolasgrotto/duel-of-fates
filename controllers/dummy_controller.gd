class_name DummyController
extends FighterController

enum Behavior { STAND, GUARD, ATTACK, PLAYBACK, HEAVY, MIRROR }

var behavior: Behavior = Behavior.STAND
var playback: IntentRecording = IntentRecording.new(1)
var _config: TrainingConfig
var _ticks: int = 0
var _attacks: int = 0
var _cursor: int = 0
var _next_heavy: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(config: TrainingConfig, dummy_seed: int = 0) -> void:
	_config = config
	_rng.seed = dummy_seed


func set_behavior(new_behavior: Behavior) -> void:
	behavior = new_behavior
	_ticks = 0
	_cursor = 0


func produce(sim: MatchSimulation, fighter_index: int, intent: Intent) -> void:
	intent.clear()
	_ticks += 1
	match behavior:
		Behavior.GUARD:
			intent.hold(Intent.Command.BLOCK)
		Behavior.ATTACK:
			if _ticks % Ticks.from_seconds(_config.dummy_attack_interval) == 0:
				_attacks += 1
				var heavy: bool = _config.dummy_heavy_every > 0 and _attacks % _config.dummy_heavy_every == 0
				intent.press(Intent.Command.HEAVY if heavy else Intent.Command.LIGHT)
		Behavior.PLAYBACK:
			_play(sim.fighters[fighter_index].facing, intent)
		Behavior.HEAVY:
			if _ticks >= _next_heavy:
				intent.press(Intent.Command.HEAVY)
				_next_heavy = _ticks + Ticks.from_seconds(_rng.randf_range(_config.heavy_interval_min, _config.heavy_interval_max))
		Behavior.MIRROR:
			_mirror(sim, fighter_index, intent)


func _mirror(sim: MatchSimulation, fighter_index: int, intent: Intent) -> void:
	var me: FighterState = sim.fighters[fighter_index]
	var other: FighterState = sim.opponent_of(me)
	if me.is_attacking() or not other.is_attacking() or other.move == null or other.move_phase != FighterState.Phase.STARTUP:
		return
	intent.press(Intent.Command.HEAVY if other.move.is_heavy() else Intent.Command.LIGHT)


func _play(facing: int, intent: Intent) -> void:
	if playback.length() == 0:
		return
	intent.unpack_relative(playback.packed_at(_cursor), facing)
	_cursor = (_cursor + 1) % playback.length()


func debug_lines() -> PackedStringArray:
	return PackedStringArray(["dummy %s" % Behavior.keys()[behavior].to_lower()])
