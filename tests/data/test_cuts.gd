extends TestCase

const CHARACTERS_ROOT: String = "res://data/characters"
const COMMITTED_HEAVY: Array[MoveData.Cut] = [MoveData.Cut.DESCENDING, MoveData.Cut.SPIN]


func _characters() -> Array[CharacterData]:
	var found: Array[CharacterData] = []
	for folder in DirAccess.get_directories_at(CHARACTERS_ROOT):
		var path: String = "%s/%s/%s.tres" % [CHARACTERS_ROOT, folder, folder]
		if ResourceLoader.exists(path):
			found.append(load(path) as CharacterData)
	return found


func test_every_chain_step_has_its_own_cut() -> void:
	for data in _characters():
		var seen: Array[MoveData.Cut] = []
		for move in data.light_chain:
			assert_ne(move.cut, MoveData.Cut.ARC, "%s %s has a cut type" % [data.id, move.id])
			assert_false(seen.has(move.cut), "%s repeats the cut of %s" % [data.id, move.id])
			seen.append(move.cut)


func test_heavies_are_the_most_committed_cut() -> void:
	for data in _characters():
		for move in [data.heavy, data.forward_heavy]:
			var rising_striker: bool = data.family.id == &"striker" and move.cut == MoveData.Cut.RISING
			assert_true(COMMITTED_HEAVY.has(move.cut) or rising_striker, "%s %s" % [data.id, move.id])
