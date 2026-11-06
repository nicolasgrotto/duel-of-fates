class_name BlasterOpsArsenal
extends Resource

@export var weapons: Array[BlasterOpsWeaponData] = []
@export var tiers: Array[BlasterOpsTrainingTier] = []
@export var training: Dictionary = {}
@export var default_tier: int = 1


func weapon(id: StringName) -> BlasterOpsWeaponData:
	for entry in weapons:
		if entry.blaster.id == id:
			return entry
	return null


func tier_for(character: StringName, entry: BlasterOpsWeaponData) -> BlasterOpsTrainingTier:
	var row: Array = training.get(character, [])
	return tiers[row[entry.training_class] if entry.training_class < row.size() else default_tier]


func apply(loadout: BlasterOpsLoadout, entry: BlasterOpsWeaponData, character: CharacterData) -> void:
	var tier: BlasterOpsTrainingTier = tier_for(character.id, entry)
	loadout.blaster = entry.blaster
	loadout.damage_scale = entry.damage_scale
	loadout.fire_interval = entry.fire_interval * tier.interval_scale
	loadout.heat_per_shot = entry.heat_per_shot * tier.heat_scale
	loadout.spread_degrees = tier.spread_degrees
	loadout.switch_scale = tier.switch_scale
	loadout.two_handed = entry.two_handed
	loadout.switchable = entry.two_handed or character.weapon.kind != WeaponData.Kind.SINGLE
	loadout.integrated = false
