class_name CostumeData
extends Resource

enum Slot { CLOAK, BODY, TRIM, SKIN, HAIR, METAL, LEATHER, EYES }

@export var id: StringName
@export var name_key: String
@export var requirement_key: String
@export var colors: PackedColorArray = PackedColorArray([
	Color("#6b5a48"), Color("#2e2925"), Color("#8a6a3a"), Color("#9a7660"),
	Color("#4a3222"), Color("#9aa3ad"), Color("#3a2c22"), Color("#ffb22e"),
])
@export var show_parts: PackedStringArray = []
@export var hide_parts: PackedStringArray = []
@export var prosthetic_arm: bool = false


func parts_for(art: FighterArt) -> PackedStringArray:
	var parts: PackedStringArray = art.default_parts.duplicate()
	for part in hide_parts:
		var index: int = parts.find(part)
		if index >= 0:
			parts.remove_at(index)
	for part in show_parts:
		if not parts.has(part):
			parts.append(part)
	return parts


func color(slot: Slot) -> Color:
	return colors[slot]
