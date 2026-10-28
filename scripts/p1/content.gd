class_name P1Content
extends RefCounted
## Stable content IDs; draft copy is never presented as approved text.
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/p1/content.json"))
	return _data

static func vector(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

static func object_anchor(world: DormitoryWorld, id: String) -> Vector3:
	if id == "window":
		return Vector3(0, 0, world.room_depth - 0.02)
	var floor_point: Vector2 = world.furniture[StringName(id)].floor_position
	return Vector3(floor_point.x, 0, floor_point.y)

static func spot(id: String) -> Dictionary:
	for entry in data().spots:
		if entry.spotId == id:
			return entry
	return {}
