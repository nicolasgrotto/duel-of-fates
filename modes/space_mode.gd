class_name SpaceMode
extends RefCounted

signal finished(result: SpaceMissionResult)
signal exit_requested

const CONFIG: SpaceConfig = preload("res://data/balance/space_config.tres")
const UPGRADES: SpaceUpgradeConfig = preload("res://data/space/upgrades.tres")
const MISSIONS: Array[SpaceMissionData] = [
	preload("res://data/space/missions/open_corridor.tres"),
	preload("res://data/space/missions/ash_trail.tres"),
	preload("res://data/space/missions/last_escort.tres"),
	preload("res://data/space/missions/cut_network.tres"),
	preload("res://data/space/missions/tide_iron.tres"),
]

var data: SpaceMissionData
var loadout: SpaceLoadout
var external: bool = false
var result: SpaceMissionResult
var _simulation: SpaceSimulation


func _init(mission: SpaceMissionData, equipment: SpaceLoadout, external_flow: bool = false) -> void:
	data = mission
	loadout = equipment.duplicate() as SpaceLoadout
	external = external_flow


func create_simulation() -> SpaceSimulation:
	result = null
	_simulation = SpaceSimulation.new(CONFIG, data.create_arena(loadout, UPGRADES), data)
	return _simulation


func start() -> void:
	result = null
	SceneRouter.change(&"space_mission", {"mode": self})


func finish(sim: SpaceSimulation) -> void:
	if result != null or sim != _simulation or sim.mission.outcome == SpaceMissionState.Outcome.ACTIVE:
		return
	result = SpaceMissionResult.new()
	result.mission_id = data.id
	result.outcome = sim.mission.outcome
	result.ticks = sim.mission.finished_tick
	result.rating = sim.mission.rating(sim)
	result.hull = sim.ships[0].hull / sim.ships[0].data.hull
	result.phase_visits = sim.mission.phase_visits.duplicate()
	result.waves = sim.mission.wave
	result.objectives.append({"key": data.objective_key, "done": result.won()})
	if data.protected_ship >= 0:
		result.objectives.append({"key": "SPACE_KEEP_ALLY", "done": sim.ships[data.protected_ship].hull > 0.0})
	if result.won() and not external:
		result.point_earned = SaveService.record_space(data.id, result.ticks, result.rating)
	finished.emit(result)


func next() -> void:
	var index: int = MISSIONS.find(data)
	SceneRouter.change(&"space", {"mission": MISSIONS[index + 1].id if index >= 0 and index + 1 < MISSIONS.size() else data.id})
