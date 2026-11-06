class_name SpaceMissionData
extends Resource

enum MapLabel { BELOW, ABOVE, RIGHT }

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
@export var preview: Texture2D
@export var tutorial_steps: Array[SpaceTutorialStep] = []
@export_range(1, 5) var threat: int = 1
@export var map_position: Vector2
@export var map_label: MapLabel = MapLabel.BELOW


func is_tutorial() -> bool:
	return not tutorial_steps.is_empty()


func enemy_types() -> Array[SpaceShipData]:
	var found: Array[SpaceShipData] = []
	for placement in arena.ships:
		_note_enemy(found, placement.ship, placement.team)
	for wave in waves:
		for placement in wave.ships:
			_note_enemy(found, placement.ship, placement.team)
		for formation in wave.formations:
			_note_enemy(found, formation.ship, formation.team)
	return found


func _note_enemy(found: Array[SpaceShipData], ship: SpaceShipData, team: int) -> void:
	if ship == null or team == 0 or ship.archetype == SpaceShipData.Archetype.SECTION or ship in found:
		return
	found.append(ship)


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
