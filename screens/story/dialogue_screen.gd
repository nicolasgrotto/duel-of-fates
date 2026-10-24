extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const CHARACTER_PATH: String = "res://data/characters/%s/%s.tres"
const BACKDROP_GRID: Vector2i = Vector2i(480, 270)
const PIXEL_SCALE: float = 4.0
const FIGHTER_GAP: float = 120.0
const BAND_HEIGHT: float = 210.0
const BAND_ALPHA: float = 0.82
const BACKDROP_DIM: float = 0.65
const LINE_FADE: float = 0.3
const TITLE_TOP: float = 60.0
const TEXT_MARGIN: float = 140.0

var campaign: StoryCampaign
var encounter: EncounterData
var part: StringName = &"before"
var gallery: bool = false

var _lines: Array[DialogueLine] = []
var _index: int = -1
var _speaker: Label
var _text: Label
var _fade: float = 1.0


func open(params: Dictionary) -> void:
	campaign = params.get("campaign")
	encounter = params["encounter"]
	part = params.get("part", &"before")
	gallery = params.get("gallery", false)
	var source: Array[DialogueLine] = encounter.before.duplicate() if part == &"before" else encounter.after.duplicate()
	if gallery and part == &"both":
		source = encounter.before.duplicate()
		source.append_array(encounter.after)
	var flow_path: int = params.get("path", campaign.path if campaign != null else 0)
	var filter: DialogueLine.PathFilter = DialogueLine.PathFilter.AURORA if flow_path == 0 else DialogueLine.PathFilter.ECLIPSE
	for line in source:
		if line.path == DialogueLine.PathFilter.ANY or line.path == filter:
			_lines.append(line)
	_build()
	_advance()


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop: ArenaThumbnail = ArenaThumbnail.new()
	backdrop.configure(BACKDROP_GRID, PIXEL_SCALE)
	backdrop.position = Vector2(BACKDROP_GRID) * PIXEL_SCALE * 0.5
	backdrop.modulate = Color(BACKDROP_DIM, BACKDROP_DIM, BACKDROP_DIM)
	add_child(backdrop)
	backdrop.show_arena(encounter.arena)
	var left: StandingFighter = StandingFighter.new()
	left.position = Vector2(-FIGHTER_GAP, 0.0)
	backdrop.add_to_world(left)
	var right: StandingFighter = StandingFighter.new()
	right.position = Vector2(FIGHTER_GAP, 0.0)
	backdrop.add_to_world(right)
	var hero: CharacterData = campaign.protagonist() if campaign != null else DuelMode.GUARDIAN
	left.show_fighter(hero, hero.costumes[0], hero.blade_colors[0], 1)
	var opponent: CharacterData = load(CHARACTER_PATH % [encounter.opponent, encounter.opponent])
	right.show_fighter(opponent, opponent.costumes[0], opponent.blade_colors[0], -1)
	var title: Label = Label.new()
	title.theme_type_variation = &"ScreenTitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = TITLE_TOP
	title.text = tr("STORY_BANNER").format({"chapter": encounter.chapter, "title": tr(encounter.title_key).to_upper()})
	add_child(title)
	var band: ColorRect = ColorRect.new()
	band.color = Color(PALETTE.background, BAND_ALPHA)
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -BAND_HEIGHT
	add_child(band)
	_speaker = Label.new()
	_speaker.theme_type_variation = &"SubtitleLabel"
	_speaker.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_speaker.offset_top = -BAND_HEIGHT + 30.0
	_speaker.offset_left = TEXT_MARGIN
	add_child(_speaker)
	_text = Label.new()
	_text.theme_type_variation = &"InfoLabel"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_text.offset_top = -BAND_HEIGHT + 80.0
	_text.offset_left = TEXT_MARGIN
	_text.offset_right = -TEXT_MARGIN
	add_child(_text)
	var hints: Label = Label.new()
	hints.theme_type_variation = &"HintLabel"
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hints.offset_top = -50.0
	hints.offset_right = -TEXT_MARGIN
	hints.text = ControlHints.line(PackedStringArray([ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_SKIP")]))
	add_child(hints)


func _process(delta: float) -> void:
	_fade = minf(_fade + delta / LINE_FADE, 1.0)
	if _text != null:
		_text.modulate.a = _fade
		_speaker.modulate.a = _fade


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_done()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_done()
		return
	var line: DialogueLine = _lines[_index]
	_speaker.text = _speaker_name(line.speaker).to_upper()
	var player_name: String = campaign.name if campaign != null else tr("STORY_PROTAGONIST")
	_text.text = tr(line.text_key).format({"name": player_name})
	_fade = 0.0


func _speaker_name(speaker: StringName) -> String:
	match speaker:
		&"narrator":
			return ""
		&"protagonist":
			return campaign.name if campaign != null else tr("STORY_PROTAGONIST")
	var data: CharacterData = load(CHARACTER_PATH % [speaker, speaker])
	return tr(data.name_key) if data != null else ""


func _done() -> void:
	if _index > _lines.size() + 1:
		return
	_index = _lines.size() + 2
	if gallery:
		SceneRouter.change(&"story_gallery")
	elif part == &"before":
		StoryMode.new(campaign, encounter).start()
	elif campaign.is_finished():
		SceneRouter.change(&"ending", {"ending": campaign.ending_data(), "campaign": campaign})
	else:
		SceneRouter.change(&"story_hub")
