class_name StoryCampaign
extends RefCounted

const CAMPAIGN: CampaignData = preload("res://data/story/campaign.tres")
const POWER_PATH: String = "res://data/powers/%s.tres"
const CHARACTER_PATH: String = "res://data/characters/%s/%s.tres"
const ATTRIBUTES: Array[StringName] = [&"health", &"vigor", &"blade", &"defense", &"agility", &"flow"]
const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const SLOTS: int = 3
const TreeNodeData = preload("res://data/story/story_tree_node.gd")
const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")

var name: String = ""
var path: int = 0
var style: int = 0
var blaster_id: StringName = &"holster_pistol"
var look: int = 0
var hair: int = CAMPAIGN.default_hair
var beard: int = 0
var hair_color: int = 0
var skin: int = CAMPAIGN.default_skin
var color: int = 0
var difficulty: int = 1
var attributes: Dictionary = {}
var free_points: int = 0
var skill_points: int = 0
var blade_bought: Array[StringName] = []
var projected_cut_slot: int = -1
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
	campaign.blade_bought = [CAMPAIGN.blade_tree[0].node_id()]
	campaign.equipped = [first, &"", &""]
	return campaign


func power_list() -> Array[StringName]:
	var ids: Array[StringName] = []
	for node in power_tree():
		ids.append(node.power.id)
	return ids


func power_tree() -> Array[TreeNodeData]:
	return CAMPAIGN.aurora_tree if path == 0 else CAMPAIGN.eclipse_tree


func can_buy(node: TreeNodeData) -> bool:
	var is_blade: bool = CAMPAIGN.blade_tree.has(node)
	var nodes: Array[TreeNodeData] = CAMPAIGN.blade_tree if is_blade else power_tree()
	var owned: Array[StringName] = blade_bought if is_blade else learned
	if not nodes.has(node) or owned.has(node.node_id()) or skill_points < node.cost:
		return false
	return node.parent < 0 or owned.has(nodes[node.parent].node_id())


func buy(node: TreeNodeData) -> bool:
	if not can_buy(node):
		return false
	skill_points -= node.cost
	if CAMPAIGN.blade_tree.has(node):
		blade_bought.append(node.node_id())
	else:
		learned.append(node.node_id())
	_fill_slots()
	return true


func blade_kind_owned(kind: TreeNodeData.Kind) -> bool:
	for node in CAMPAIGN.blade_tree:
		if node.kind == kind:
			return blade_bought.has(node.node_id())
	return false


func equip_blade(node: TreeNodeData, slot: int) -> bool:
	if not CAMPAIGN.blade_tree.has(node) or not blade_bought.has(node.node_id()):
		return false
	if node.kind == TreeNodeData.Kind.TECHNIQUE:
		if slot < 0 or slot >= 3:
			return false
		var style_node: TreeNodeData = CAMPAIGN.blade_tree[slot]
		if not blade_bought.has(style_node.node_id()):
			return false
		projected_cut_slot = slot
		return true
	if slot != node.style_slot() or slot < 0:
		return false
	if projected_cut_slot == slot:
		projected_cut_slot = -1
	return true


func award_points(encounter: EncounterData, won: bool) -> int:
	if not route().has(encounter) and encounter != secret_encounter():
		return 0
	var points: int = CAMPAIGN.skill_points_loss
	if won:
		points = CAMPAIGN.skill_points_secret if encounter == secret_encounter() else CAMPAIGN.skill_points_win
		if encounter.milestone:
			points += CAMPAIGN.skill_points_milestone
	skill_points += points
	return points


func power_allowed(id: StringName) -> bool:
	var power: PowerData = CATALOG.find(id)
	if power == null:
		return false
	var hero: CharacterData = CharacterData.new()
	hero.flow = attributes.get(&"flow", CAMPAIGN.start_attribute)
	hero.path = CharacterData.Path.AURORA if path == 0 else CharacterData.Path.ECLIPSE
	return PowerCatalog.is_allowed(power, hero)


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
			if not equipped.has(power) and power_allowed(power):
				equipped[slot] = power
				break


func cycle_power(slot: int, step: int) -> void:
	if slot >= slots_open or learned.size() <= 1:
		return
	var index: int = learned.find(equipped[slot])
	for attempt in learned.size():
		index = posmod(index + step, learned.size())
		var candidate: StringName = learned[index]
		if not equipped.has(candidate) and power_allowed(candidate):
			equipped[slot] = candidate
			return


