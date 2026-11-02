class_name DuelSetup
extends RefCounted

enum ControllerKind { PLAYER, AI, DUMMY, GALLERY, CHOREOGRAPHY }

var characters: Array[CharacterData] = []
var costumes: Array[CostumeData] = []
var blade_colors: Array[Color] = []
var controllers: Array[ControllerKind] = []
var player_slots: Array[int] = [0, 1]
var hold_to_lock: Array[bool] = [false, false]
var difficulty: AiDifficultyData
var rules: MatchRules
var arena: ArenaData
var match_seed: int = 0
var training: bool = false
var gallery: bool = false
var two_players: bool = false
var awakening: Array = [null, null]
var banner: String = ""
var objective: bool = false
var power_sets: Array = [[], []]
var flow_levels: Array[int] = [0, 0]
var bout: ExhibitionBout
var bout_skip_key: String = "HINT_NEXT_BOUT"


func fill_default_looks() -> void:
	for i in characters.size():
		if costumes.size() <= i:
			costumes.append(characters[i].costumes[0])
		if blade_colors.size() <= i:
			blade_colors.append(characters[i].blade_colors[0])


func equip(sim: MatchSimulation) -> void:
	for i in sim.fighters.size():
		var custom: Array[PowerData] = []
		custom.assign(power_sets[i])
		if not custom.is_empty():
			sim.fighters[i].equip_powers(custom)
		if flow_levels[i] > 0:
			sim.fighters[i].set_flow_level(flow_levels[i], sim.config)
		if bout != null:
			sim.fighters[i].blade_multiplier *= bout.blade_scale[i]
