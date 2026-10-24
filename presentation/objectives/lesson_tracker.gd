class_name LessonTracker
extends DuelObjective

var lesson: LessonData
var dummy: DummyController
var config: TrainingConfig
var player: int = 0
var step_index: int = 0
var progress: int = 0

var _last_x: float = 0.0
var _walked: float = 0.0
var _evade_tick: int = -1


func _init(lesson_data: LessonData, dummy_controller: DummyController, training: TrainingConfig) -> void:
	lesson = lesson_data
	dummy = dummy_controller
	config = training
	_enter_step()


func step() -> LessonStep:
	return lesson.steps[step_index] if step_index < lesson.steps.size() else null


func on_tick(sim: MatchSimulation) -> void:
	if done or step() == null:
		return
	var me: FighterState = sim.fighters[player]
	if sim.phase != MatchSimulation.Phase.FIGHT:
		_last_x = me.x
		return
	if step().goal == LessonStep.Goal.WALK:
		_walked += absf(me.x - _last_x)
		if _walked >= config.walk_distance:
			_walked = 0.0
			_advance()
	_last_x = me.x


func on_event(event: CombatEvent, sim: MatchSimulation) -> void:
	if done or step() == null:
		return
	if event.type == CombatEvent.Type.EVADE_SUCCESS and event.target == player:
		_evade_tick = sim.tick
	if _matches(step().goal, event, sim):
		_advance()


func _matches(goal: LessonStep.Goal, event: CombatEvent, sim: MatchSimulation) -> bool:
	var mine: bool = event.source == player
	var against_me: bool = event.target == player
	var move: MoveData = event.move
	match goal:
		LessonStep.Goal.LIGHT_HIT:
			return mine and event.type == CombatEvent.Type.HIT and move != null and move.kind == MoveData.Kind.LIGHT
		LessonStep.Goal.CHAIN_HIT:
			return mine and event.type == CombatEvent.Type.HIT and move != null and _closes_chain(sim.fighters[player].character, move)
		LessonStep.Goal.HEAVY_HIT:
			return mine and event.type == CombatEvent.Type.HIT and event.heavy
		LessonStep.Goal.BLOCK:
			return against_me and event.type == CombatEvent.Type.BLOCK
		LessonStep.Goal.PARRY_HEAVY:
			return against_me and event.heavy and (event.type == CombatEvent.Type.PARRY or event.type == CombatEvent.Type.PERFECT_PARRY)
		LessonStep.Goal.COUNTER:
			return mine and event.type == CombatEvent.Type.HIT and move != null and move.kind == MoveData.Kind.COUNTER
		LessonStep.Goal.SHOVE:
			return mine and event.type == CombatEvent.Type.SHOVE
		LessonStep.Goal.GUARD_BREAK:
			return mine and event.type == CombatEvent.Type.GUARD_BREAK
		LessonStep.Goal.WOUND:
			return mine and event.type == CombatEvent.Type.WOUND
		LessonStep.Goal.LOCK_WIN:
			return mine and event.type == CombatEvent.Type.BLADE_LOCK_ENDED
		LessonStep.Goal.ABILITY:
			return mine and event.type == CombatEvent.Type.ATTACK_STARTED and move != null and (move.kind == MoveData.Kind.ABILITY or move.kind == MoveData.Kind.STANCE)
		LessonStep.Goal.EVADE:
			return against_me and event.type == CombatEvent.Type.EVADE_SUCCESS
		LessonStep.Goal.EVADE_STREAK:
			return against_me and event.type == CombatEvent.Type.EVADE_SUCCESS and event.amount >= 3.0
		LessonStep.Goal.EVADE_PUNISH:
			return mine and event.type == CombatEvent.Type.HIT and _evade_tick >= 0 and sim.tick - _evade_tick <= Ticks.from_seconds(config.evade_punish_window)
		LessonStep.Goal.EXHAUST:
			return mine and event.type == CombatEvent.Type.EXHAUSTION
		LessonStep.Goal.RECOVER:
			return mine and event.type == CombatEvent.Type.EXHAUSTION_RECOVERED
		LessonStep.Goal.DISENGAGE:
			return mine and event.type == CombatEvent.Type.DISENGAGE
		LessonStep.Goal.PRESS_WIN:
			return mine and event.type == CombatEvent.Type.BLADE_PRESS_ENDED
		LessonStep.Goal.SPIN_DODGE:
			return mine and event.type == CombatEvent.Type.DODGE and int(event.amount) == FighterState.DodgeKind.SPIN
	return false


static func _closes_chain(character: CharacterData, move: MoveData) -> bool:
	var chain: Array[MoveData] = character.light_chain
	return chain.size() > 1 and chain.find(move) == chain.size() - 1


func _advance() -> void:
	progress += 1
	if progress >= step().count:
		step_index += 1
		progress = 0
		if step_index >= lesson.steps.size():
			_finish()
			return
		_enter_step()


func instruction() -> String:
	return format_keys(TranslationServer.translate(step().text_key)) if step() != null else ""


func progress_line() -> String:
	if step() == null:
		return ""
	return TranslationServer.translate("LESSON_PROGRESS").format({
		"step": step_index + 1, "total": lesson.steps.size(), "done": progress, "count": step().count,
	})


func result_title() -> String:
	return TranslationServer.translate(lesson.done_key)


func _enter_step() -> void:
	_walked = 0.0
	if step() != null and dummy != null:
		dummy.set_behavior(step().dummy)
