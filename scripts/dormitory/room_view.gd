class_name DormitoryView
extends Control
## Fixed front-facing projection, drawn with CanvasItem only; no Node3D/camera.
## Depth cuts are local to these three axis-aligned geometric samples.
signal object_selected(id: StringName)
signal framing_changed
signal empty_tapped

const HORIZON := Vector2(640, 210)
const MARKER_COLOR := Color("ed795a")
# Local composition trials only; the world/furniture and face-sorter stay shared.
const COMPOSITIONS := {
	"original": [3.4, 5.5, 3.0, 1.55, 3.8, 780.0],
	"balanced": [3.2, 5.5, 2.8, 1.4, 8.0, 1200.0],
	"compact": [3.0, 5.4, 2.8, 1.3, 12.0, 1500.0],
	"ribbon": [6.0, 5.4, 3.0, 1.4, 12.0, 1500.0]
}
var composition := "ribbon"
var eye_height := 1.4
var camera_distance := 12.0
var focal := 1500.0
var ceiling_emphasis := true
var overview_bounds := Rect2()
var focus_y := 320.0
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
const DRAG_THRESHOLD := 10.0
var pan_limits := Vector2.ZERO
var browse_center_x := 640.0
var _browse_position_set := false
var _pointer_down := false
var _press_position := Vector2.ZERO
var _press_camera_x := 640.0
var _press_scale := 1.0
var _dragging := false
var _gesture_cancelled := false

func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	resized.connect(rebuild)

func configure(room_world: DormitoryWorld) -> void:
	world = room_world
	world.changed.connect(rebuild)
	rebuild()

func set_composition(id: String) -> void:
	if not COMPOSITIONS.has(id):
		return
	composition = id
	world.set_layout("ribbon" if id == "ribbon" else "legacy")
	var values: Array = COMPOSITIONS[id]
	world.room_half_width = values[0]
	world.room_depth = values[1]
	world.room_height = values[2]
	eye_height = values[3]
	camera_distance = values[4]
	focal = values[5]
	world.room_front = -2.4 if id == "ribbon" else 0.0
	framing = "auto"
	pan_offset = 0.0
	_browse_position_set = false
	world.changed.emit()

func set_ceiling_emphasis(value: bool) -> void:
	ceiling_emphasis = value
	rebuild()

func project_base(point: Vector3) -> Vector2:
	return HORIZON + Vector2(point.x, eye_height - point.y) * focal / (camera_distance + point.z)

func project(point: Vector3) -> Vector2:
	return size / 2.0 + (project_base(point) - Vector2(focus_x, focus_y)) * view_scale

func is_portrait() -> bool:
	return get_viewport_rect().size.y > get_viewport_rect().size.x

func effective_framing() -> String:
	return ("browse" if composition == "ribbon" else "overview") if framing == "auto" else framing

func reset_browse() -> void:
	_browse_position_set = false
	framing = "auto"
	rebuild()

func set_browse_center(value: float) -> void:
	browse_center_x = clampf(value, pan_limits.x, pan_limits.y)
	_browse_position_set = true
	framing = "auto"
	rebuild()

func frame_object(id: String) -> void:
	if id != "overview" and not world.furniture.has(StringName(id)):
		return
	if composition == "ribbon":
		if id == "overview":
			reset_browse()
		else:
			set_browse_center(_item_bounds(world.furniture[StringName(id)]).get_center().x)
		return
	framing = id
	pan_offset = 0.0
	rebuild()

func pan(direction: float) -> void:
	if composition == "ribbon":
		set_browse_center(browse_center_x + direction * 150)
		return
	if effective_framing() == "overview":
		framing = "desk"
	pan_offset += direction * 150.0
	rebuild()

