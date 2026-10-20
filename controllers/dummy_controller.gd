class_name DummyController
extends FighterController

enum Behavior { STAND, GUARD, ATTACK, PLAYBACK }

var behavior: Behavior = Behavior.STAND
var playback: IntentRecording = IntentRecording.new(1)
var _config: TrainingConfig
var _ticks: int = 0
var _attacks: int = 0
var _cursor: int = 0


func _init(config: TrainingConfig) -> void:
	_config = config


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


func _play(facing: int, intent: Intent) -> void:
	if playback.length() == 0:
		return
	intent.unpack_relative(playback.packed_at(_cursor), facing)
	_cursor = (_cursor + 1) % playback.length()


func debug_lines() -> PackedStringArray:
	return PackedStringArray(["dummy %s" % Behavior.keys()[behavior].to_lower()])
