extends Node
## Test-only event evidence. No game behavior, input mutation or interception.
var target: Control
var phase := ""
var records: Array[Dictionary] = []

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch or (event is InputEventMouseMotion and event.button_mask != 0):
		record("input", event)

func record(path: String, event: InputEvent) -> void:
	if phase.is_empty() or records.size() >= 500:
		return
	var room: Node = target.get("active_room")
	if not room:
		return
	var view: Control = room.get("room_view")
	var world: Node = room.get("world")
	records.append({"phase": phase, "path": path, "type": event.get_class(), "position": str(event.get("position")),
		"pressed": event.get("pressed") if event is InputEventMouseButton or event is InputEventScreenTouch else null,
		"settled": target.get("safe_layout").is_layout_settled(), "camera": view.get("focus_x"), "pointer_down": view.get("_pointer_down"),
		"button_rect": str(room.get("hunt_action").get_global_rect()), "viewport_mouse": str(target.get_viewport().get_mouse_position()),
		"active": world.is_hunt_active(), "found": world.get("hunt").found, "hint": world.get("hunt").hint_requested})
