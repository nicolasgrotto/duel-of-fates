class_name StoryPowerTree
extends RefCounted

enum State { LOCKED, NEXT, LEARNED, EQUIPPED }

class PowerNode extends RefCounted:
	var power: PowerData
	var encounter: EncounterData
	var initial: bool = false
	var slot: int = -1
	var tier: int = 0
	var allowed: bool = false
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
	var encounters: Array[EncounterData] = campaign.route()
	encounters.append(campaign.secret_encounter())
	for encounter in encounters:
		if encounter.milestone:
			milestones.append(encounter)
	var hero: CharacterData = CharacterData.new()
	hero.flow = campaign.attributes.get(&"flow", StoryCampaign.CAMPAIGN.start_attribute)
	hero.path = CharacterData.Path.AURORA if campaign.path == 0 else CharacterData.Path.ECLIPSE
	var next: EncounterData = campaign.next_encounter()
	for id in campaign.power_list():
		var node: PowerNode = PowerNode.new()
		node.power = StoryCampaign.load_power(id)
		node.initial = nodes.is_empty()
		for encounter in encounters:
			if (encounter.power_aurora if campaign.path == 0 else encounter.power_eclipse) == id:
				node.encounter = encounter
		if node.encounter != null:
			for milestone in milestones:
				if milestone.chapter <= node.encounter.chapter:
					node.tier += 1
		node.allowed = PowerCatalog.is_allowed(node.power, hero)
		node.slot = campaign.equipped.find(id)
		if node.slot >= campaign.slots_open:
			node.slot = -1
		if campaign.learned.has(id):
			node.state = State.EQUIPPED if node.slot >= 0 else State.LEARNED
		elif node.encounter != null and node.encounter == next:
			node.state = State.NEXT
		nodes.append(node)


func equip(index: int, slot: int) -> bool:
	if index < 0 or index >= nodes.size():
		return false
	var node: PowerNode = nodes[index]
	if not node.allowed:
		return false
	if not campaign.equip_power(node.power.id, slot):
		return false
	rebuild()
	return true
