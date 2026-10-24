class_name DialogueLine
extends Resource

enum PathFilter { ANY, AURORA, ECLIPSE }

@export var speaker: StringName
@export var text_key: String
@export var path: PathFilter = PathFilter.ANY
