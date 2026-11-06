class_name SpaceProgress
extends RefCounted

const CONFIG: SpaceUpgradeConfig = preload("res://data/space/upgrades.tres")
const IDS: PackedStringArray = ["open_corridor", "ash_trail", "last_escort", "cut_network", "iron_graveyard", "tide_iron"]
const SHIPS: Array[SpaceShipData] = [
	preload("res://data/space/ships/mission_ship.tres"),
	preload("res://data/space/ships/needle.tres"),
	preload("res://data/space/ships/anvil.tres"),
	preload("res://data/space/ships/spear.tres"),
]

var records: Dictionary = {}
var ship_levels: Dictionary = {}
var levels: PackedInt32Array:
	get:
		return levels_for(ship_id)
var ship_id: StringName = SHIPS[0].id


func earned() -> int:
	return records.size()


func levels_for(id: StringName) -> PackedInt32Array:
	if not ship_levels.has(id):
		ship_levels[id] = PackedInt32Array([0, 0, 0])
	return ship_levels[id]


func available(id: StringName = &"") -> int:
	var owned: PackedInt32Array = levels_for(id if id != &"" else ship_id)
	return earned() - (owned[0] + owned[1] + owned[2]) * CONFIG.cost


func record(id: StringName, ticks: int, rating: int) -> bool:
	if not String(id) in IDS or ticks <= 0 or rating < 1 or rating > 3:
		return false
	var previous: Dictionary = records.get(String(id), {})
	records[String(id)] = {"ticks": mini(ticks, int(previous.get("ticks", ticks))), "rating": maxi(rating, int(previous.get("rating", 0)))}
	return previous.is_empty()


func buy(track: int, id: StringName = &"") -> bool:
	var target: StringName = id if id != &"" else ship_id
	var owned: PackedInt32Array = levels_for(target)
	if track < 0 or track >= owned.size() or owned[track] >= CONFIG.max_level or available(target) < CONFIG.cost:
		return false
	owned[track] += 1
	ship_levels[target] = owned
	return true


func reset_upgrades(id: StringName = &"") -> void:
	ship_levels[id if id != &"" else ship_id] = PackedInt32Array([0, 0, 0])


func selected_ship() -> SpaceShipData:
	for ship in SHIPS:
		if ship.id == ship_id:
			return ship
	return SHIPS[0]


func select_ship(id: StringName) -> bool:
	for ship in SHIPS:
		if ship.id == id:
			ship_id = id
			return true
	return false


func loadout() -> SpaceLoadout:
	return loadout_for(selected_ship())


func loadout_for(ship: SpaceShipData) -> SpaceLoadout:
	var owned: PackedInt32Array = levels_for(ship.id)
	var result: SpaceLoadout = SpaceLoadout.new()
	result.ship = ship
	result.weapon_level = owned[0]
	result.shield_level = owned[1]
	result.speed_level = owned[2]
	return result


func capture() -> Dictionary:
	var saved_levels: Dictionary = {}
	for ship in SHIPS:
		saved_levels[String(ship.id)] = Array(levels_for(ship.id))
	return {"records": records.duplicate(true), "ship_levels": saved_levels, "ship": String(ship_id)}


func restore(state: Dictionary) -> void:
	records.clear()
	ship_levels.clear()
	ship_id = SHIPS[0].id
	select_ship(StringName(str(state.get("ship", ""))))
	var saved: Variant = state.get("records", {})
	if saved is Dictionary:
		for id in IDS:
			var row: Variant = saved.get(id, {})
			if row is Dictionary:
				record(StringName(id), int(row.get("ticks", 0)), int(row.get("rating", 0)))
	var saved_levels: Variant = state.get("ship_levels", {})
	for ship in SHIPS:
		var upgrades: Variant = saved_levels.get(String(ship.id), state.get("levels", [])) if saved_levels is Dictionary else []
		_rebuy(ship.id, upgrades)


func _rebuy(id: StringName, upgrades: Variant) -> void:
	if not (upgrades is Array or upgrades is PackedInt32Array):
		return
	for track in mini(upgrades.size(), levels_for(id).size()):
		var desired: int = clampi(int(upgrades[track]), 0, CONFIG.max_level)
		for level in desired:
			buy(track, id)
