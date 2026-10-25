class_name DuelSelection
extends RefCounted

var characters: Array[CharacterData] = [null, null]
var costumes: Array[CostumeData] = [null, null]
var blade_colors: Array[Color] = [Color.WHITE, Color.WHITE]
var arena: ArenaData
var power_sets: Array = [[], []]


func is_complete(slots: int) -> bool:
	for i in slots:
		if characters[i] == null:
			return false
	return true


func apply_to(setup: DuelSetup) -> void:
	for i in characters.size():
		if characters[i] == null:
			continue
		setup.characters[i] = characters[i]
		setup.costumes[i] = costumes[i]
		setup.blade_colors[i] = blade_colors[i]
		setup.power_sets[i] = power_sets[i]
	if arena != null:
		setup.arena = arena
	_keep_mirror_matches_apart(setup)


func _keep_mirror_matches_apart(setup: DuelSetup) -> void:
	if setup.characters[0].id != setup.characters[1].id or setup.blade_colors[0] != setup.blade_colors[1]:
		return
	var colors: PackedColorArray = setup.characters[1].blade_colors
	if colors.size() > 1:
		setup.blade_colors[1] = colors[(colors.find(setup.blade_colors[0]) + 1) % colors.size()]
