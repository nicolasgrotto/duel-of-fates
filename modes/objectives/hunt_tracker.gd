class_name HuntTracker
extends DuelObjective

const PLAYER: int = 0
const BOSS: int = 1

var hunt: HuntData
var phase_index: int = -1
var fight_ticks: int = 0
var perfect_parries: int = 0
var survived_singularity: bool = false
var opening_activated: bool = false
var _singularity_launched: bool = false


func _init(data: HuntData) -> void:
	hunt = data


func phase() -> HuntPhase:
	return hunt.phases[phase_index] if phase_index >= 0 else null


func on_tick(sim: MatchSimulation) -> void:
	if sim.phase == MatchSimulation.Phase.KO and sim.phase_ticks == 0:
		fight_ticks += 1
	if sim.phase != MatchSimulation.Phase.FIGHT:
		return
	fight_ticks += 1
	var boss: FighterState = sim.fighters[BOSS]
	if not boss.is_alive() or not sim.fighters[PLAYER].is_alive():
		return
	if _singularity_launched and not _singularity_pending(sim):
		survived_singularity = true
	if boss.is_casting() or boss.rain_ticks > 0 or _singularity_pending(sim):
		return
	while phase_index + 1 < hunt.phases.size() and boss.health_ratio() <= hunt.phases[phase_index + 1].health_threshold:
		phase_index += 1
		_apply_phase(sim, boss)


func _apply_phase(sim: MatchSimulation, boss: FighterState) -> void:
	var current: HuntPhase = phase()
	boss.equip_powers(current.powers)
	boss.power_cooldowns.fill(0)
	boss.set_flow_level(current.flow_level, sim.config)
	boss.flow = clampf(current.starting_flow, 0.0, sim.config.flow.maximum)
	opening_activated = current.opening_slot < 0
	announced.emit(current.title_key)


func on_event(event: CombatEvent, _sim: MatchSimulation) -> void:
	if event.type == CombatEvent.Type.PERFECT_PARRY and event.target == PLAYER and event.source == BOSS and event.heavy:
		perfect_parries += 1
	if event.source != BOSS or event.power == null:
		return
	if event.type == CombatEvent.Type.POWER_ACTIVE and phase() != null and phase().opening_slot >= 0:
		if event.power == phase().powers[phase().opening_slot]:
			opening_activated = true
	if event.type == CombatEvent.Type.PROJECTILE_SPAWNED and event.power.kind == PowerData.Kind.SINGULARITY:
		_singularity_launched = true


func _singularity_pending(sim: MatchSimulation) -> bool:
	if sim.fighters[BOSS].singularity_ticks > 0:
		return true
	for projectile in sim.projectiles:
		if projectile.active and projectile.owner == BOSS and projectile.kind == Projectile.Kind.SINGULARITY:
			return true
	for hazard in sim.hazards:
		if hazard.active and hazard.owner == BOSS and hazard.kind == Hazard.Kind.EXTRACTION:
			return true
	return false


func condition_met() -> bool:
	match hunt.condition.goal:
		HuntCondition.Goal.PERFECT_PARRIES:
			return perfect_parries >= hunt.condition.count
		HuntCondition.Goal.TIME_LIMIT:
			return fight_ticks <= Ticks.from_seconds(hunt.condition.seconds)
		HuntCondition.Goal.SURVIVE_SINGULARITY:
			return survived_singularity
	return false


func instruction() -> String:
	return TranslationServer.translate("HUNT_BANNER").format({
		"name": TranslationServer.translate(hunt.title_key),
		"phase": TranslationServer.translate(phase().title_key) if phase() != null else "",
	})


func progress_line() -> String:
	var detail: String = TranslationServer.translate(hunt.condition.description_key)
	match hunt.condition.goal:
		HuntCondition.Goal.PERFECT_PARRIES:
			detail = TranslationServer.translate("HUNT_PARRY_PROGRESS").format({"done": perfect_parries, "count": hunt.condition.count})
		HuntCondition.Goal.TIME_LIMIT:
			detail = TranslationServer.translate("HUNT_TIME_PROGRESS").format({"time": ChallengeMode.format_time(maxf(hunt.condition.seconds - Ticks.to_seconds(fight_ticks), 0.0))})
		HuntCondition.Goal.SURVIVE_SINGULARITY:
			detail = TranslationServer.translate("HUNT_SURVIVED" if survived_singularity else "HUNT_SURVIVE_WAIT")
	return TranslationServer.translate("HUNT_PROGRESS").format({"condition": detail, "time": ChallengeMode.format_time(Ticks.to_seconds(fight_ticks))})


func debug_lines() -> PackedStringArray:
	return PackedStringArray(["hunt %s phase %d/%d parries %d survived %s met %s ticks %d" % [hunt.id, phase_index + 1, hunt.phases.size(), perfect_parries, survived_singularity, condition_met(), fight_ticks]])
