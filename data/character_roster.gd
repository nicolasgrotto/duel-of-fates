class_name CharacterRoster
extends RefCounted

const IDS: Array[StringName] = [
	&"guardian", &"shadow", &"bastion", &"wasp", &"mirror", &"lance", &"ember", &"forge", &"heron", &"reaper", &"echo", &"corsair", &"lynx",
	&"sovereign", &"elder", &"foretold",
]
const PATH: String = "res://data/characters/%s/%s.tres"


static func path(id: StringName) -> String:
	return PATH % [id, id]


static func character(id: StringName) -> CharacterData:
	return load(path(id)) as CharacterData
