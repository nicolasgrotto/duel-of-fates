class_name CampaignData
extends Resource

const TreeNodeData = preload("res://data/story/story_tree_node.gd")

@export var common: Array[EncounterData] = []
@export var aurora: Array[EncounterData] = []
@export var eclipse: Array[EncounterData] = []
@export var aurora_secret: EncounterData
@export var eclipse_secret: EncounterData
@export var aurora_normal_ending: EndingData
@export var aurora_secret_ending: EndingData
@export var eclipse_normal_ending: EndingData
@export var eclipse_secret_ending: EndingData
@export var names: PackedStringArray = ["Kael", "Iria", "Tarin", "Vessa", "Oren", "Lyse"]
@export var styles: Array[StringName] = [&"guardian", &"shadow", &"heron"]
@export var style_keys: PackedStringArray = ["STYLE_TECHNIQUE", "STYLE_FURY", "STYLE_FLIGHT"]
@export var outfits: Array[CostumeData] = [
	preload("res://data/story/outfits/wanderer.tres"), preload("res://data/story/outfits/watcher.tres"),
	preload("res://data/story/outfits/pilgrim.tres"), preload("res://data/story/outfits/plate.tres"),
	preload("res://data/story/outfits/layered.tres"),
	preload("res://data/story/outfits/scout.tres"),
	preload("res://data/story/outfits/noble.tres"),
	preload("res://data/story/outfits/ash.tres"),
	preload("res://data/story/outfits/duelist.tres"),
	preload("res://data/story/outfits/desert.tres"),
	preload("res://data/story/outfits/sentry.tres"),
]
@export var hair_styles: PackedStringArray = ["", "hair_short", "hair_mid_wavy", "hair_wavy", "hair_long", "hair_ponytail", "hair_bun", "hair_bob", "hair_long_straight", "hair_braid", "hair_high_ponytail", "hair_side_bangs"]
@export var hair_keys: PackedStringArray = ["HAIR_NONE", "HAIR_SHORT", "HAIR_MID_WAVY", "HAIR_WAVY", "HAIR_LONG", "HAIR_PONYTAIL", "HAIR_BUN", "HAIR_BOB", "HAIR_LONG_STRAIGHT", "HAIR_BRAID", "HAIR_HIGH_PONYTAIL", "HAIR_SIDE_BANGS"]
@export var beard_styles: PackedStringArray = ["", "beard_short", "beard_full", "beard_long", "beard_mustache"]
@export var beard_keys: PackedStringArray = ["BEARD_NONE", "BEARD_SHORT", "BEARD_FULL", "BEARD_LONG", "BEARD_MUSTACHE"]
@export var hair_colors: PackedColorArray = [Color("#3b2a1e"), Color("#5a3d26"), Color("#7a3a1c"), Color("#9a7a45"), Color("#1c1a1a"), Color("#8a8784")]
@export var hair_color_keys: PackedStringArray = ["HAIR_COLOR_DARK_BROWN", "HAIR_COLOR_BROWN", "HAIR_COLOR_AUBURN", "HAIR_COLOR_DARK_BLOND", "HAIR_COLOR_BLACK", "HAIR_COLOR_GREY"]
@export var skin_tones: PackedColorArray = [Color("#e0b48e"), Color("#c4936c"), Color("#9a6a48"), Color("#6e4630"), Color("#4a2e20")]
@export var skin_keys: PackedStringArray = ["SKIN_LIGHT", "SKIN_FAIR", "SKIN_MEDIUM", "SKIN_DARK", "SKIN_DEEP"]
@export var default_hair: int = 1
@export var default_skin: int = 1
@export var blade_sources: Array[StringName] = [&"guardian", &"shadow", &"bastion", &"wasp", &"mirror", &"lance", &"ember", &"forge", &"heron", &"reaper"]
@export var blade_tree: Array[TreeNodeData] = []
@export var style_forward_fallback: MoveData = preload("res://data/techniques/thrust.tres")
@export var style_air_fallback: MoveData = preload("res://data/techniques/plunge.tres")
@export var aurora_tree: Array[TreeNodeData] = []
@export var eclipse_tree: Array[TreeNodeData] = []
@export var skill_points_win: int = 3
@export var skill_points_loss: int = 1
@export var skill_points_milestone: int = 1
@export var skill_points_secret: int = 3
@export var start_attribute: int = 3
@export var start_points: int = 3
@export var max_attribute: int = 7
@export var points_per_win: PackedInt32Array = [3, 2, 1]
@export var milestone_points: Array[PackedInt32Array] = [PackedInt32Array([3, 3]), PackedInt32Array([3, 2]), PackedInt32Array([2, 2])]
@export var secret_health_ratio: float = 0.75
