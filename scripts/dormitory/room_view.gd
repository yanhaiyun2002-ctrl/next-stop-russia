class_name DormitoryView
extends Control
## Fixed front-facing projection, drawn with CanvasItem only; no Node3D/camera.
## Depth cuts are local to these three axis-aligned geometric samples.
signal object_selected(id: StringName)
signal framing_changed

const EYE_HEIGHT := 1.55
const CAMERA_DISTANCE := 3.8
const FOCAL := 780.0
const HORIZON := Vector2(640, 210)
const MARKER_COLOR := Color("ed795a")
var world: DormitoryWorld
var commands: Array[Dictionary] = []
var selected_id: StringName = &""
var framing := "auto"
var focus_x := 640.0
var pan_offset := 0.0
var view_scale := 1.0
var view_revision := 0
var _pressed_id: StringName = &""
var _pressed_revision := -1

func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	resized.connect(rebuild)

func configure(room_world: DormitoryWorld) -> void:
	world = room_world
	world.changed.connect(rebuild)
	rebuild()

func project_base(point: Vector3) -> Vector2:
	return HORIZON + Vector2(point.x, EYE_HEIGHT - point.y) * FOCAL / (CAMERA_DISTANCE + point.z)

func project(point: Vector3) -> Vector2:
	return size / 2.0 + (project_base(point) - Vector2(focus_x, 320)) * view_scale

func is_portrait() -> bool:
	return get_viewport_rect().size.y > get_viewport_rect().size.x

func effective_framing() -> String:
	return ("desk" if is_portrait() else "overview") if framing == "auto" else framing

func frame_object(id: String) -> void:
	if id != "overview" and not world.furniture.has(StringName(id)):
		return
	framing = id
	pan_offset = 0.0
	rebuild()

func pan(direction: float) -> void:
	if effective_framing() == "overview":
		framing = "desk"
	pan_offset += direction * 150.0
	rebuild()

func rebuild() -> void:
	if not is_instance_valid(world) or size.x <= 0 or size.y <= 0:
		return
	view_revision += 1
	_pressed_id = &""
	var mode := effective_framing()
	if mode == "overview":
		view_scale = minf(size.x / 1280.0, size.y / 640.0)
		focus_x = 640.0
	else:
		view_scale = minf(size.y / 560.0, size.x / 360.0) if is_portrait() else minf(size.x / 1000.0, size.y / 560.0)
		var item: GrayboxFurniture = world.furniture[StringName(mode)]
		focus_x = project_base(Vector3(item.floor_position.x, 0.7, item.floor_position.y + item.dimensions.z / 2)).x + pan_offset
		var half_width := size.x / (2.0 * view_scale)
		focus_x = clampf(focus_x, minf(half_width, 640.0), maxf(1280.0 - half_width, 640.0))
	commands.clear()
	var boxes := world.all_boxes()
	var cuts: Array[float] = [world.marker_position.y]
	for box in boxes:
		cuts.append(box.origin.z)
		cuts.append(box.origin.z + box.size.z)
	cuts.sort()
	for box in boxes:
		_box_faces(box, cuts)
	_marker()
	commands.sort_custom(func(a, b):
		if not is_equal_approx(a.depth, b.depth):
			return a.depth > b.depth
		return a.tie < b.tie)
	queue_redraw()
	framing_changed.emit()

func _face(points: Array[Vector3], owner: StringName, color: Color, depth: float, tie: float = 0) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(project(point))
	commands.append({"polygon": polygon, "owner": owner, "color": color, "depth": depth, "tie": tie})

func _box_faces(box: Dictionary, cuts: Array[float]) -> void:
	var p: Vector3 = box.origin
	var end: Vector3 = p + box.size
	var color: Color = box.color
	var owner: StringName = box.owner
	_face([Vector3(p.x, p.y, p.z), Vector3(end.x, p.y, p.z), Vector3(end.x, end.y, p.z), Vector3(p.x, end.y, p.z)], owner, color, p.z, 1)
	var depths: Array[float] = [p.z]
	for cut in cuts:
		if cut > p.z + 0.0001 and cut < end.z - 0.0001 and not depths.has(cut):
			depths.append(cut)
	depths.append(end.z)
	depths.sort()
	var side_x := end.x if (p.x + end.x) < 0 else p.x
	for i in range(depths.size() - 1):
		var a := depths[i]
		var b := depths[i + 1]
		if end.y < EYE_HEIGHT:
			_face([Vector3(p.x, end.y, a), Vector3(end.x, end.y, a), Vector3(end.x, end.y, b), Vector3(p.x, end.y, b)], owner, color.lightened(0.17), (a + b) / 2, end.y)
		if side_x * (p.x + end.x) > 0:
			_face([Vector3(side_x, p.y, a), Vector3(side_x, end.y, a), Vector3(side_x, end.y, b), Vector3(side_x, p.y, b)], owner, color.darkened(0.18), (a + b) / 2, -absf(side_x))

