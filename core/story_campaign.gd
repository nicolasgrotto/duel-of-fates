class_name StoryCampaign
extends RefCounted

const CAMPAIGN: CampaignData = preload("res://data/story/campaign.tres")
const POWER_PATH: String = "res://data/powers/%s.tres"
const CHARACTER_PATH: String = "res://data/characters/%s/%s.tres"
const ATTRIBUTES: Array[StringName] = [&"health", &"vigor", &"blade", &"defense", &"agility", &"flow"]
const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const SLOTS: int = 3

var name: String = ""
var path: int = 0
var style: int = 0
var look: int = 0
var color: int = 0
var difficulty: int = 1
var attributes: Dictionary = {}
var free_points: int = 0
var cleared: Array[StringName] = []
var learned: Array[StringName] = []
var equipped: Array[StringName] = [&"", &"", &""]
var slots_open: int = 1
var secret_pending: bool = false
var ending: StringName = &""


static func current() -> StoryCampaign:
	if SaveService.campaign.is_empty():
		return null
	return from_dict(SaveService.campaign)


func save() -> void:
	SaveService.campaign = to_dict()
	SaveService.save_progress()


static func create(player_name: String, flow_path: int, style_index: int, look_index: int, color_index: int, difficulty_index: int) -> StoryCampaign:
	var campaign: StoryCampaign = StoryCampaign.new()
	campaign.name = player_name
	campaign.path = flow_path
	campaign.style = style_index
	campaign.look = look_index
	campaign.color = color_index
	campaign.difficulty = difficulty_index
	for attribute in ATTRIBUTES:
		campaign.attributes[attribute] = CAMPAIGN.start_attribute
	campaign.free_points = CAMPAIGN.start_points
	var first: StringName = campaign.power_list()[0]
	campaign.learned = [first]
	campaign.equipped = [first, &"", &""]
	return campaign


func power_list() -> Array[StringName]:
	return CAMPAIGN.aurora_powers if path == 0 else CAMPAIGN.eclipse_powers


func route() -> Array[EncounterData]:
	var list: Array[EncounterData] = []
	list.append_array(CAMPAIGN.common)
	list.append_array(CAMPAIGN.aurora if path == 0 else CAMPAIGN.eclipse)
	return list


func secret_encounter() -> EncounterData:
	return CAMPAIGN.aurora_secret if path == 0 else CAMPAIGN.eclipse_secret


func next_encounter() -> EncounterData:
	if ending != &"":
		return null
	for encounter in route():
		if not cleared.has(encounter.id):
			return encounter
	if secret_pending:
		return secret_encounter()
	return null


func is_finished() -> bool:
	return ending != &""


func ending_data() -> EndingData:
	match ending:
		CAMPAIGN.aurora_normal_ending.id:
			return CAMPAIGN.aurora_normal_ending
		CAMPAIGN.aurora_secret_ending.id:
			return CAMPAIGN.aurora_secret_ending
		CAMPAIGN.eclipse_normal_ending.id:
			return CAMPAIGN.eclipse_normal_ending
		CAMPAIGN.eclipse_secret_ending.id:
			return CAMPAIGN.eclipse_secret_ending
	return null


func points_for(encounter: EncounterData) -> int:
	if not encounter.awards_points:
		return 0
	if encounter.milestone:
		var milestones: PackedInt32Array = CAMPAIGN.milestone_points[difficulty]
		var milestone_index: int = 0
		for item in route():
			if item == encounter:
				break
			if item.milestone:
				milestone_index += 1
		return milestones[mini(milestone_index, milestones.size() - 1)]
	return CAMPAIGN.points_per_win[difficulty]


func complete(encounter: EncounterData, health_ratio: float) -> PackedStringArray:
	var notes: PackedStringArray = []
	if cleared.has(encounter.id):
		return notes
	cleared.append(encounter.id)
	var points: int = points_for(encounter)
	if points > 0:
		free_points += points
		notes.append(TranslationServer.translate("STORY_NOTE_POINTS").format({"points": points}))
	var power: StringName = encounter.power_aurora if path == 0 else encounter.power_eclipse
	if power != &"" and not learned.has(power):
		learned.append(power)
		notes.append(TranslationServer.translate("STORY_NOTE_POWER").format({"power": TranslationServer.translate(load_power(power).name_key)}))
	if encounter.milestone:
		slots_open = mini(slots_open + 1, SLOTS)
		notes.append(TranslationServer.translate("STORY_NOTE_SLOT"))
	_fill_slots()
	for key in encounter.unlocks:
		SaveService.unlock(key)
	if encounter == secret_encounter():
		_finish(CAMPAIGN.aurora_secret_ending if path == 0 else CAMPAIGN.eclipse_secret_ending)
	elif next_encounter() == null:
		secret_pending = health_ratio > CAMPAIGN.secret_health_ratio
		if not secret_pending:
			_finish(CAMPAIGN.aurora_normal_ending if path == 0 else CAMPAIGN.eclipse_normal_ending)
	return notes


