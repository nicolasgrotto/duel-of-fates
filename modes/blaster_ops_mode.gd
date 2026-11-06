class_name BlasterOpsMode
extends InfiltrationMode

signal finished(value: BlasterOpsMissionResult)
signal exit_requested

const TUTORIALS: Array[BlasterOpsMissionData] = [
	preload("res://data/blaster_ops/missions/training_infiltration.tres"),
	preload("res://data/blaster_ops/missions/training_incursion.tres"),
]
const INCURSIONS: Array[BlasterOpsMissionData] = [
	preload("res://data/blaster_ops/missions/encircled_yard.tres"),
	preload("res://data/blaster_ops/missions/breach_line.tres"),
	preload("res://data/blaster_ops/missions/defense_node.tres"),
	preload("res://data/blaster_ops/missions/extraction_window.tres"),
	preload("res://data/blaster_ops/missions/ally_corridor.tres"),
	preload("res://data/blaster_ops/missions/retreat_vector.tres"),
	preload("res://data/blaster_ops/missions/siege_core.tres"),
]

const RECORD_LAYOUT: int = 2

var external: bool = false
var sealed: BlasterOpsMissionResult


func _init(mission_data: BlasterOpsMissionData, fighter: CharacterData = null, loadout: BlasterOpsLoadout = null, embedded: bool = false, appearance: InfiltrationLook = null) -> void:
	super(mission_data, fighter, loadout, appearance)
	external = embedded


func start() -> void:
	sealed = null
	super.start()


func finish(sim: InfiltrationSimulation) -> void:
	if sealed != null or sim.mission.outcome == InfiltrationMissionState.Outcome.ACTIVE:
		return
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	sealed = BlasterOpsMissionResult.new()
	sealed.mission_id = data.id
	sealed.won = progress.outcome == InfiltrationMissionState.Outcome.COMPLETED
	sealed.ticks = progress.finished_tick
	sealed.damage = progress.damage_taken
	sealed.attempts = progress.attempts
	sealed.hits = progress.hits
	sealed.bonuses = progress.bonuses(sealed.ticks) | (8 if progress.bonus_objective(sim) else 0)
	if sealed.won:
		sealed.rating = 1
		for bit in 4:
			sealed.rating += int((sealed.bonuses & (1 << bit)) != 0)
		sealed.rating = clampi(sealed.rating - 1, 1, 4)
	result = progress.capture()
	result.merge(sealed.to_dict(), true)
	result["objectives"] = objective_lines(sim)
	if not external and sealed.won and not (data as BlasterOpsMissionData).tutorial:
		SaveService.record_incursion(data.id, sealed.ticks, sealed.rating, sealed.bonuses)
	finished.emit(sealed)


func objective_lines(sim: InfiltrationSimulation) -> Array[Dictionary]:
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	if not progress.definition.stages.is_empty():
		var lines: Array[Dictionary] = []
		for index in progress.definition.stages.size():
			lines.append({"key": progress.definition.stages[index].title_key, "index": index + 1, "done": index < progress.stage_index})
		return lines
	return [{"key": "OPS_GOAL", "index": 1, "done": progress.goal_done(sim)}, {"key": "OPS_FINAL_WAVE", "index": 1, "done": progress.waves_finished}]


func next() -> void:
	var catalog: Array[InfiltrationMissionData] = all_missions()
	var index: int = catalog.find(data)
	SceneRouter.change(&"operations", {"mission": catalog[index + 1].id if index >= 0 and index + 1 < catalog.size() else data.id})


static func menu_missions() -> Array[InfiltrationMissionData]:
	var missions: Array[InfiltrationMissionData] = []
	missions.assign(TUTORIALS)
	missions.append_array(all_missions())
	return missions


static func all_missions() -> Array[InfiltrationMissionData]:
	var missions: Array[InfiltrationMissionData] = []
	missions.assign(InfiltrationMode.MISSIONS)
	missions.append_array(INCURSIONS)
	return missions


static func rating_key(value: int) -> String:
	return ["OPS_UNRATED", "OPS_RATING_C", "OPS_RATING_B", "OPS_RATING_A", "OPS_RATING_S"][clampi(value, 0, 4)]


static func incursion_bonus_text(mask: int) -> String:
	var lines: PackedStringArray = []
	for bit in 4:
		lines.append(TranslationServer.translate("INF_CHECK").format({"state": TranslationServer.translate("INF_DONE" if (mask & (1 << bit)) != 0 else "INF_PENDING"), "objective": TranslationServer.translate(["OPS_BONUS_TIME", "OPS_BONUS_DAMAGE", "OPS_BONUS_ACCURACY", "OPS_BONUS_OBJECTIVE"][bit])}))
	return "\n".join(lines)
