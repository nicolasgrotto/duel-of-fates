class_name DuelSetup
extends RefCounted

enum ControllerKind { PLAYER, AI, DUMMY, GALLERY }

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
var power_sets: Array = [[], []]


func fill_default_looks() -> void:
	for i in characters.size():
		if costumes.size() <= i:
			costumes.append(characters[i].costumes[0])
		if blade_colors.size() <= i:
			blade_colors.append(characters[i].blade_colors[0])
