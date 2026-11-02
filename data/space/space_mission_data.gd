class_name SpaceMissionData
extends Resource

@export var id: StringName
@export var title_key: String
@export var briefing_key: String
@export var objective_key: String
@export var arena: SpaceArenaData
@export var waves: Array[SpaceWaveData] = []
@export var par_seconds: float = 60.0
@export var limit_seconds: float = 180.0
@export var protected_ship: int = -1
@export var boss: int = -1
@export var phases: Array[SpaceBossPhase] = []


func create_arena(loadout: SpaceLoadout, upgrades: SpaceUpgradeConfig) -> SpaceArenaData:
	var result: SpaceArenaData = arena.duplicate() as SpaceArenaData
	result.ships = []
	for index in arena.ships.size():
		var placement: SpaceShipPlacement = arena.ships[index].duplicate() as SpaceShipPlacement
		if index == 0:
			placement.ship = loadout.build_ship(upgrades, placement.ship)
		result.ships.append(placement)
	for index in waves.size():
		for original in waves[index].ships:
			var placement: SpaceShipPlacement = original.duplicate() as SpaceShipPlacement
			placement.wave = index + 1
			result.ships.append(placement)
		for formation in waves[index].formations:
			formation.append_to(result, index + 1)
	return result
