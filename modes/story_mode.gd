class_name StoryMode
extends DuelMode

var campaign: StoryCampaign
var encounter: EncounterData
var won: bool = false
var notes: PackedStringArray = []


func _init(story: StoryCampaign, story_encounter: EncounterData) -> void:
	campaign = story
	encounter = story_encounter


func steps() -> Array[StringName]:
	return []


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	var protagonist: CharacterData = campaign.protagonist()
	setup.characters = [protagonist, character(encounter.opponent)]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.AI]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.difficulty = difficulty(campaign.difficulty_id(encounter.ai_offset))
	if encounter.boss_ai:
		setup.awakening = [null, BOSS_DIFFICULTY]
	setup.rules = MatchRules.new()
	setup.rules.rounds_to_win = 1
	setup.rules.powers = true
	setup.arena = encounter.arena
	setup.match_seed = _new_seed()
	setup.costumes = [protagonist.costumes[0]]
	setup.blade_colors = [protagonist.blade_colors[0]]
	setup.banner = TranslationServer.translate("STORY_BANNER").format({
		"chapter": encounter.chapter, "title": TranslationServer.translate(encounter.title_key).to_upper(),
	})
	setup.fill_default_looks()
	return setup


func finish(winner: int, sim: MatchSimulation, _seconds: float) -> void:
	won = winner == 0
	if won:
		notes = campaign.complete(encounter, sim.fighters[0].health_ratio())
		SaveService.unlock("seen:encounter:%s" % encounter.id)
		campaign.save()


func result_options() -> Array[StringName]:
	return [&"continue"] if won else [&"retry", &"story"]


func result_title() -> String:
	return TranslationServer.translate("STORY_CHAPTER_WON") if won else ""


func result_note() -> String:
	return " · ".join(notes)


func choose(option: StringName) -> void:
	match option:
		&"continue":
			SceneRouter.change(&"dialogue", {"campaign": campaign, "encounter": encounter, "part": &"after"})
		&"story":
			SceneRouter.change(&"story_hub")
		_:
			super.choose(option)
