class_name BlasterOpsFixture
extends RefCounted

var sim: BlasterOpsSimulation
var intent: InfiltrationIntent = InfiltrationIntent.new()
var events: Array[Dictionary] = []
var _empty_intents: Array[InfiltrationIntent] = []


static func arena(enemies: Array[BlasterOpsEnemyData] = [], cover: bool = false) -> BlasterOpsArenaData:
	var data: BlasterOpsArenaData = BlasterOpsArenaData.new()
	var rows: PackedStringArray = []
	for y in 14:
		rows.append("#".repeat(24) if y == 0 or y == 13 else "#" + ".".repeat(22) + "#")
	if cover:
		rows[6] = rows[6].substr(0, 6) + "C" + rows[6].substr(7)
		var box: BlasterOpsCoverData = BlasterOpsCoverData.new()
		box.cell = Vector2i(6, 6)
		data.covers.append(box)
	data.rows = rows
	data.player_spawn = Vector2(160, 416)
	for index in enemies.size():
		var placement: InfiltrationEnemyPlacement = InfiltrationEnemyPlacement.new()
		placement.enemy = enemies[index]
		placement.position = Vector2(736, 416 + index * 100)
		placement.direction = Vector2.LEFT
		data.enemies.append(placement)
	return data


static func create(map: BlasterOpsArenaData = null, loadout: BlasterOpsLoadout = null, config: BlasterOpsConfig = null) -> BlasterOpsFixture:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.new()
	fixture.sim = BlasterOpsSimulation.new(config if config != null else BlasterOpsTraining.CONFIG, map if map != null else arena(), loadout if loadout != null else BlasterOpsTraining.PISTOL)
	fixture.intent.aim = Vector2.RIGHT
	return fixture


static func enemy(id: String) -> BlasterOpsEnemyData:
	return load("res://data/blaster_ops/enemies/%s.tres" % id) as BlasterOpsEnemyData


func step(count: int = 1, controller: BlasterOpsEnemyController = null) -> void:
	for index in count:
		sim.step(intent, controller.produce_all(sim) if controller != null else _empty_intents)
		for event_index in sim.event_count:
			var event: InfiltrationEvent = sim.events[event_index]
			events.append({"type": event.type, "tick": sim.tick, "source": event.source, "target": event.target, "amount": event.amount})
		intent.pressed = 0


func count_events(type: InfiltrationEvent.Type) -> int:
	var count: int = 0
	for event in events:
		if event.type == type:
			count += 1
	return count


func incoming(velocity: Vector2 = Vector2.LEFT * 900.0, damage: float = 7.0) -> BlasterOpsBolt:
	var bolt: BlasterOpsBolt = BlasterOpsBolt.new()
	bolt.active = true
	bolt.owner = 1
	bolt.shooter = 0
	bolt.position = sim.player.position + Vector2(18, 0)
	bolt.previous = bolt.position
	bolt.data = load("res://data/infiltration/bolts/trooper_bolt.tres") as BoltData
	bolt.velocity = velocity
	bolt.damage = damage
	return bolt