func rebuild(preserve_pointer := false) -> void:
	if not is_instance_valid(world) or size.x <= 0 or size.y <= 0:
		return
	view_revision += 1
	if not preserve_pointer:
		_cancel_pointer()
	var mode := effective_framing()
	overview_bounds = _overview_bounds()
	if mode == "browse":
		var left := project_base(Vector3(-world.room_half_width, 0, world.room_depth)).x
		var right := project_base(Vector3(world.room_half_width, 0, world.room_depth)).x
		# Fill the vertical viewing window, never squeeze the whole ribbon into a
		# phone. At wide PC sizes a minimum scale avoids exposing the rear edges.
		view_scale = maxf(size.y / 430.0, size.x / (right - left - 8))
		var half := size.x / (2 * view_scale)
		pan_limits = Vector2(left + half + 2, right - half - 2)
		# Stop at the outer furniture, rather than browsing more empty wall.
		pan_limits.x = maxf(pan_limits.x, _item_bounds(world.furniture[&"bed"]).get_center().x)
		pan_limits.y = minf(pan_limits.y, _item_bounds(world.furniture[&"wardrobe"]).get_center().x)
		if not _browse_position_set:
			browse_center_x = 640.0
			if not is_portrait():
				var furniture_bounds := _item_bounds(world.furniture[&"bed"]).merge(_item_bounds(world.furniture[&"wardrobe"]))
				browse_center_x = furniture_bounds.get_center().x
			_browse_position_set = true
		browse_center_x = clampf(browse_center_x, pan_limits.x, pan_limits.y)
		focus_x = browse_center_x
		focus_y = 200.0
	elif mode == "overview":
		view_scale = minf((size.x - 16) / overview_bounds.size.x, (size.y - 16) / overview_bounds.size.y)
		focus_x = overview_bounds.get_center().x
		focus_y = overview_bounds.get_center().y
	else:
		var item: GrayboxFurniture = world.furniture[StringName(mode)]
		var bounds := _item_bounds(item).grow(32)
		view_scale = minf((size.x - 24) / bounds.size.x, (size.y - 24) / bounds.size.y)
		focus_x = clampf(bounds.get_center().x + pan_offset, overview_bounds.position.x, overview_bounds.end.x)
		focus_y = bounds.get_center().y
	commands.clear()
	var boxes := world.all_boxes()
	var cat_parts := world.cat_parts()
	var cuts: Array[float] = [world.marker_position.y]
	for part in cat_parts:
		cuts.append(part.depth)
	for box in boxes:
		cuts.append(box.origin.z)
		cuts.append(box.origin.z + box.size.z)
	cuts.sort()
	for box in boxes:
		_box_faces(box, cuts)
	if cat_parts.is_empty() and not is_instance_valid(world.encounter):
		_marker()
	else:
		for part in cat_parts:
			_face(part.points, &"cat", part.color, part.depth, part.tie)
			if part.has("texture"):
				commands.back().texture = part.texture
				commands.back().uv = part.uv
	commands.sort_custom(func(a, b):
		if not is_equal_approx(a.depth, b.depth):
			return a.depth > b.depth
		return a.tie < b.tie)
	queue_redraw()
	framing_changed.emit()

func _item_bounds(item: GrayboxFurniture, position_override := Vector2(INF, INF)) -> Rect2:
	var point := item.floor_position if is_inf(position_override.x) else position_override
	var bounds := Rect2(project_base(Vector3(point.x, 0, point.y)), Vector2.ZERO)
	for x in [point.x - item.dimensions.x / 2, point.x + item.dimensions.x / 2]:
		for y in [0.0, item.dimensions.y]:
			for z in [point.y, point.y + item.dimensions.z]:
				bounds = bounds.expand(project_base(Vector3(x, y, z)))
	return bounds

func _overview_bounds() -> Rect2:
	# Frame the back wall and ALL furniture, including both desk slots. Empty
	# peripheral front-wall corners may extend offscreen; furniture never does.
	var w := world.room_half_width
	var d := world.room_depth
	var h := world.room_height
	var front_top := project_base(Vector3(0, h, 0)).y
	var rear_top := project_base(Vector3(0, h, d)).y
	var top := front_top if ceiling_emphasis else lerpf(front_top, rear_top, 0.65)
	var bounds := Rect2(Vector2(project_base(Vector3(-w, h, d)).x, top), Vector2.ZERO)
	bounds = bounds.expand(Vector2(project_base(Vector3(w, h, d)).x, project_base(Vector3(0, 0, 0)).y))
	for item in world.furniture.values():
		bounds = bounds.merge(_item_bounds(item))
	for point in world.DESK_SLOTS:
		bounds = bounds.merge(_item_bounds(world.furniture[&"desk"], point))
	return bounds.grow(12)

func _face(points: Array[Vector3], owner: StringName, color: Color, depth: float, tie: float = 0) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(project(point))
	commands.append({"polygon": polygon, "owner": owner, "color": color, "depth": depth, "tie": tie,"world_points":points})

