class_name GalleryMode
extends DuelMode

var caster_id: StringName = &"guardian"
var entry_index: int = 0
var section: GalleryPanel.Section = GalleryPanel.Section.POWERS


func steps() -> Array[StringName]:
	return []


func required_resources() -> PackedStringArray:
	return PackedStringArray([CHARACTER_PATH % [caster_id, caster_id], SHADOW.resource_path])


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [DuelMode.character(caster_id).duplicate(), SHADOW.duplicate()]
	setup.controllers = [DuelSetup.ControllerKind.GALLERY, DuelSetup.ControllerKind.GALLERY]
	setup.rules = MatchRules.new()
	setup.rules.endless = true
	setup.rules.free_powers = true
	setup.rules.round_intro = false
	setup.arena = TRAINING_ARENA
	setup.match_seed = _new_seed()
	setup.training = true
	setup.gallery = true
	return setup


func result_options() -> Array[StringName]:
	return [&"menu"]