func _marker() -> void:
	var x := world.marker_position.x
	var z := world.marker_position.y
	_face([Vector3(x - 0.055, 0.03, z), Vector3(x + 0.055, 0.03, z), Vector3(x + 0.055, 0.73, z), Vector3(x - 0.055, 0.73, z)], &"marker", MARKER_COLOR, z, 10)
	var head: Array[Vector3] = []
	for i in range(24):
		var angle := TAU * i / 24.0
		head.append(Vector3(x + cos(angle) * 0.14, 0.74 + sin(angle) * 0.14, z))
	_face(head, &"marker", MARKER_COLOR, z, 10)
	_face([Vector3(x - 0.16, 0, z), Vector3(x + 0.16, 0, z), Vector3(x + 0.12, 0.07, z), Vector3(x - 0.12, 0.07, z)], &"marker", MARKER_COLOR, z, 10)

func pick(point: Vector2) -> StringName:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return &""
	for i in range(commands.size() - 1, -1, -1):
		if Geometry2D.is_point_in_polygon(point, commands[i].polygon):
			return commands[i].owner
	return &""

func visible_point(id: StringName) -> Vector2:
	# Test helper and focus target: sample only visible, rendered silhouette.
	for command in commands:
		if command.owner != id:
			continue
		var rect := Rect2(command.polygon[0], Vector2.ZERO)
		for point in command.polygon:
			rect = rect.expand(point)
		for fy in [0.5, 0.3, 0.7]:
			for fx in [0.5, 0.3, 0.7]:
				var point := rect.position + rect.size * Vector2(fx, fy)
				if pick(point) == id:
					return point
	return Vector2(-1, -1)

func _gui_input(event: InputEvent) -> void:
	# One touch->mouse path, consistent with project input settings.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed_id = pick(event.position)
			_pressed_revision = view_revision
		else:
			var released_id := _pressed_id
			var valid := _pressed_revision == view_revision and released_id != &"" and pick(event.position) == released_id
			_pressed_id = &""
			_pressed_revision = -1
			if valid:
				selected_id = released_id
				object_selected.emit(selected_id)
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("17242b"))
	if not is_instance_valid(world):
		return
	_room_shell()
	for command in commands:
		draw_colored_polygon(command.polygon, command.color)

func _room_polygon(points: Array[Vector3], color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(project(point))
	draw_colored_polygon(polygon, color)
	polygon.append(polygon[0])
	draw_polyline(polygon, Color("566970"), maxf(1.0, view_scale * 2.0), true)

func _room_shell() -> void:
	_room_polygon([Vector3(-3.4, 0, 5.5), Vector3(3.4, 0, 5.5), Vector3(3.4, 3, 5.5), Vector3(-3.4, 3, 5.5)], Color("deded4"))
	_room_polygon([Vector3(-3.4, 0, 0), Vector3(-3.4, 0, 5.5), Vector3(-3.4, 3, 5.5), Vector3(-3.4, 3, 0)], Color("a6b3b8"))
	_room_polygon([Vector3(3.4, 0, 5.5), Vector3(3.4, 0, 0), Vector3(3.4, 3, 0), Vector3(3.4, 3, 5.5)], Color("bdc7c5"))
	_room_polygon([Vector3(-3.4, 0, 0), Vector3(3.4, 0, 0), Vector3(3.4, 0, 5.5), Vector3(-3.4, 0, 5.5)], Color("c8c3b5"))
	for x in [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]:
		draw_line(project(Vector3(x, 0, 0)), project(Vector3(x, 0, 5.5)), Color("a6a69c"), maxf(0.7, view_scale), true)
	for depth in [1.0, 2.0, 3.0, 4.0, 5.0]:
		draw_line(project(Vector3(-3.4, 0, depth)), project(Vector3(3.4, 0, depth)), Color("a6a69c"), maxf(0.7, view_scale), true)