func equip_power(id: StringName, slot: int) -> bool:
	if slot < 0 or slot >= slots_open or id == &"" or not learned.has(id):
		return false
	var other: int = equipped.find(id)
	if other >= 0 and other != slot:
		return false
	if not power_allowed(id):
		return false
	equipped[slot] = id
	return true


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
	var base: CharacterData = load(CHARACTER_PATH % [id, id]) as CharacterData
	if base.technique_forward != null and base.technique_air != null:
		return base
	var resolved: CharacterData = base.duplicate() as CharacterData
	if resolved.technique_forward == null:
		resolved.technique_forward = CAMPAIGN.style_forward_fallback
	if resolved.technique_air == null:
		resolved.technique_air = CAMPAIGN.style_air_fallback
	return resolved


func uses_blaster_style() -> bool:
	return CAMPAIGN.styles[style] == &"holster"


func blaster_data() -> BlasterData:
	for blaster in CAMPAIGN.blasters:
		if blaster.id == blaster_id:
			return blaster
	return CAMPAIGN.blasters[0]


func blade_color() -> Color:
	var id: StringName = CAMPAIGN.blade_sources[color]
	return (load(CHARACTER_PATH % [id, id]) as CharacterData).blade_colors[0]


func protagonist() -> CharacterData:
	var base: CharacterData = style_character()
	var data: CharacterData = base.duplicate()
	if uses_blaster_style():
		data.weapon = base.weapon.duplicate() as WeaponData
		data.weapon.blaster = blaster_data()
	data.directional_ability_fallback = false
	if not blade_kind_owned(TreeNodeData.Kind.STYLE_FORWARD):
		data.technique_forward = null
	if not blade_kind_owned(TreeNodeData.Kind.STYLE_BACK):
		data.technique_back = null
	if not blade_kind_owned(TreeNodeData.Kind.STYLE_AIR):
		data.technique_air = null
	if not blade_kind_owned(TreeNodeData.Kind.STYLE_ABILITY):
		data.ability = null
	if projected_cut_slot >= 0:
		for node in CAMPAIGN.blade_tree:
			if node.kind == TreeNodeData.Kind.TECHNIQUE and blade_bought.has(node.node_id()):
				data.set([&"technique_forward", &"technique_back", &"technique_air"][projected_cut_slot], node.technique)
	data.id = &"protagonist"
	data.name_key = name
	data.path = CharacterData.Path.AURORA if path == 0 else CharacterData.Path.ECLIPSE
	for attribute in ATTRIBUTES:
		data.set(attribute, attributes[attribute])
	data.blade_colors = PackedColorArray([blade_color()])
	var costumes: Array[CostumeData] = [appearance()]
	data.costumes = costumes
	data.eclipse_eyes = path == 1
	data.powers = equipped_powers()
	data.fourth_power = null
	data.secret = false
	data.variant = null
	return data


func appearance() -> CostumeData:
	var outfit: CostumeData = CAMPAIGN.outfits[clampi(look, 0, CAMPAIGN.outfits.size() - 1)].duplicate() as CostumeData
	var colors: PackedColorArray = outfit.colors.duplicate()
	colors[CostumeData.Slot.HAIR] = CAMPAIGN.hair_colors[clampi(hair_color, 0, CAMPAIGN.hair_colors.size() - 1)]
	colors[CostumeData.Slot.SKIN] = CAMPAIGN.skin_tones[clampi(skin, 0, CAMPAIGN.skin_tones.size() - 1)]
	outfit.colors = colors
	var hidden: PackedStringArray = outfit.hide_parts.duplicate()
	hidden.append_array(PackedStringArray(["hair", "beard"]))
	outfit.hide_parts = hidden
	var shown: PackedStringArray = outfit.show_parts.duplicate()
	for style in [CAMPAIGN.hair_styles[clampi(hair, 0, CAMPAIGN.hair_styles.size() - 1)], CAMPAIGN.beard_styles[clampi(beard, 0, CAMPAIGN.beard_styles.size() - 1)]]:
		if style != "":
			shown.append(style)
	outfit.show_parts = shown
	return outfit


