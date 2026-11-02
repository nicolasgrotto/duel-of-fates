class_name InfiltrationLook
extends RefCounted

const SPRITE_PATH: String = "res://assets/infiltration/heroes/%s.png"

var character_id: StringName
var texture: Texture2D
var blade_color: Color
var hilt_color: Color
var skin_color: Color
var kind: WeaponData.Kind = WeaponData.Kind.SINGLE
var second_blade_ratio: float = 0.0


static func create(data: CharacterData, costume_index: int, blade_index: int) -> InfiltrationLook:
	var look: InfiltrationLook = InfiltrationLook.new()
	var colors: PackedColorArray = data.costumes[clampi(costume_index, 0, data.costumes.size() - 1)].colors
	look.character_id = data.id
	look.texture = bake(load(SPRITE_PATH % data.id), colors)
	look.blade_color = data.blade_colors[clampi(blade_index, 0, data.blade_colors.size() - 1)]
	look.hilt_color = colors[CostumeData.Slot.METAL]
	look.skin_color = colors[CostumeData.Slot.SKIN]
	look.kind = data.weapon.kind
	look.second_blade_ratio = data.weapon.second_blade_length / data.weapon.blade_length
	return look


static func bake(source: Texture2D, colors: PackedColorArray) -> ImageTexture:
	return PaletteBake.texture(source, colors)
