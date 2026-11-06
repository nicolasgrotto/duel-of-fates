extends Node

const CONFIG: BlasterOpsConfig = preload("res://data/balance/blaster_ops_config.tres")
const TICKS: int = 900
const WARM_UP_TICKS: int = 120
const ENEMY_COUNTS: PackedInt32Array = [8, 16, 24, 32, 48]
const ALLY_COUNTS: PackedInt32Array = [0, 4, 8]
const MAP_WIDTH: int = 72
const MAP_HEIGHT: int = 40
const ARCHETYPES: PackedStringArray = ["soldier", "rusher", "heavy", "marksman"]


func _ready() -> void:
	_run_all.call_deferred()


func _run_all() -> void:
	print("enemies allies  avg_us  p99_us  max_us  bolts_peak  dropped")
	for allies in ALLY_COUNTS:
		for enemies in ENEMY_COUNTS:
			_run(enemies, allies)
			await get_tree().process_frame
	print("ops_benchmark_done")
	get_tree().quit()


func _mission(enemies: int, allies: int) -> InfiltrationMissionData:
	var arena: BlasterOpsArenaData = BlasterOpsArenaData.new()
	var rows: PackedStringArray = []
	for y in MAP_HEIGHT:
		var row: String = ""
		for x in MAP_WIDTH:
			var border: bool = x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1
			var pillar: bool = x % 9 == 4 and y % 7 >= 2 and y % 7 <= 4
			row += "#" if border or pillar else "."
		rows.append(row)
	arena.rows = rows
	arena.player_spawn = Vector2(160, 160)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for index in enemies:
		var placement: InfiltrationEnemyPlacement = InfiltrationEnemyPlacement.new()
		placement.enemy = load("res://data/blaster_ops/enemies/%s.tres" % ARCHETYPES[index % ARCHETYPES.size()])
		placement.position = _open_point(rng, arena)
		placement.direction = Vector2.LEFT
		arena.enemies.append(placement)
	var mission: BlasterOpsMissionData = BlasterOpsMissionData.new()
	mission.objective = InfiltrationMissionData.Objective.INCURSION
	mission.map = arena
	mission.extraction = Vector2(4000, 2400)
	var wave: BlasterOpsWaveData = BlasterOpsWaveData.new()
	wave.indices = PackedInt32Array()
	mission.waves = [wave] as Array[BlasterOpsWaveData]
	var spawns: PackedVector2Array = []
	for index in allies:
		spawns.append(_open_point(rng, arena))
	mission.prisoner_spawns = spawns
	return mission


func _open_point(rng: RandomNumberGenerator, arena: BlasterOpsArenaData) -> Vector2:
	while true:
		var x: int = rng.randi_range(2, MAP_WIDTH - 3)
		var y: int = rng.randi_range(2, MAP_HEIGHT - 3)
		if arena.rows[y][x] == ".":
			return (Vector2(x, y) + Vector2.ONE * 0.5) * arena.tile_size
	return Vector2.ZERO


func _run(enemies: int, allies: int) -> void:
	var mission: InfiltrationMissionData = _mission(enemies, allies)
	var loadout: BlasterOpsLoadout = BlasterOpsTraining.PISTOL.duplicate() as BlasterOpsLoadout
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(CONFIG, mission.map, loadout, mission)
	for index in sim.mission.recruited.size():
		sim.mission.recruited[index] = 1
	var enemy_controller: BlasterOpsMissionController = BlasterOpsMissionController.new(sim.map, sim.targets.size())
	var escort_controller: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var samples: PackedInt32Array = []
	samples.resize(TICKS - WARM_UP_TICKS)
	var peak: int = 0
	var center: Vector2 = Vector2(MAP_WIDTH, MAP_HEIGHT) * sim.map.tile_size * 0.5
	for index in sim.targets.size():
		InfiltrationPerception.alert(sim, index, sim.player.position)
	for tick in TICKS:
		sim.player.health = CONFIG.health
		for prisoner in sim.prisoners:
			prisoner.health = CONFIG.prisoner_health
		for target in sim.targets:
			target.health = maxf(target.health, 12.0)
		intent.clear()
		var angle: float = tick * 0.01
		intent.movement = (center + Vector2(cos(angle), sin(angle)) * 1200.0 - sim.player.position).normalized()
		intent.aim = Vector2.from_angle(tick * 0.05)
		intent.held = Intent.Command.LIGHT
		var start: int = Time.get_ticks_usec()
		sim.step(intent, enemy_controller.produce_all(sim), escort_controller.produce_all(sim))
		if tick >= WARM_UP_TICKS:
			samples[tick - WARM_UP_TICKS] = Time.get_ticks_usec() - start
		var active: int = 0
		for bolt in sim.bolts:
			active += int(bolt.active)
		peak = maxi(peak, active)
	samples.sort()
	var total: int = 0
	for value in samples:
		total += value
	var count: int = samples.size()
	print("%7d %6d %7d %7d %7d %11d %8d" % [enemies, allies, total / count, samples[int(count * 0.99)], samples[count - 1], peak, sim.dropped_events])
