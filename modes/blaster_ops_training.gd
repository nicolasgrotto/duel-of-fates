class_name BlasterOpsTraining
extends RefCounted

const CONFIG: BlasterOpsConfig = preload("res://data/balance/blaster_ops_config.tres")
const ARENA: BlasterOpsArenaData = preload("res://data/blaster_ops/training_arena.tres")
const PISTOL: BlasterOpsLoadout = preload("res://data/blaster_ops/loadouts/pistol.tres")
const RIFLE: BlasterOpsLoadout = preload("res://data/blaster_ops/loadouts/rifle.tres")
const CHARACTERS: Array[StringName] = [&"corsair", &"lynx", &"holster", &"guardian"]
const POWERS: Array[BlasterOpsPowerData] = [preload("res://data/blaster_ops/powers/repulse.tres"), preload("res://data/blaster_ops/powers/pull.tres"), preload("res://data/blaster_ops/powers/barrier.tres")]
const ADAPTED_POWERS: Array[BlasterOpsPowerData] = [
	preload("res://data/blaster_ops/powers/repulse.tres"), preload("res://data/blaster_ops/powers/pull.tres"), preload("res://data/blaster_ops/powers/barrier.tres"),
	preload("res://data/blaster_ops/powers/throw.tres"), preload("res://data/blaster_ops/powers/heal.tres"), preload("res://data/blaster_ops/powers/absorption.tres"),
	preload("res://data/blaster_ops/powers/lightning.tres"), preload("res://data/blaster_ops/powers/choke.tres"), preload("res://data/blaster_ops/powers/freeze.tres"),
	preload("res://data/blaster_ops/powers/wrath.tres"), preload("res://data/blaster_ops/powers/storm.tres"),
]
const MAX_POWER_SLOTS: int = 3
const ARSENAL: BlasterOpsArsenal = preload("res://data/blaster_ops/arsenal.tres")


static func equipment(character: CharacterData, power_index: int) -> BlasterOpsLoadout:
	var original: BlasterOpsLoadout = PISTOL
	if character.weapon.sidearm == WeaponData.Sidearm.HOLSTER and character.weapon.blaster != null:
		original = RIFLE if character.weapon.blaster.two_handed() else PISTOL
	var result: BlasterOpsLoadout = original.duplicate() as BlasterOpsLoadout
	if character.weapon.sidearm == WeaponData.Sidearm.NONE:
		result.blaster = null
	elif character.weapon.sidearm == WeaponData.Sidearm.HOLSTER:
		result.blaster = character.weapon.blaster
	result.power = POWERS[clampi(power_index, 0, POWERS.size() - 1)]
	result.integrated = character.weapon.sidearm == WeaponData.Sidearm.HILT_EMITTER
	return result


static func adapted(power: PowerData) -> BlasterOpsPowerData:
	for entry in ADAPTED_POWERS:
		if entry.power.id == power.id:
			return entry
	return null


static func weapon_name_key(character: CharacterData, weapon_id: StringName) -> String:
	var entry: BlasterOpsWeaponData = ARSENAL.weapon(weapon_id)
	if entry != null:
		return entry.blaster.name_key
	match character.weapon.sidearm:
		WeaponData.Sidearm.BLASTER:
			return "OPS_WEAPON_OWN_BLASTER"
		WeaponData.Sidearm.HILT_EMITTER:
			return "OPS_WEAPON_OWN_EMITTER"
	return "OPS_WEAPON_BLADE"


static func mission_loadout(character: CharacterData, weapon_id: StringName = &"") -> BlasterOpsLoadout:
	var result: BlasterOpsLoadout = equipment(character, 0)
	var weapon: BlasterOpsWeaponData = ARSENAL.weapon(weapon_id)
	if weapon != null:
		ARSENAL.apply(result, weapon, character)
	var chosen: Array[BlasterOpsPowerData] = []
	for power in character.powers:
		var entry: BlasterOpsPowerData = adapted(power) if power != null else null
		if entry != null and chosen.size() < MAX_POWER_SLOTS:
			chosen.append(entry)
	if chosen.is_empty():
		return result
	result.power = chosen[0]
	result.extra_powers = chosen.slice(1)
	return result


static func look(character: CharacterData, costume: int = 0, blade: int = 0) -> InfiltrationLook:
	var visual: CharacterData = character.duplicate() as CharacterData
	for id in CharacterRoster.IDS:
		if CharacterRoster.character(id).art == character.art:
			visual.id = id
			break
	return InfiltrationLook.create(visual, costume, blade)
