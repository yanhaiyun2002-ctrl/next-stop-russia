class_name DormitoryWorld
extends Node2D
signal changed

const DESK_SLOTS: Array[Vector2] = [Vector2(0.35, 3.2), Vector2(-0.45, 0.25)]
const MARKER_POINTS: Array[Vector2] = [Vector2(-1.7, 0.85), Vector2(-1.7, 3.60),
	Vector2(0.35, 4.35), Vector2(-0.45, 1.6), Vector2(2.1, 5.25), Vector2(2.1, 3.85)]
const MARKER_NAMES := ["床前", "床后", "桌后 / 腿间", "家具之间", "衣柜后", "衣柜前"]
var furniture: Dictionary = {}
var marker_position := MARKER_POINTS[0]
var marker_index := 0
var desk_slot := 0
var depth_direction := 1.0
var room_half_width := 3.0
var room_depth := 5.4
var room_height := 2.8

func _ready() -> void:
	for packed in [preload("res://scenes/dormitory/bed.tscn"), preload("res://scenes/dormitory/desk.tscn"), preload("res://scenes/dormitory/wardrobe.tscn")]:
		var item: GrayboxFurniture = packed.instantiate()
		add_child(item)
		furniture[item.furniture_id] = item

func all_boxes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in furniture.values():
		result.append_array(item.boxes())
	return result

func set_marker(point: Vector2) -> void:
	marker_position = point.clamp(Vector2(-room_half_width + 0.3, 0.4), Vector2(room_half_width - 0.3, room_depth - 0.05))
	changed.emit()

func cycle_marker() -> void:
	marker_index = (marker_index + 1) % MARKER_POINTS.size()
	set_marker(MARKER_POINTS[marker_index])

func step_marker() -> void:
	var depth := marker_position.y + 0.35 * depth_direction
	if depth > 5.2 or depth < 0.55:
		depth_direction *= -1.0
		depth = marker_position.y + 0.35 * depth_direction
	set_marker(Vector2(marker_position.x, depth))

func move_furniture(id: StringName, point: Vector2) -> bool:
	if not furniture.has(id):
		return false
	var item: GrayboxFurniture = furniture[id]
	var old := item.floor_position
	item.floor_position = point
	var footprint := item.footprint()
	var valid := Rect2(-room_half_width + 0.05, 0.05, room_half_width * 2 - 0.1, room_depth - 0.1).encloses(footprint)
	for other in furniture.values():
		if other != item and footprint.intersects(other.footprint()):
			valid = false
	if not valid:
		item.floor_position = old
		return false
	changed.emit()
	return true

func toggle_desk() -> bool:
	var next := 1 - desk_slot
	if not move_furniture(&"desk", DESK_SLOTS[next]):
		return false
	desk_slot = next
	return true
