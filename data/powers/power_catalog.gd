class_name PowerCatalog
extends Resource

const SET_SIZE: int = 3

@export var powers: Array[PowerData] = []


static func technique_key(technique: MoveData) -> String:
	return "TECHNIQUE_" + String(technique.id).to_upper()


static func is_allowed(power: PowerData, character: CharacterData) -> bool:
	if power.min_level > character.flow:
		return false
	match power.path:
		PowerData.Path.AURORA:
			return character.path == CharacterData.Path.AURORA
		PowerData.Path.ECLIPSE:
			return character.path == CharacterData.Path.ECLIPSE
	return true


func allowed_for(character: CharacterData) -> Array[PowerData]:
	var allowed: Array[PowerData] = []
	for power in powers:
		if is_allowed(power, character):
			allowed.append(power)
	return allowed


func base_set(character: CharacterData) -> Array[PowerData]:
	var chosen: Array[PowerData] = []
	for slot in SET_SIZE:
		chosen.append(character.powers[slot] if slot < character.powers.size() else null)
	return chosen


func cycle(current: Array[PowerData], slot: int, step: int, character: CharacterData) -> void:
	var allowed: Array[PowerData] = allowed_for(character)
	if allowed.is_empty():
		return
	var index: int = allowed.find(current[slot])
	var next: PowerData = allowed[posmod(index + step, allowed.size())] if index >= 0 else allowed[0 if step > 0 else allowed.size() - 1]
	var other: int = current.find(next)
	if other >= 0 and other != slot:
		current[other] = current[slot]
	current[slot] = next