func _finish(data: EndingData) -> void:
	ending = data.id
	secret_pending = false
	for key in data.unlocks:
		SaveService.unlock(key)
	SaveService.unlock("seen:ending:%s" % data.id)


func _fill_slots() -> void:
	for slot in slots_open:
		if equipped[slot] != &"":
			continue
		for power in learned:
			if not equipped.has(power):
				equipped[slot] = power
				break


func cycle_power(slot: int, step: int) -> void:
	if slot >= slots_open or learned.size() <= 1:
		return
	var index: int = learned.find(equipped[slot])
	for attempt in learned.size():
		index = posmod(index + step, learned.size())
		var candidate: StringName = learned[index]
		if not equipped.has(candidate):
			equipped[slot] = candidate
			return


func raise(attribute: StringName) -> bool:
	if free_points <= 0 or attributes[attribute] >= CAMPAIGN.max_attribute:
		return false
	attributes[attribute] += 1
	free_points -= 1
	return true


func attribute_total() -> int:
	var total: int = 0
	for attribute in ATTRIBUTES:
		total += attributes[attribute]
	return total


func style_character() -> CharacterData:
	var id: StringName = CAMPAIGN.styles[style]
	return load(CHARACTER_PATH % [id, id]) as CharacterData


func blade_color() -> Color:
	var id: StringName = CAMPAIGN.blade_sources[color]
	return (load(CHARACTER_PATH % [id, id]) as CharacterData).blade_colors[0]


func protagonist() -> CharacterData:
	var base: CharacterData = style_character()
	var data: CharacterData = base.duplicate()
	data.id = &"protagonist"
	data.name_key = name
	data.path = CharacterData.Path.AURORA if path == 0 else CharacterData.Path.ECLIPSE
	for attribute in ATTRIBUTES:
		data.set(attribute, attributes[attribute])
	data.blade_colors = PackedColorArray([blade_color()])
	var costumes: Array[CostumeData] = [base.costumes[look % base.costumes.size()]]
	data.costumes = costumes
	data.powers = equipped_powers()
	data.fourth_power = null
	data.secret = false
	data.variant = null
	return data


func equipped_powers() -> Array[PowerData]:
	var powers: Array[PowerData] = []
	for slot in SLOTS:
		powers.append(load_power(equipped[slot]) if slot < slots_open and equipped[slot] != &"" else null)
	return powers


func difficulty_id(offset: int) -> StringName:
	return DIFFICULTIES[clampi(difficulty + offset, 0, DIFFICULTIES.size() - 1)]


static func load_power(id: StringName) -> PowerData:
	return load(POWER_PATH % id) as PowerData


func to_dict() -> Dictionary:
	return {
		"name": name, "path": path, "style": style, "look": look, "color": color, "difficulty": difficulty,
		"attributes": attributes.duplicate(), "free_points": free_points, "cleared": cleared.duplicate(), "learned": learned.duplicate(),
		"equipped": equipped.duplicate(), "slots_open": slots_open, "secret_pending": secret_pending, "ending": ending,
	}


static func from_dict(data: Dictionary) -> StoryCampaign:
	var campaign: StoryCampaign = StoryCampaign.new()
	campaign.name = data.get("name", "")
	campaign.path = data.get("path", 0)
	campaign.style = data.get("style", 0)
	campaign.look = data.get("look", 0)
	campaign.color = data.get("color", 0)
	campaign.difficulty = data.get("difficulty", 1)
	campaign.attributes = data.get("attributes", {})
	for attribute in ATTRIBUTES:
		if not campaign.attributes.has(attribute):
			campaign.attributes[attribute] = CAMPAIGN.start_attribute
	campaign.free_points = data.get("free_points", 0)
	campaign.cleared.assign(data.get("cleared", []))
	campaign.learned.assign(data.get("learned", []))
	campaign.equipped.assign(data.get("equipped", [&"", &"", &""]))
	campaign.slots_open = data.get("slots_open", 1)
	campaign.secret_pending = data.get("secret_pending", false)
	campaign.ending = data.get("ending", &"")
	return campaign
