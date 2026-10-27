extends Node

const SAVE_PATH: String = "user://progress.cfg"
const FORMAT_VERSION: int = 1
const SECTION: String = "progress"

var path: String = SAVE_PATH
var arcade_cleared: Dictionary = {}
var survival_best: int = 0
var parry_best: int = 0
var challenge_best: Dictionary = {}
var hunt_best: Dictionary = {}
var infiltration_best: Dictionary = {}
var unlocked: Dictionary = {}
var campaign: Dictionary = {}


func _ready() -> void:
	load_progress()


func reset() -> void:
	arcade_cleared = {}
	survival_best = 0
	parry_best = 0
	challenge_best = {}
	hunt_best = {}
	infiltration_best = {}
	unlocked = {}
	campaign = {}


func load_progress() -> void:
	reset()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	var version: int = file.get_value(SECTION, "version", 0)
	if version > FORMAT_VERSION:
		return
	arcade_cleared = file.get_value(SECTION, "arcade_cleared", {})
	survival_best = file.get_value(SECTION, "survival_best", 0)
	parry_best = file.get_value(SECTION, "parry_best", 0)
	challenge_best = file.get_value(SECTION, "challenge_best", {})
	hunt_best = file.get_value(SECTION, "hunt_best", {})
	infiltration_best = file.get_value(SECTION, "infiltration_best", {})
	unlocked = file.get_value(SECTION, "unlocked", {})
	campaign = file.get_value(SECTION, "campaign", {})


func save_progress() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION, "version", FORMAT_VERSION)
	file.set_value(SECTION, "arcade_cleared", arcade_cleared)
	file.set_value(SECTION, "survival_best", survival_best)
	file.set_value(SECTION, "parry_best", parry_best)
	file.set_value(SECTION, "challenge_best", challenge_best)
	file.set_value(SECTION, "hunt_best", hunt_best)
	file.set_value(SECTION, "infiltration_best", infiltration_best)
	file.set_value(SECTION, "unlocked", unlocked)
	file.set_value(SECTION, "campaign", campaign)
	file.save(path)


func clear_arcade(character_id: StringName) -> void:
	arcade_cleared[String(character_id)] = true
	save_progress()


func has_cleared_arcade(character_id: StringName) -> bool:
	return arcade_cleared.get(String(character_id), false)


func record_survival(wins: int) -> bool:
	if wins <= survival_best:
		return false
	survival_best = wins
	save_progress()
	return true


func record_parry(points: int) -> bool:
	if points <= parry_best:
		return false
	parry_best = points
	save_progress()
	return true


func record_challenge(id: StringName, seconds: float) -> bool:
	var key: String = String(id)
	if challenge_best.has(key) and seconds >= challenge_best[key]:
		return false
	challenge_best[key] = seconds
	save_progress()
	return true


func unlock(key: String) -> bool:
	if unlocked.get(key, false):
		return false
	unlocked[key] = true
	save_progress()
	return true


func record_hunt(id: StringName, seconds: float) -> bool:
	var key: String = String(id)
	if hunt_best.has(key) and seconds >= hunt_best[key]:
		return false
	hunt_best[key] = seconds
	save_progress()
	return true


func is_unlocked(key: String) -> bool:
	return unlocked.get(key, false)


func record_infiltration(id: StringName, ticks: int, bonuses: int) -> bool:
	if ticks <= 0:
		return false
	var key: String = String(id)
	var previous: Dictionary = infiltration_best.get(key, {})
	var best: int = mini(ticks, int(previous.get("ticks", ticks)))
	var combined: int = bonuses | int(previous.get("bonuses", 0))
	if not previous.is_empty() and best == int(previous.ticks) and combined == int(previous.bonuses):
		return false
	infiltration_best[key] = {"ticks": best, "bonuses": combined}
	save_progress()
	return true
