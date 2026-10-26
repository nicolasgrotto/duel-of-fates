extends SceneTree

const CONFIG_PATH: String = "res://data/balance/combat_config.tres"
const CHARACTER_PATH: String = "res://data/characters/%s/%s.tres"
const DIFFICULTY_PATH: String = "res://data/balance/ai/difficulty_%s.tres"
const MATRIX_CAST: Array[String] = ["guardian", "shadow", "bastion", "wasp", "mirror", "lance", "ember", "forge", "heron", "reaper", "echo", "corsair", "lynx"]


func _initialize() -> void:
	var options: Dictionary = _parse_options({
		"duels": "100",
		"difficulty": "normal",
		"p1": "guardian",
		"p2": "shadow",
		"seed": "1",
	})
	var config: CombatConfig = load(CONFIG_PATH)
	if options.has("matrix"):
		_matrix(config, options)
		quit()
		return
	var characters: Array[CharacterData] = [_character(options["p1"]), _character(options["p2"])]
	var difficulty: AiDifficultyData = load(DIFFICULTY_PATH % options["difficulty"])
	var difficulties: Array[AiDifficultyData] = [difficulty, difficulty]
	var duels: int = int(options["duels"])
	var wins: Array[int] = [0, 0]
	var unfinished: int = 0
	var total_fight_ticks: int = 0
	var total_knockouts: int = 0
	var total_hits: int = 0
	var totals: Dictionary = {}
	for i in duels:
		var duel: HeadlessDuel = HeadlessDuel.new(config, characters, difficulties, int(options["seed"]) + i)
		var winner: int = duel.run()
		if winner == MatchSimulation.NO_WINNER:
			unfinished += 1
		else:
			wins[winner] += 1
		total_fight_ticks += duel.fight_ticks
		total_knockouts += duel.knockouts
		total_hits += duel.hits_before_knockout
		for type in duel.event_counts:
			totals[type] = totals.get(type, 0) + duel.event_counts[type]
	_report(options, duels, wins, unfinished, total_fight_ticks, total_knockouts, total_hits, totals)
	quit()


func _character(id: String) -> CharacterData:
	return load(CHARACTER_PATH % [id, id])


func _parse_options(defaults: Dictionary) -> Dictionary:
	var options: Dictionary = defaults.duplicate()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i].begins_with("--"):
			options[args[i].substr(2)] = args[i + 1]
	return options


func _report(options: Dictionary, duels: int, wins: Array[int], unfinished: int, fight_ticks: int, knockouts: int, hits: int, totals: Dictionary) -> void:
	var rounds: int = maxi(knockouts, 1)
	print("Duels: %d  %s vs %s  difficulty %s" % [duels, options["p1"], options["p2"], options["difficulty"]])
	print("Wins: %s %d (%.0f%%)  %s %d (%.0f%%)  unfinished %d" % [
		options["p1"], wins[0], 100.0 * wins[0] / duels, options["p2"], wins[1], 100.0 * wins[1] / duels, unfinished,
	])
	print("Clean hits until K.O.: %.1f" % (float(hits) / rounds))
	print("Round length: %.1f s" % (Ticks.to_seconds(fight_ticks) / rounds))
	var per_round: PackedStringArray = []
	for type in totals:
		per_round.append("%s %.1f" % [CombatEvent.Type.keys()[type].to_lower(), float(totals[type]) / rounds])
	per_round.sort()
	print("Events per round: ", ", ".join(per_round))
	_report_contacts(totals)


func _report_contacts(totals: Dictionary) -> void:
	print("Contacts total: hit %d, clash %d, lock %d, press %d" % [totals.get(CombatEvent.Type.HIT, 0), totals.get(CombatEvent.Type.CLASH, 0), totals.get(CombatEvent.Type.BLADE_LOCK_STARTED, 0), totals.get(CombatEvent.Type.BLADE_PRESS_STARTED, 0)])


func _matrix(config: CombatConfig, options: Dictionary) -> void:
	var difficulty: AiDifficultyData = load(DIFFICULTY_PATH % options["difficulty"])
	var difficulties: Array[AiDifficultyData] = [difficulty, difficulty]
	var duels: int = int(options["duels"])
	var cast: Array[String] = MATRIX_CAST
	if options["matrix"] != "all":
		cast = []
		for id in String(options["matrix"]).split(","):
			cast.append(id)
	var totals: Dictionary = {}
	var contacts: Dictionary = {}
	var header: String = "%-10s" % ""
	for id in cast:
		header += " %6s" % id.substr(0, 6)
		totals[id] = [0, 0]
	print("Matrix: %d duels per pair, difficulty %s (row win %%, both sides)" % [duels, options["difficulty"]])
	print(header + "   total")
	for a in cast:
		var line: String = "%-10s" % a
		for b in cast:
			if a == b:
				line += " %6s" % "-"
				continue
			var wins: int = 0
			for i in duels:
				var swap: bool = i % 2 == 1
				var pair: Array[CharacterData] = [_character(a), _character(b)]
				if swap:
					pair.reverse()
				var duel: HeadlessDuel = HeadlessDuel.new(config, pair, difficulties, int(options["seed"]) + i * 7919 + a.hash() % 997)
				var winner: int = duel.run()
				for type in duel.event_counts:
					contacts[type] = contacts.get(type, 0) + duel.event_counts[type]
				if winner == (1 if swap else 0):
					wins += 1
			totals[a][0] += wins
			totals[a][1] += duels
			line += " %5.0f%%" % (100.0 * wins / duels)
		line += "  %5.1f%%" % (100.0 * totals[a][0] / maxi(totals[a][1], 1))
		print(line)
	_report_contacts(contacts)
