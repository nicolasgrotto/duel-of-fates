class_name StoryPowerTree
extends RefCounted

enum State { LOCKED, AFFORDABLE, EXPENSIVE, TIER_BLOCKED, LEARNED, EQUIPPED }

const TreeNodeData = preload("res://data/story/story_tree_node.gd")

class PowerNode extends RefCounted:
	var definition: TreeNodeData
	var power: PowerData
	var initial: bool = false
	var slot: int = -1
	var allowed: bool = false
	var owned: bool = false
	var state: State = State.LOCKED

var campaign: StoryCampaign
var nodes: Array[PowerNode] = []
var milestones: Array[EncounterData] = []


func _init(story: StoryCampaign) -> void:
	campaign = story
	rebuild()


func rebuild() -> void:
	nodes.clear()
	milestones.clear()
	for encounter in campaign.route():
		if encounter.milestone:
			milestones.append(encounter)
	var definitions: Array[TreeNodeData] = campaign.power_tree()
	for definition in definitions:
		var node: PowerNode = PowerNode.new()
		node.definition = definition
		node.power = definition.power
		node.initial = nodes.is_empty()
		node.allowed = campaign.power_allowed(node.power.id)
		node.owned = campaign.learned.has(node.power.id)
		node.slot = campaign.equipped.find(node.power.id)
		if node.slot >= campaign.slots_open or not node.allowed:
			node.slot = -1
		if node.owned:
			node.state = State.TIER_BLOCKED if not node.allowed else (State.EQUIPPED if node.slot >= 0 else State.LEARNED)
		elif definition.parent < 0 or campaign.learned.has(definitions[definition.parent].power.id):
			node.state = State.AFFORDABLE if campaign.skill_points >= definition.cost else State.EXPENSIVE
		nodes.append(node)


func buy(index: int) -> bool:
	if index < 0 or index >= nodes.size() or not campaign.buy(nodes[index].definition):
		return false
	rebuild()
	return true


func equip(index: int, slot: int) -> bool:
	if index < 0 or index >= nodes.size() or not campaign.equip_power(nodes[index].power.id, slot):
		return false
	rebuild()
	return true
