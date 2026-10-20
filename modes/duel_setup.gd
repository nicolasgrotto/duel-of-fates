class_name DuelSetup
extends RefCounted

enum ControllerKind { PLAYER, AI, DUMMY }

var characters: Array[CharacterData] = []
var controllers: Array[ControllerKind] = []
var player_slots: Array[int] = [0, 1]
var hold_to_lock: Array[bool] = [false, false]
var difficulty: AiDifficultyData
var rules: MatchRules
var arena: ArenaData
var match_seed: int = 0
var training: bool = false
