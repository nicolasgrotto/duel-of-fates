class_name ArcadeMode
extends DuelMode

var fight: int = 0
var opponents: Array[CharacterData] = []
var won_last: bool = false
var cleared: bool = false


func steps() -> Array[StringName]:
	return [&"player"]


func total_fights() -> int:
	return MODES.arcade_opponents + 1


func is_boss_fight() -> bool:
	return fight >= MODES.arcade_opponents


func player() -> CharacterData:
	return selection.characters[0] if selection.characters[0] != null else GUARDIAN


func build_setup() -> DuelSetup:
	if opponents.is_empty():
		opponents = ladder(player().id, MODES.arcade_opponents)
	var setup: DuelSetup = DuelSetup.new()
	var opponent: CharacterData = character_for_fight()
	setup.characters = [player(), opponent]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.AI]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.difficulty = difficulty(fight_difficulty())
	if is_boss_fight():
		setup.awakening = [null, BOSS_DIFFICULTY]
	setup.rules = MatchRules.new()
	setup.rules.powers = Settings.powers
	setup.arena = ARENAS[fight % ROTATION_SIZE]
	setup.match_seed = _new_seed()
	setup.banner = TranslationServer.translate("ARCADE_BANNER").format({
		"fight": fight + 1, "total": total_fights(), "name": TranslationServer.translate(opponent.name_key).to_upper(),
	})
	return _finish_setup(setup)


func character_for_fight() -> CharacterData:
	if is_boss_fight():
		return load(BOSS_PATH) as CharacterData
	return opponents[fight]


func fight_difficulty() -> StringName:
	if is_boss_fight() or fight >= MODES.arcade_easy_fights + MODES.arcade_normal_fights:
		return &"hard"
	return &"easy" if fight < MODES.arcade_easy_fights else &"normal"


static func ladder(player_id: StringName, count: int) -> Array[CharacterData]:
	var start: int = maxi(CAST.find(player_id), 0)
	var list: Array[CharacterData] = []
	var offset: int = 1
	while list.size() < count and offset <= CAST.size() * 2:
		var id: StringName = CAST[(start + offset) % CAST.size()]
		offset += 1
		if id != player_id:
			list.append(character(id))
	return list


func finish(winner: int, _sim: MatchSimulation) -> void:
	won_last = winner == 0
	if won_last and is_boss_fight():
		cleared = true
		SaveService.clear_arcade(player().id)


func result_options() -> Array[StringName]:
	if cleared:
		return [&"menu"]
	return [&"next", &"menu"] if won_last else [&"retry", &"menu"]


func result_title() -> String:
	return TranslationServer.translate("ARCADE_CLEARED") if cleared else ""


func choose(option: StringName) -> void:
	if option == &"next":
		fight += 1
	super.choose(option)
