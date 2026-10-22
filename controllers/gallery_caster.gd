class_name GalleryCaster
extends FighterController

const SECOND_PRESS: float = 0.6
const AIR_DELAY: float = 0.25

var power: PowerData
var technique: MoveData
var _ticks: int = -1
var _hold_ticks: int = 0
var _second_press: int = -1


func perform(new_power: PowerData, new_technique: MoveData) -> void:
	power = new_power
	technique = new_technique
	_ticks = 0
	_hold_ticks = Ticks.from_seconds(power.max_channel) if power != null and power.is_channeled() else 0
	_second_press = Ticks.from_seconds(SECOND_PRESS) if power != null and power.kind == PowerData.Kind.ARSENAL else -1


func produce(sim: MatchSimulation, fighter_index: int, intent: Intent) -> void:
	intent.clear()
	if _ticks < 0:
		return
	var tick: int = _ticks
	_ticks += 1
	if technique != null:
		_technique_step(sim.fighters[fighter_index], tick, intent)
		return
	if tick == 0 or tick == _second_press:
		intent.press(Intent.Command.POWER)
	elif tick < _hold_ticks:
		intent.hold(Intent.Command.POWER)


func _technique_step(fighter: FighterState, tick: int, intent: Intent) -> void:
	if technique.aerial_technique:
		if tick == 0:
			intent.press(Intent.Command.JUMP)
		elif tick == Ticks.from_seconds(AIR_DELAY):
			intent.press(Intent.Command.SPECIAL)
		return
	if tick == 0:
		intent.move_x = fighter.facing
		intent.press(Intent.Command.SPECIAL)


func debug_lines() -> PackedStringArray:
	var shown: String = String(power.id) if power != null else (String(technique.id) if technique != null else "-")
	return PackedStringArray(["gallery caster %s" % shown])