func set_appearance(choices: Dictionary) -> void:
	look = choices.get(&"look", look)
	hair = choices.get(&"hair", hair)
	beard = choices.get(&"beard", beard)
	hair_color = choices.get(&"hair_color", hair_color)
	skin = choices.get(&"skin", skin)


func equipped_powers() -> Array[PowerData]:
	var powers: Array[PowerData] = []
	for slot in SLOTS:
		powers.append(load_power(equipped[slot]) if slot < slots_open and equipped[slot] != &"" else null)
	return powers


func difficulty_id(offset: int) -> StringName:
	return DIFFICULTIES[clampi(difficulty + offset, 0, DIFFICULTIES.size() - 1)]


static func load_power(id: StringName) -> PowerData:
	return load(POWER_PATH % id) as PowerData if ResourceLoader.exists(POWER_PATH % id) else null


func to_dict() -> Dictionary:
	return {
		"name": name, "path": path, "style": style, "look": look, "color": color, "difficulty": difficulty,
		"hair": hair, "beard": beard, "hair_color": hair_color, "skin": skin, "blaster_id": blaster_data().id,
		"blade_bought": blade_bought.duplicate(), "projected_cut_slot": projected_cut_slot,
		"attributes": attributes.duplicate(), "free_points": free_points, "skill_points": skill_points, "cleared": cleared.duplicate(), "learned": learned.duplicate(),
		"equipped": equipped.duplicate(), "slots_open": slots_open, "secret_pending": secret_pending, "ending": ending,
	}


static func from_dict(data: Dictionary) -> StoryCampaign:
	var campaign: StoryCampaign = StoryCampaign.new()
	campaign.name = data.get("name", "")
	campaign.path = data.get("path", 0)
	campaign.style = clampi(data.get("style", 0), 0, CAMPAIGN.styles.size() - 1)
	campaign.blaster_id = StringName(data.get("blaster_id", "holster_pistol"))
	campaign.blaster_id = campaign.blaster_data().id
	campaign.look = data.get("look", 0)
	campaign.hair = data.get("hair", CAMPAIGN.default_hair)
	campaign.beard = data.get("beard", 0)
	campaign.hair_color = data.get("hair_color", 0)
	campaign.skin = data.get("skin", CAMPAIGN.default_skin)
	campaign.color = data.get("color", 0)
	campaign.difficulty = data.get("difficulty", 1)
	campaign.attributes = data.get("attributes", {})
	for attribute in ATTRIBUTES:
		if not campaign.attributes.has(attribute):
			campaign.attributes[attribute] = CAMPAIGN.start_attribute
	campaign.free_points = data.get("free_points", 0)
	campaign.skill_points = maxi(data.get("skill_points", 0), 0)
	campaign.cleared.assign(data.get("cleared", []))
	for value in data.get("learned", []):
		var id: StringName = StringName(value)
		if CATALOG.find(id) != null and not campaign.learned.has(id):
			campaign.learned.append(id)
	var first: StringName = campaign.power_list()[0]
	if not campaign.learned.has(first):
		campaign.learned.append(first)
	campaign.slots_open = clampi(data.get("slots_open", 1), 1, SLOTS)
	var saved_slots: Array = data.get("equipped", [])
	for slot in mini(saved_slots.size(), campaign.slots_open):
		var id: StringName = StringName(saved_slots[slot])
		if campaign.learned.has(id) and campaign.power_allowed(id) and not campaign.equipped.has(id):
			campaign.equipped[slot] = id
	campaign.secret_pending = data.get("secret_pending", false)
	campaign.ending = data.get("ending", &"")
	var legacy: bool = not data.has("blade_bought")
	for node in CAMPAIGN.blade_tree:
		if (legacy and node.kind != TreeNodeData.Kind.TECHNIQUE) or data.get("blade_bought", []).has(String(node.node_id())) or data.get("blade_bought", []).has(node.node_id()):
			campaign.blade_bought.append(node.node_id())
	if not campaign.blade_bought.has(CAMPAIGN.blade_tree[0].node_id()):
		campaign.blade_bought.append(CAMPAIGN.blade_tree[0].node_id())
	var chosen: int = data.get("projected_cut_slot", -1)
	if chosen >= 0 and chosen < 3:
		campaign.equip_blade(CAMPAIGN.blade_tree.back(), chosen)
	campaign._fill_slots()
	return campaign
