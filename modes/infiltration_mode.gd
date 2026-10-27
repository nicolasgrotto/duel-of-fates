class_name InfiltrationMode
extends RefCounted

const MISSIONS: Array[InfiltrationMissionData] = [
	preload("res://data/infiltration/missions/first_access.tres"),
	preload("res://data/infiltration/missions/silent_network.tres"),
	preload("res://data/infiltration/missions/cold_archive.tres"),
	preload("res://data/infiltration/missions/way_back.tres"),
]

var data: InfiltrationMissionData
var result: Dictionary = {}


func _init(mission: InfiltrationMissionData) -> void:
	data = mission


func start() -> void:
	result = {}
	SceneRouter.change(&"infiltration_mission", {"mode": self})


func finish(sim: InfiltrationSimulation) -> void:
	if not result.is_empty() or sim.mission == null or sim.mission.outcome == InfiltrationMissionState.Outcome.ACTIVE:
		return
	result = sim.mission.capture()
	result["ticks"] = sim.mission.finished_tick
	result["bonuses"] = sim.mission.bonuses(sim.mission.finished_tick)
	result["objectives"] = objective_lines(sim)
	if sim.mission.outcome == InfiltrationMissionState.Outcome.COMPLETED:
		SaveService.record_infiltration(data.id, result.ticks, result.bonuses)


func objective_lines(sim: InfiltrationSimulation) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if data.disable_alarms:
		for index in sim.panels.size():
			lines.append({"key": "INF_OBJECTIVE_PANEL", "index": index + 1, "done": sim.panels[index].disabled})
	for index in sim.mission.copied.size():
		lines.append({"key": "INF_OBJECTIVE_TERMINAL", "index": index + 1, "done": sim.mission.copied[index] != 0})
	for index in sim.mission.extracted.size():
		lines.append({"key": "INF_OBJECTIVE_PRISONER", "index": index + 1, "done": sim.mission.extracted[index] != 0})
	lines.append({"key": "INF_OBJECTIVE_EXIT", "index": 1, "done": sim.mission.outcome == InfiltrationMissionState.Outcome.COMPLETED})
	return lines


func next() -> void:
	var index: int = MISSIONS.find(data)
	SceneRouter.change(&"infiltration", {"mission": MISSIONS[index + 1].id if index >= 0 and index + 1 < MISSIONS.size() else data.id})


static func bonus_text(mask: int) -> String:
	var lines: PackedStringArray = []
	var keys: PackedStringArray = ["INF_BONUS_ALARM", "INF_BONUS_ABATES", "INF_BONUS_TIME"]
	for index in keys.size():
		lines.append(TranslationServer.translate("INF_CHECK").format({"state": TranslationServer.translate("INF_DONE" if (mask & (1 << index)) != 0 else "INF_PENDING"), "objective": TranslationServer.translate(keys[index])}))
	return "\n".join(lines)