func _box_faces(box: Dictionary, cuts: Array[float]) -> void:
	var first_command := commands.size()
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
		if end.y < eye_height:
			_face([Vector3(p.x, end.y, a), Vector3(end.x, end.y, a), Vector3(end.x, end.y, b), Vector3(p.x, end.y, b)], owner, color.lightened(0.17), (a + b) / 2, end.y)
		if side_x * (p.x + end.x) > 0:
			_face([Vector3(side_x, p.y, a), Vector3(side_x, end.y, a), Vector3(side_x, end.y, b), Vector3(side_x, p.y, b)], owner, color.darkened(0.18), (a + b) / 2, -absf(side_x))
	if is_instance_valid(world.encounter):
		for index in range(first_command,commands.size()):
			var command: Dictionary = commands[index]
			command.texture = "home.fabric" if owner == &"bed" and p.y >= 0.5 and p.y < 0.8 else "home.wood"
			var uv := PackedVector2Array()
			var points: Array = command.world_points
			var top_face: bool = is_equal_approx(points[0].y,points[1].y) and is_equal_approx(points[0].y,points[2].y)
			var side_face: bool = is_equal_approx(points[0].x,points[1].x) and is_equal_approx(points[0].x,points[2].x)
			for point in points:
				if top_face:
					uv.append(Vector2((point.x-p.x)/box.size.x,(point.z-p.z)/box.size.z))
				elif side_face:
					uv.append(Vector2((point.z-p.z)/box.size.z,1-(point.y-p.y)/box.size.y))
				else:
					uv.append(Vector2((point.x-p.x)/box.size.x,1-(point.y-p.y)/box.size.y))
			command.uv = uv
			command.color = Color(1.04,1.02,0.98) if top_face else (Color(0.74,0.72,0.68) if side_face else Color(0.94,0.91,0.85))

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
			if commands[i].get("texture","") == "cat" and not _sprite_hit(commands[i],point):
				continue
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
	if composition != "ribbon":
		_legacy_gui_input(event)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down = true
			_dragging = false
			_gesture_cancelled = false
			_press_position = event.position
			_press_camera_x = browse_center_x
			_press_scale = view_scale
			_pressed_id = pick(event.position)
			_pressed_revision = view_revision
		else:
			var id := _pressed_id
			var activate := _pointer_down and not _dragging and not _gesture_cancelled and _pressed_revision == view_revision and pick(event.position) == id
			_cancel_pointer()
			if activate and id != &"":
				selected_id = id
				object_selected.emit(id)
			elif activate and world.is_hunt_active():
				empty_tapped.emit()
		accept_event()
	elif event is InputEventMouseMotion and _pointer_down:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return
		var delta: Vector2 = event.position - _press_position
		if not _dragging and not _gesture_cancelled and delta.length() >= DRAG_THRESHOLD:
			_dragging = absf(delta.x) >= absf(delta.y)
			_gesture_cancelled = not _dragging
		if _dragging:
			browse_center_x = clampf(_press_camera_x - delta.x / _press_scale, pan_limits.x, pan_limits.y)
			_browse_position_set = true
			rebuild(true)
		accept_event()

func _cancel_pointer() -> void:
	_pointer_down = false
	_pressed_id = &""
	_pressed_revision = -1
	_dragging = false
	_gesture_cancelled = false

func _legacy_gui_input(event: InputEvent) -> void:
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
	if is_instance_valid(world.encounter) and P1Art.texture("home.background"):
		draw_rect(Rect2(Vector2.ZERO,size),Color("cbb28e"))
		var left := project(Vector3(-world.room_half_width,world.room_height,world.room_depth))
		left.y = minf(0.0,left.y)
		var right := Vector2(project(Vector3(world.room_half_width,0,world.room_depth)).x,project(Vector3(0,0,world.room_front)).y)
		# Room-space rectangle: panning and window changes use the same projection.
		GameUI.draw_cover(self,P1Art.texture("home.background"),Rect2(left,Vector2(right.x-left.x,right.y-left.y)))
	else:
		_room_shell()
		if composition == "ribbon":
			_architecture()
	for command in commands:
		var texture: Texture2D = P1Art.texture(command.get("texture",""))
		if texture:
			draw_polygon(command.polygon,PackedColorArray([command.color]),command.uv,texture)
		else:
			draw_colored_polygon(command.polygon, command.color)
	if is_instance_valid(world.encounter):
		_draw_furniture_details()

func _sprite_hit(command: Dictionary, point: Vector2) -> bool:
	var image := P1Art.alpha_image("cat")
	if image == null:
		return true
	var bounds := Rect2(command.polygon[0],Vector2.ZERO)
	for vertex in command.polygon:
		bounds = bounds.expand(vertex)
	var uv: Vector2 = (point-bounds.position)/bounds.size
	var uv_min := Vector2(1,1)
	var uv_max := Vector2.ZERO
	for vertex in command.uv:
		uv_min = uv_min.min(vertex)
		uv_max = uv_max.max(vertex)
	uv = uv_min + uv*(uv_max-uv_min)
	return image.get_pixel(clampi(int(uv.x*image.get_width()),0,image.get_width()-1),clampi(int(uv.y*image.get_height()),0,image.get_height()-1)).a > 0.15

