class_name Unlocks

const ARCADE_COLOR: int = 1
const CHALLENGE_COLOR: int = 2
const SECRETS_KEY: String = "secrets:all"
const WARDROBE_KEY: String = "wardrobe:all"
const ARCADE_REQUIREMENTS: Array[String] = ["REQUIREMENT_TRAVELER", "REQUIREMENT_ARCADE"]
const STORY_REQUIREMENTS: Dictionary = {
	"REQUIREMENT_SENTINEL": "ending:any", "REQUIREMENT_STORY": "ending:any", "REQUIREMENT_SECRET_ENDING": "ending:secret",
}


static func color_key(data: CharacterData, index: int) -> String:
	return "color:%s:%d" % [data.id, index]


static func costume_key(data: CharacterData, costume: CostumeData) -> String:
	return "costume:%s:%s" % [data.id, costume.id]


static func is_color_unlocked(data: CharacterData, index: int) -> bool:
	return index == 0 or SaveService.is_unlocked(WARDROBE_KEY) or SaveService.is_unlocked(color_key(data, index))


static func is_costume_unlocked(data: CharacterData, costume: CostumeData) -> bool:
	if costume.requirement_key == "" or SaveService.is_unlocked(WARDROBE_KEY) or SaveService.is_unlocked(costume_key(data, costume)):
		return true
	return STORY_REQUIREMENTS.has(costume.requirement_key) and SaveService.is_unlocked(STORY_REQUIREMENTS[costume.requirement_key])


static func is_character_unlocked(data: CharacterData) -> bool:
	return not data.secret or SaveService.is_unlocked(SECRETS_KEY) or SaveService.is_unlocked("character:%s" % data.id)


static func is_variant_unlocked(data: CharacterData) -> bool:
	return data.variant != null and (SaveService.is_unlocked(SECRETS_KEY) or SaveService.is_unlocked("character:%s" % data.variant.id))


static func color_requirement(data: CharacterData, index: int) -> String:
	if index == ARCADE_COLOR:
		return "REQUIREMENT_ARCADE"
	if index == CHALLENGE_COLOR:
		return data.challenge_key
	return ""


static func challenge_met(data: CharacterData, stats: Dictionary) -> bool:
	return data.challenge_stat != &"" and data.challenge_target > 0 and stats.get(data.challenge_stat, 0) >= data.challenge_target


static func after_duel_against_ai(data: CharacterData, stats: Dictionary) -> PackedStringArray:
	var messages: PackedStringArray = []
	if challenge_met(data, stats) and data.blade_colors.size() > CHALLENGE_COLOR:
		if SaveService.unlock(color_key(data, CHALLENGE_COLOR)):
			messages.append(_color_message(data, CHALLENGE_COLOR))
	return messages


static func after_arcade(data: CharacterData) -> PackedStringArray:
	var messages: PackedStringArray = []
	if data.blade_colors.size() > ARCADE_COLOR and SaveService.unlock(color_key(data, ARCADE_COLOR)):
		messages.append(_color_message(data, ARCADE_COLOR))
	for costume in data.costumes:
		if costume.requirement_key in ARCADE_REQUIREMENTS and SaveService.unlock(costume_key(data, costume)):
			messages.append(TranslationServer.translate("UNLOCK_COSTUME").format({
				"name": TranslationServer.translate(data.name_key), "costume": TranslationServer.translate(costume.name_key),
			}))
	return messages


static func _color_message(data: CharacterData, index: int) -> String:
	var name_key: String = data.blade_color_keys[index] if index < data.blade_color_keys.size() else ""
	return TranslationServer.translate("UNLOCK_COLOR").format({
		"name": TranslationServer.translate(data.name_key), "color": TranslationServer.translate(name_key),
	})
