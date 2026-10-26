class_name HuntController
extends AiController

var tracker: HuntTracker
var _phase_index: int = -1


func _init(data: HuntTracker, ai_seed: int) -> void:
	tracker = data
	super(data.hunt.difficulty, data.hunt.phases[0].profile, ai_seed)


func produce(sim: MatchSimulation, index: int, intent: Intent) -> void:
	if _phase_index != tracker.phase_index:
		_phase_index = tracker.phase_index
		if tracker.phase() != null:
			profile = tracker.phase().profile
			_reset_plan()
			_think_ticks = 0
	var current: HuntPhase = tracker.phase()
	var me: FighterState = sim.fighters[index]
	if sim.phase == MatchSimulation.Phase.FIGHT and current != null and not tracker.opening_activated and me.is_free() and me.on_ground and me.singularity_ticks <= 0 and me.rain_ticks <= 0:
		if AiPowers.is_ready(sim, me, current.opening_slot):
			intent.clear()
			intent.pressed = Intent.Command.POWER
			intent.held = Intent.Command.POWER
			intent.move_x = AiPowers.direction_for(current.opening_slot) * me.facing
			decision = "hunt opening"
			return
	super.produce(sim, index, intent)
