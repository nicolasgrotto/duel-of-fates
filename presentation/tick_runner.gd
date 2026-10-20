class_name TickRunner
extends Node

signal ticked
signal combat_event(event: CombatEvent)

const MAX_STEPS_PER_FRAME: int = 5

var sim: MatchSimulation
var controllers: Array[FighterController] = []
var intents: Array[Intent] = [Intent.new(), Intent.new()]
var recording: IntentRecording = IntentRecording.new(2)
var round_snapshot: Dictionary = {}
var records: bool = true
var allows_slow_motion: bool = true
var time_scale: float = 1.0
var alpha: float = 0.0

var _accumulator: float = 0.0
var _slow_scale: float = 1.0
var _slow_left: float = 0.0


func start(simulation: MatchSimulation, fighter_controllers: Array[FighterController]) -> void:
	sim = simulation
	controllers = fighter_controllers
	_accumulator = 0.0
	_slow_left = 0.0
	if records:
		recording.clear()
		round_snapshot = sim.capture()


func slow_motion(scale: float, seconds: float) -> void:
	if not allows_slow_motion:
		return
	_slow_scale = scale
	_slow_left = seconds


func _process(delta: float) -> void:
	if sim == null:
		return
	var scale: float = time_scale
	if _slow_left > 0.0:
		scale *= _slow_scale
		_slow_left -= delta
	_accumulator += delta * scale
	var steps: int = 0
	while _accumulator >= Ticks.DELTA and steps < MAX_STEPS_PER_FRAME:
		_accumulator -= Ticks.DELTA
		step_once()
		steps += 1
	if steps == MAX_STEPS_PER_FRAME:
		_accumulator = 0.0
	alpha = _accumulator / Ticks.DELTA


func _unhandled_input(event: InputEvent) -> void:
	for controller in controllers:
		controller.handle_input(event)


func step_once() -> void:
	for i in controllers.size():
		controllers[i].produce(sim, i, intents[i])
	if records:
		recording.append_tick(intents)
	sim.step(intents[0], intents[1])
	for i in sim.event_count:
		var event: CombatEvent = sim.events[i]
		_react_to_rules(event)
		combat_event.emit(event)
	ticked.emit()


func _react_to_rules(event: CombatEvent) -> void:
	var config: CombatConfig = sim.config
	match event.type:
		CombatEvent.Type.ROUND_STARTED:
			if records:
				recording.clear()
				round_snapshot = sim.capture()
		CombatEvent.Type.PERFECT_PARRY:
			slow_motion(config.perfect_parry_slow_motion_scale, config.perfect_parry_slow_motion)
		CombatEvent.Type.DEATH:
			slow_motion(config.knockout_slow_motion_scale, config.knockout_slow_motion)
