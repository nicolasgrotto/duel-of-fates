class_name StoryPowerTree
extends RefCounted

enum State { LOCKED, AFFORDABLE, EXPENSIVE, TIER_BLOCKED, LEARNED, EQUIPPED, NEEDS_BLASTER }

const TreeNodeData = preload("res://data/story/story_tree_node.gd")

class PowerNode extends RefCounted:
	var definition: TreeNodeData
	var technique: MoveData
	var ability: AbilityData
	var name_key: String
	var description_key: String
	var icon: Texture2D
	var power: PowerData
	var initial: bool = false
	var slot: int = -1
	var allowed: bool = false
	var owned: bool = false
	var state: State = State.LOCKED

var blade: bool = false
var blaster: bool = false
var campaign: StoryCampaign
var nodes: Array[PowerNode] = []
var milestones: Array[EncounterData] = []


func _init(story: StoryCampaign, blade_tab: bool = false, blaster_tab: bool = false) -> void:
	campaign = story
	blade = blade_tab
	blaster = blaster_tab
	rebuild()


func rebuild() -> void:
	nodes.clear()
	milestones.clear()
	for encounter in campaign.route():
		if encounter.milestone:
			milestones.append(encounter)
	var definitions: Array[TreeNodeData] = _definitions()
	var owned: Array[StringName] = campaign.blade_bought if blade else (campaign.blaster_bought if blaster else campaign.learned)
	var character: CharacterData = campaign.style_character()
	for definition in definitions:
		var node: PowerNode = PowerNode.new()
		node.definition = definition
		node.power = definition.power
		node.initial = nodes.is_empty()
		node.owned = owned.has(definition.node_id())
		if blade:
			node.technique = definition.move_for(character)
			node.ability = definition.ability_for(character)
			node.name_key = PowerCatalog.technique_key(node.technique) if node.technique != null else "TREE_STYLE_ABILITY"
			node.description_key = "TREE_TECHNIQUE_TEXT" if node.technique != null else character.ability_key
			node.icon = node.technique.icon if node.technique != null else node.ability.icon
			node.allowed = true
			node.slot = definition.style_slot()
			if node.slot == campaign.projected_cut_slot or not node.owned or campaign.draw_in_slot(node.slot):
				node.slot = -1
			if definition.kind == TreeNodeData.Kind.TECHNIQUE:
				node.slot = campaign.projected_cut_slot if node.owned else -1
		elif blaster:
			node.technique = definition.technique
			node.ability = definition.ability
			node.name_key = PowerCatalog.technique_key(node.technique) if node.technique != null else definition.ability_key
			node.description_key = "TREE_BLASTER_TEXT" if node.technique != null else "TREE_BLASTER_ABILITY_TEXT"
			node.icon = node.technique.icon if node.technique != null else node.ability.icon
			node.allowed = campaign.blaster_equipped()
			node.slot = definition.draw_slot() if campaign.blaster_skill_on(definition) else -1
		else:
			node.name_key = node.power.name_key
			node.description_key = node.power.description_key
			node.icon = node.power.icon
			node.allowed = campaign.power_allowed(node.power.id)
			node.slot = campaign.equipped.find(node.power.id)
			if node.slot >= campaign.slots_open or not node.allowed:
				node.slot = -1
		if blaster and not node.allowed:
			node.state = State.NEEDS_BLASTER
		elif node.owned:
			node.state = State.TIER_BLOCKED if not node.allowed else (State.EQUIPPED if _in_use(node) else State.LEARNED)
		elif definition.parent < 0 or owned.has(definitions[definition.parent].node_id()):
			node.state = State.AFFORDABLE if campaign.skill_points >= definition.cost else State.EXPENSIVE
		nodes.append(node)


func _definitions() -> Array[TreeNodeData]:
	if blade:
		return StoryCampaign.CAMPAIGN.blade_tree
	return StoryCampaign.CAMPAIGN.blaster_tree if blaster else campaign.power_tree()


func _in_use(node: PowerNode) -> bool:
	if blaster:
		return campaign.blaster_skill_on(node.definition)
	return node.slot >= 0 or (node.ability != null and not campaign.blaster_ability_on())


func buy(index: int) -> bool:
	if index < 0 or index >= nodes.size() or not campaign.buy(nodes[index].definition):
		return false
	rebuild()
	return true


func equip(index: int, slot: int) -> bool:
	if index < 0 or index >= nodes.size():
		return false
	var changed: bool = _equip_node(nodes[index], slot)
	if not changed:
		return false
	rebuild()
	return true


func _equip_node(node: PowerNode, slot: int) -> bool:
	if blaster:
		return campaign.toggle_blaster_skill(node.definition)
	return campaign.equip_blade(node.definition, slot) if blade else campaign.equip_power(node.power.id, slot)
