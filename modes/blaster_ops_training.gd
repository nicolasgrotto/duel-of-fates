class_name BlasterOpsTraining
extends RefCounted

const CONFIG: BlasterOpsConfig = preload("res://data/balance/blaster_ops_config.tres")
const ARENA: BlasterOpsArenaData = preload("res://data/blaster_ops/training_arena.tres")
const PISTOL: BlasterOpsLoadout = preload("res://data/blaster_ops/loadouts/pistol.tres")
const RIFLE: BlasterOpsLoadout = preload("res://data/blaster_ops/loadouts/rifle.tres")
const TEMPORARY: BlasterOpsLoadout = preload("res://data/blaster_ops/loadouts/temporary.tres")
const CHARACTERS: Array[StringName] = [&"corsair", &"lynx", &"holster", &"guardian"]
const POWERS: Array[BlasterOpsPowerData] = [preload("res://data/blaster_ops/powers/repulse.tres"), preload("res://data/blaster_ops/powers/pull.tres"), preload("res://data/blaster_ops/powers/barrier.tres")]


static func equipment(character: CharacterData, power_index: int) -> BlasterOpsLoadout:
	var original: BlasterOpsLoadout = TEMPORARY if character.weapon.sidearm == WeaponData.Sidearm.NONE else PISTOL
	if character.weapon.sidearm == WeaponData.Sidearm.HOLSTER and character.weapon.blaster != null:
		original = RIFLE if character.weapon.blaster.two_handed() else PISTOL
	var result: BlasterOpsLoadout = original.duplicate() as BlasterOpsLoadout
	if character.weapon.sidearm == WeaponData.Sidearm.HOLSTER:
		result.blaster = character.weapon.blaster
	result.power = POWERS[clampi(power_index, 0, POWERS.size() - 1)]
	return result


static func look(character: CharacterData, costume: int = 0, blade: int = 0) -> InfiltrationLook:
	var visual: CharacterData = character.duplicate() as CharacterData
	for id in CharacterRoster.IDS:
		if CharacterRoster.character(id).art == character.art:
			visual.id = id
			break
	return InfiltrationLook.create(visual, costume, blade)
