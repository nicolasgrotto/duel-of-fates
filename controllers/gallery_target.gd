class_name GalleryTarget
extends FighterController

enum Behavior { STAND, GUARD, BARRIER, ABSORPTION, AIR, LIGHTNING }

const POWERED: Array[Behavior] = [Behavior.BARRIER, Behavior.ABSORPTION, Behavior.LIGHTNING]

var behavior: Behavior = Behavior.STAND


func produce(sim: MatchSimulation, fighter_index: int, intent: Intent) -> void:
	intent.clear()
	var fighter: FighterState = sim.fighters[fighter_index]
	match behavior:
		Behavior.GUARD:
			intent.hold(Intent.Command.BLOCK)
		Behavior.AIR:
			if not fighter.is_airborne():
				intent.press(Intent.Command.JUMP)
		Behavior.BARRIER, Behavior.ABSORPTION, Behavior.LIGHTNING:
			if fighter.is_casting():
				intent.hold(Intent.Command.POWER)
			else:
				intent.press(Intent.Command.POWER)


func uses_power() -> bool:
	return POWERED.has(behavior)


func debug_lines() -> PackedStringArray:
	return PackedStringArray(["gallery target %s" % Behavior.keys()[behavior].to_lower()])
