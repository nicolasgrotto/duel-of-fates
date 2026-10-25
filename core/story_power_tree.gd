class_name StoryPowerTree
extends RefCounted

enum State { LOCKED, AFFORDABLE, EXPENSIVE, TIER_BLOCKED, LEARNED, EQUIPPED }

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
var campaign: StoryCampaign
var nodes: Array[PowerNode] = []
var milestones: Array[EncounterData] = []


func _init(story: StoryCampaign, blade_tab: bool = false) -> void:
	campaign = story
	blade = blade_tab
	rebuild()


func rebuild() -> void:
	nodes.clear()
	milestones.clear()
	for encounter in campaign.route():
		if encounter.milestone:
			milestones.append(encounter)
	var definitions: Array[TreeNodeData] = StoryCampaign.CAMPAIGN.blade_tree if blade else campaign.power_tree()
	var owned: Array[StringName] = campaign.blade_bought if blade else campaign.learned
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
			if node.slot == campaign.projected_cut_slot or not node.owned:
				node.slot = -1
			if definition.kind == TreeNodeData.Kind.TECHNIQUE:
				node.slot = campaign.projected_cut_slot if node.owned else -1
		else:
			node.name_key = node.power.name_key
			node.description_key = node.power.description_key
			node.icon = node.power.icon
			node.allowed = campaign.power_allowed(node.power.id)
			node.slot = campaign.equipped.find(node.power.id)
			if node.slot >= campaign.slots_open or not node.allowed:
				node.slot = -1
		if node.owned:
			node.state = State.TIER_BLOCKED if not node.allowed else (State.EQUIPPED if node.slot >= 0 or node.ability != null else State.LEARNED)
		elif definition.parent < 0 or owned.has(definitions[definition.parent].node_id()):
			node.state = State.AFFORDABLE if campaign.skill_points >= definition.cost else State.EXPENSIVE
		nodes.append(node)


func buy(index: int) -> bool:
	if index < 0 or index >= nodes.size() or not campaign.buy(nodes[index].definition):
		return false
	rebuild()
	return true


func equip(index: int, slot: int) -> bool:
	if index < 0 or index >= nodes.size():
		return false
	var changed: bool = campaign.equip_blade(nodes[index].definition, slot) if blade else campaign.equip_power(nodes[index].power.id, slot)
	if not changed:
		return false
	rebuild()
	return true