func _draw_furniture_details() -> void:
	# Small original hardware lines follow world objects, no new collision objects.
	var cupboard: Vector2 = world.furniture[&"wardrobe"].floor_position
	for offset in [-0.11,0.11]:
		draw_line(project(Vector3(cupboard.x+offset,0.95,cupboard.y-0.008)),project(Vector3(cupboard.x+offset,1.18,cupboard.y-0.008)),Color("5f4930"),maxf(2,view_scale*3),true)

func _room_polygon(points: Array[Vector3], color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(project(point))
	var clip := shell_clip_rect()
	var boundary := PackedVector2Array([clip.position, Vector2(clip.end.x, clip.position.y), clip.end, Vector2(clip.position.x, clip.end.y)])
	for visible in Geometry2D.intersect_polygons(polygon, boundary):
		draw_colored_polygon(visible, color)
		visible.append(visible[0])
		draw_polyline(visible, Color("566970"), maxf(1.0, view_scale * 2.0), true)

func shell_clip_rect() -> Rect2:
	# Keep the weak-ceiling crop meaningful even in a tall letterboxed canvas.
	var top := maxf(0, size.y / 2 + (overview_bounds.position.y - focus_y) * view_scale) if effective_framing() == "overview" else 0.0
	return Rect2(Vector2(0, top), Vector2(size.x, size.y - top))

func _room_shell() -> void:
	var w := world.room_half_width
	var d := world.room_depth
	var h := world.room_height
	var front := world.room_front
	_room_polygon([Vector3(-w, 0, d), Vector3(w, 0, d), Vector3(w, h, d), Vector3(-w, h, d)], Color("deded4"))
	_room_polygon([Vector3(-w, 0, front), Vector3(-w, 0, d), Vector3(-w, h, d), Vector3(-w, h, front)], Color("a6b3b8"))
	_room_polygon([Vector3(w, 0, d), Vector3(w, 0, front), Vector3(w, h, front), Vector3(w, h, d)], Color("bdc7c5"))
	_room_polygon([Vector3(-w, 0, front), Vector3(w, 0, front), Vector3(w, 0, d), Vector3(-w, 0, d)], Color("c8c3b5"))
	# The ceiling shares exactly the same rear/side seam vertices as the walls.
	_room_polygon([Vector3(-w, h, front), Vector3(-w, h, d), Vector3(w, h, d), Vector3(w, h, front)], Color("b8bdb7") if ceiling_emphasis else Color("d1d4cc"))
	for x in range(-int(w), int(w)):
		draw_line(project(Vector3(x + 0.5, 0, front)), project(Vector3(x + 0.5, 0, d)), Color("a6a69c"), maxf(0.7, view_scale), true)
	for depth in [1.0, 2.0, 3.0, 4.0, 5.0]:
		draw_line(project(Vector3(-w, 0, depth)), project(Vector3(w, 0, depth)), Color("a6a69c"), maxf(0.7, view_scale), true)

func _architecture() -> void:
	# Original gray geometry only: three repeated wall bays and overhead beams.
	# These planes stay behind all furniture and have no interactive hotspots.
	var d := world.room_depth - 0.02
	var h := world.room_height
	var w := world.room_half_width
	_room_polygon([Vector3(-w, 0.05, d), Vector3(w, 0.05, d), Vector3(w, 0.7, d), Vector3(-w, 0.7, d)], Color("aeb8b2"))
	for x in [-3.8, 0.0, 3.8]:
		_room_polygon([Vector3(x - 1.12, 1.05, d), Vector3(x + 1.12, 1.05, d), Vector3(x + 1.12, 2.6, d), Vector3(x - 1.12, 2.6, d)], Color("b7c9cc"))
		for ends in [[Vector3(x, 1.05, d), Vector3(x, 2.6, d)], [Vector3(x - 1.12, 1.85, d), Vector3(x + 1.12, 1.85, d)]]:
			draw_line(project(ends[0]), project(ends[1]), Color("6b8185"), maxf(2, view_scale * 4), true)
	for x in [-2.0, 2.0]:
		_room_polygon([Vector3(x - 0.06, 0, d - 0.01), Vector3(x + 0.06, 0, d - 0.01), Vector3(x + 0.06, h, d - 0.01), Vector3(x - 0.06, h, d - 0.01)], Color("879b99"))
	for z in [-0.4, 2.2, 4.6]:
		_room_polygon([Vector3(-w, h - 0.1, z), Vector3(w, h - 0.1, z), Vector3(w, h - 0.1, z + 0.16), Vector3(-w, h - 0.1, z + 0.16)], Color("8f9f9c"))
