extends Node

const MAX_TICKS: int = 72000


func _ready() -> void:
	var armed: bool = "--armed" in OS.get_cmdline_user_args()
	for mission in BlasterOpsMode.INCURSIONS:
		_run(mission, armed)
	get_tree().quit()


func _run(mission: BlasterOpsMissionData, armed: bool) -> void:
	var hero: CharacterData = CharacterRoster.character(&"corsair" if armed else &"guardian")
	var sim: BlasterOpsSimulation = BlasterOpsMode.new(mission, hero, null, true).create_simulation()
	var pilot: BlasterOpsMissionPilot = BlasterOpsMissionPilot.new(sim)
	var enemies: BlasterOpsMissionController = BlasterOpsMissionController.new(sim.map, sim.targets.size())
	var allies: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var peak: int = 0
	var marks: PackedStringArray = []
	var last: int = -2
	for tick in MAX_TICKS:
		sim.step(pilot.produce(sim), enemies.produce_all(sim), allies.produce_all(sim))
		peak = maxi(peak, progress.enemies_left(sim))
		if progress.stage_index != last:
			last = progress.stage_index
			marks.append("%d@%ds/hp%d" % [last, sim.tick / 60, roundi(sim.player.health)])
		if progress.outcome != InfiltrationMissionState.Outcome.ACTIVE:
			break
	if progress.outcome != InfiltrationMissionState.Outcome.COMPLETED:
		var alive: PackedStringArray = []
		for index in sim.targets.size():
			if sim.targets[index].spawned and sim.targets[index].health > 0.0:
				alive.append("%s@%s/%d" % [sim.target_data[index].id, str(Vector2i(sim.targets[index].position / sim.map.tile_size)), roundi(sim.targets[index].health)])
		print("   player %s  alive %s" % [str(Vector2i(sim.player.position / sim.map.tile_size)), " ".join(alive)])
	print("%-18s outcome %d  %4d s  hp %3d  peak %2d  kills %2d  stages %s" % [mission.id, progress.outcome, sim.tick / 60, roundi(sim.player.health), peak, progress.takedowns, " ".join(marks)])
