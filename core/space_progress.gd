class_name SpaceProgress
extends RefCounted

const CONFIG: SpaceUpgradeConfig = preload("res://data/space/upgrades.tres")
const IDS: PackedStringArray = ["open_corridor", "ash_trail", "last_escort", "cut_network", "tide_iron"]

var records: Dictionary = {}
var levels: PackedInt32Array = [0, 0, 0]


func available() -> int:
	return records.size() - (levels[0] + levels[1] + levels[2]) * CONFIG.cost


func record(id: StringName, ticks: int, rating: int) -> bool:
	if not String(id) in IDS or ticks <= 0 or rating < 1 or rating > 3:
		return false
	var previous: Dictionary = records.get(String(id), {})
	records[String(id)] = {"ticks": mini(ticks, int(previous.get("ticks", ticks))), "rating": maxi(rating, int(previous.get("rating", 0)))}
	return previous.is_empty()


func buy(track: int) -> bool:
	if track < 0 or track >= levels.size() or levels[track] >= CONFIG.max_level or available() < CONFIG.cost:
		return false
	levels[track] += 1
	return true


func reset_upgrades() -> void:
	levels.fill(0)


func loadout() -> SpaceLoadout:
	var result: SpaceLoadout = SpaceLoadout.new()
	result.weapon_level = levels[0]
	result.shield_level = levels[1]
	result.speed_level = levels[2]
	return result


func capture() -> Dictionary:
	return {"records": records.duplicate(true), "levels": levels.duplicate()}


func restore(state: Dictionary) -> void:
	records.clear()
	levels.fill(0)
	var saved: Variant = state.get("records", {})
	if saved is Dictionary:
		for id in IDS:
			var row: Variant = saved.get(id, {})
			if row is Dictionary:
				record(StringName(id), int(row.get("ticks", 0)), int(row.get("rating", 0)))
	var upgrades: Variant = state.get("levels", [])
	if upgrades is Array or upgrades is PackedInt32Array:
		for track in mini(upgrades.size(), levels.size()):
			var desired: int = clampi(int(upgrades[track]), 0, CONFIG.max_level)
			for level in desired:
				buy(track)
