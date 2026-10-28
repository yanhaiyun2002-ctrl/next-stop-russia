extends SceneTree
## P0-03 tests the real main scene. Ray/AABB oracle is independent of face sorting.
const MAIN = preload("res://scenes/main.tscn")
var app: Control
var room: BuildingRoom
var view: DormitoryView
var world: DormitoryWorld
var passed := 0
var failed := 0
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var selected: Array[StringName] = []
var evidence := "res://docs/evidence/p0-03/spatial"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not OS.get_environment("P0_EVIDENCE_DIR").is_empty():
		evidence = OS.get_environment("P0_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	create_timer(120).timeout.connect(func():
		push_error("P0_SPATIAL_TIMEOUT")
		quit(124))
	app = MAIN.instantiate()
	app.technical_mode = true
	root.add_child(app)
	await _settle()
	var map_id: int = app.map_view.get_instance_id()
	_check(app.enter_building(&"dormitory"), "从稳定宿舍 ID 请求进入")
	await _settle()
	room = app.active_room
	view = room.room_view
	world = room.world
	# Replay the retained V fixture: its coordinate-specific assertions remain.
	view.set_composition("compact")
	await _settle()
	view.object_selected.connect(func(id): selected.append(id))
	_check(room is BuildingRoom and world.furniture.size() == 3, "BuildingRoom 合同和三家具独立节点")
	_check(world.get_child_count() == 3 and not _has_3d(room), "原生 2D 场景，无 Node3D")
	for pixels in [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1080, 1920), Vector2i(1170, 2532), Vector2i(360, 780)]:
		room.set_debug_visible(true)
		root.size = pixels
		app.safe_layout.refresh()
		view.framing = "auto"
		await _settle()
		view.rebuild()
		await _settle()
		var label := "%dx%d" % [pixels.x, pixels.y]
		_check(root.size == pixels, "实际窗口尺寸 " + label)
		_check(_on_screen(view) and view.size.x >= 260 and view.size.y >= 220, "展开测试面板时空间视图未溢出 " + label)
		_check(_on_screen(room.back_button) and _on_screen(room.feedback), "返回与反馈可见 " + label)
		_check(room.controls.columns == (3 if pixels.y > pixels.x else 6), "独立横竖屏 UI 重排 " + label)
		for button in room.controls.get_children() + room.selection_bar.get_children():
			_check(_on_screen(button) and button.size.x >= 48 and button.size.y >= 48, "控件可见且至少 48 单位 %s %s" % [label, button.text])
		await _capture("room_auto_" + label)
		for id in [&"bed", &"desk", &"wardrobe"]:
			if pixels.y > pixels.x:
				view.frame_object(String(id))
			await _settle()
			var point := view.visible_point(id)
			_check(point.x >= 0 and _oracle(point) == id, "可见表面可点击 %s %s" % [label, id])
			var before := selected.size()
			await _click(view.global_position + point)
			_check(selected.size() == before + 1 and selected.back() == id, "鼠标仅命中可见家具 %s %s" % [label, id])
			before = selected.size()
			await _touch(view.global_position + point)
			_check(selected.size() == before + 1 and selected.back() == id, "合成触摸单次命中 %s %s" % [label, id])
			if pixels == Vector2i(360, 780):
				await _capture("portrait_focus_" + String(id))
		view.frame_object("overview")
		await _settle()
		for id in [&"bed", &"desk", &"wardrobe"]:
			_check(view.visible_point(id).x >= 0, "全景可找回家具 %s %s" % [label, id])
		await _sample_scene("overview_" + label)
		if pixels.y > pixels.x:
			await _capture("room_overview_" + label)
		view.pan(1.0)
		await _settle()
		_check(view.effective_framing() == "desk" and view.focus_x <= view.overview_bounds.end.x, "受约束横移可用 " + label)
		view.frame_object("overview")
		_check(is_equal_approx(view.focus_x, view.overview_bounds.get_center().x) and view.pan_offset == 0, "明确返回全景 " + label)
	root.size = Vector2i(1920, 1080)
	app.safe_layout.refresh()
	view.frame_object("overview")
	await _settle()
	world.set_marker(Vector2(-1.7, 0.85))
	await _settle()
	var front := view.project(Vector3(-1.7, 0.74, 0.85))
	_check(view.pick(front) == &"marker" and _oracle(front) == &"marker", "床前标记头部可见")
	await _sample_scene("marker_front_bed")
	await _capture("marker_front_bed")
	world.set_marker(Vector2(-1.7, 3.6))
	await _settle()
	var back := view.project(Vector3(-1.7, 0.74, 3.6))
	_check(view.pick(back) == &"bed" and _oracle(back) == &"bed", "床后标记头部被床遮挡且不穿透拾取")
	await _sample_scene("marker_behind_bed")
	await _capture("marker_behind_bed")
	world.set_marker(Vector2(0.35, 4.35))
	await _settle()
	var gap := view.project(Vector3(0.35, 0.40, 4.35))
	_check(view.pick(gap) == &"marker" and _oracle(gap) == &"marker", "桌腿之间为真实空隙，无包围矩形误挡")
	await _sample_scene("marker_desk_gap")
	await _capture("marker_desk_gap")
	# One stationary marker and the same camera: furniture motion must change coverage.
	world.set_marker(Vector2(-0.45, 1.6))
	await _settle()
	# Lower eye/longer distance changes the line of sight: the head center now
	# remains under the desk. Its upper disk (y=.86) still crosses the tabletop.
	var stationary := view.project(Vector3(-0.45, 0.86, 1.6))
	_check(view.pick(stationary) == &"marker", "换位前固定标记可见")
	await _capture("desk_before_move")
	await _click(room.swap_button.get_global_rect().get_center())
	_check(world.desk_slot == 1 and world.furniture[&"desk"].floor_position == world.DESK_SLOTS[1], "真实 GUI 书桌换位")
	_check(view.pick(stationary) == &"desk" and _oracle(stationary) == &"desk", "换位后固定标记被桌面遮挡")
	_check(view.project(Vector3(-0.45, 0.86, 1.6)).is_equal_approx(stationary), "换位未移动镜头或标记坐标")
	_check(_overlap_point().x >= 0, "换位后确有书桌与床体的投影重叠且前桌优先")
	await _sample_scene("desk_front_overlap")
	await _capture("desk_front_overlap")
	_check(not world.move_furniture(&"unknown", Vector2.ZERO), "拒绝未知家具")
	_check(not world.move_furniture(&"desk", Vector2(9, 0)), "拒绝越出房间")
	_check(not world.move_furniture(&"desk", Vector2(-1.7, 1.4)), "拒绝家具实体相交")
	_check(world.furniture[&"desk"].floor_position == world.DESK_SLOTS[1], "拒绝移动后保留原状态")
	_check(world.toggle_desk() and world.desk_slot == 0, "书桌可返回后槽位")
	var boundary: Array[Dictionary] = []
	for depth in [1.15, 1.24, 1.26, 1.35, 1.5, 2.1, 3.32, 3.34, 3.6]:
		world.set_marker(Vector2(-1.7, depth))
		await _settle()
		var marker_head := view.project(Vector3(-1.7, 0.74, depth))
		var expected := _oracle(marker_head)
		_check(view.pick(marker_head) == expected, "标记跨床遮挡边界 z=%.2f" % depth)
		boundary.append({"depth": depth, "head_owner": String(expected)})
		if depth in [1.15, 2.1, 3.6]:
			await _capture("bed_boundary_z%.2f" % depth)
	samples.append({"trajectory": "bed depth boundary", "steps": boundary})
	for x in [-1.7, 0.35, 2.1]:
		for z in [0.85, 1.5, 2.7, 3.6, 4.35, 5.25]:
			world.set_marker(Vector2(x, z))
			await _sample_scene("depth_x%.2f_z%.2f" % [x, z], false)
	var old_marker := world.marker_position
	await _click(room.depth_button.get_global_rect().get_center())
	_check(world.marker_position != old_marker, "标记深度按钮更新位置")
	var old_count := room.interaction_count
	await _click(room.action_button.get_global_rect().get_center())
	_check(room.interaction_count == old_count + 1, "换点保留临时交互计数合同")
	# Reframing between down/up must never pick a changed surface.
	var point := view.visible_point(&"bed") + view.global_position
	var before := selected.size()
	_mouse_event(point, true)
	view.pan(1)
	_mouse_event(point, false)
	await _settle()
	_check(selected.size() == before, "镜头变化期间旧按下被取消")
	view.frame_object("overview")
	point = view.visible_point(&"bed") + view.global_position
	_mouse_event(point, true)
	_mouse_event(view.global_position + Vector2(3, 3), false)
	await _settle()
	_check(selected.size() == before, "拖离可见表面取消点击")
	_mouse_event(point, false)
	await _settle()
	_check(selected.size() == before, "取消后重复释放不会恢复旧点击")
	point = view.visible_point(&"bed") + view.global_position
	_mouse_event(point, true)
	root.size = Vector2i(360, 780)
	app.safe_layout.refresh()
	_mouse_event(point, false)
	await _settle()
	_check(selected.size() == before, "家具按下跨方向变化取消旧坐标释放")
	old_marker = world.marker_position
	root.size = Vector2i(1170, 2532)
	room.set_debug_visible(false)
	app.safe_layout.safe_override_pixels = Rect2(0, 150, 1170, 2280)
	app.safe_layout.refresh()
	view.framing = "auto"
	await _settle()
	var scale := minf(1170.0 / 360, 2532.0 / 780)
	var safe := Rect2(0, 150 / scale, 1170 / scale, 2280 / scale)
	_check(safe.encloses(view.get_global_rect()) and safe.encloses(room.debug_button.get_global_rect()), "模拟不对称安全区内空间与常驻控件")
	_check(world.marker_position == old_marker and world.desk_slot == 0, "方向和安全区变化保持空间状态")
	await _capture("portrait_simulated_safe_area")
	app.safe_layout.safe_override_pixels = Rect2(-1, -1, 0, 0)
	await _click(room.back_button.get_global_rect().get_center())
	_check(app.active_room == null and app.map_view.visible, "真实 GUI 返回地图")
	_check(app.map_view.get_instance_id() == map_id and app.map_view.selected_id == &"dormitory", "保留地图实例与宿舍选择")
	_check(root.gui_get_focus_owner() == app.map_view.buttons[&"dormitory"], "恢复宿舍导航焦点")
	_check(app.safe_layout.get_child_count() == 1, "退出宿舍无空间节点残留")
	for i in range(8):
		app.enter_building(&"dormitory")
		await _settle()
		_check(app.active_room.world.desk_slot == 0 and app.active_room.world.marker_index == 0, "重入仅建立当前灰盒状态 %d" % i)
		app.return_to_map()
		await _settle()
	_check(app.safe_layout.get_child_count() == 1, "八轮往返后无室内节点残留")
	var report := {"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(),
		"passed": passed, "failed": failed, "checks": checks, "screenshots": captures, "ray_samples": samples,
		"scope": "Windows viewport rendering and synthetic mouse/touch only; no device or human playtest"}
	var output := FileAccess.open(evidence.path_join("spatial_results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("P0_SPATIAL_RESULT passed=%d failed=%d display=%s" % [passed, failed, DisplayServer.get_name()])
	app.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)

func _ray_box(direction: Vector3, box: Dictionary) -> float:
	var origin := Vector3(0, view.eye_height, -view.camera_distance)
	var low := 0.0
	var high := INF
	for axis in range(3):
		if absf(direction[axis]) < 0.000001:
			if origin[axis] < box.origin[axis] or origin[axis] > box.origin[axis] + box.size[axis]:
				return INF
			continue
		var a: float = (box.origin[axis] - origin[axis]) / direction[axis]
		var b: float = (box.origin[axis] + box.size[axis] - origin[axis]) / direction[axis]
		low = maxf(low, minf(a, b))
		high = minf(high, maxf(a, b))
		if low > high:
			return INF
	return low

func _overlap_point() -> Vector2:
	for x in range(0, int(view.size.x), 5):
		for y in range(0, int(view.size.y), 5):
			var point := Vector2(x + 0.3, y + 0.7)
			var has_bed := false
			var has_desk := false
			for command in view.commands:
				if Geometry2D.is_point_in_polygon(point, command.polygon):
					has_bed = has_bed or command.owner == &"bed"
					has_desk = has_desk or command.owner == &"desk"
			if has_bed and has_desk and view.pick(point) == &"desk" and _oracle(point) == &"desk":
				return point
	return Vector2(-1, -1)

func _oracle(point: Vector2) -> StringName:
	# Invert the camera, intersect physical boxes; never inspect render commands.
	var base := (point - view.size / 2) / view.view_scale + Vector2(view.focus_x, view.focus_y)
	var direction := Vector3((base.x - view.HORIZON.x) / view.focal, -(base.y - view.HORIZON.y) / view.focal, 1)
	var near := INF
	var owner: StringName = &""
	for box in world.all_boxes():
		var hit := _ray_box(direction, box)
		if hit < near:
			near = hit
			owner = box.owner
	var depth := world.marker_position.y + view.camera_distance
	var x := direction.x * depth - world.marker_position.x
	var y := view.eye_height + direction.y * depth
	var head := Vector2(x, y - 0.74)
	# Circle's polygon boundary has a maximum 0.0012m discrepancy; exclude edges in sampling.
	var marker := (absf(x) < 0.055 and y >= 0.03 and y <= 0.73) or head.length() < 0.139
	marker = marker or (y >= 0 and y <= 0.07 and absf(x) <= 0.16 - y * 0.04 / 0.07)
	if marker and depth <= near:
		return &"marker"
	return owner

func _sample_scene(label: String, pixels: bool = true) -> void:
	await _settle()
	var picture: Image
	if pixels and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		picture = root.get_texture().get_image()
	var total := 0
	var mismatch: Array[String] = []
	var pixel_total := 0
	var pixel_mismatch: Array[String] = []
	var palette: Array[Dictionary] = []
	for box in world.all_boxes():
		for color in [box.color, box.color.lightened(0.17), box.color.darkened(0.18)]:
			palette.append({"owner": box.owner, "color": color})
	palette.append({"owner": &"marker", "color": view.MARKER_COLOR})
	for part in world.cat_parts():
		palette.append({"owner": &"cat", "color": part.color})
	for x in range(11, int(view.size.x) - 1, 19):
		for y in range(13, int(view.size.y) - 1, 17):
			var point := Vector2(x + 0.37, y + 0.63)
			var expected := _oracle(point)
			if _oracle(point + Vector2.ONE) != expected or _oracle(point - Vector2.ONE) != expected:
				continue
			total += 1
			if view.pick(point) != expected and mismatch.size() < 8:
				mismatch.append("%s expected=%s actual=%s" % [point, expected, view.pick(point)])
			if picture and expected != &"":
				var p := Vector2i(root.get_final_transform() * (view.global_position + point))
				var color := picture.get_pixelv(p)
				var actual: StringName = &""
				var distance := 0.035
				for entry in palette:
					var delta := Vector3(color.r - entry.color.r, color.g - entry.color.g, color.b - entry.color.b).length()
					if delta < distance:
						distance = delta
						actual = entry.owner
				pixel_total += 1
				if actual != expected and pixel_mismatch.size() < 8:
					pixel_mismatch.append("%s expected=%s color=%s owner=%s" % [point, expected, color, actual])
	samples.append({"scene": label, "rays": total, "first_mismatches": mismatch, "rendered_pixels": pixel_total, "first_pixel_mismatches": pixel_mismatch})
	_check(total > 40 and mismatch.is_empty(), "独立射线与可见面拾取一致 " + label + str(mismatch))
	if picture:
		_check(pixel_total > 10 and pixel_mismatch.is_empty(), "实际渲染像素与独立深度一致 " + label + str(pixel_mismatch))

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _settle()
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var filename := label + ".png"
	_check(picture.save_png(evidence.path_join(filename)) == OK and picture.get_size() == root.size, "保存实际渲染截图 " + label)
	captures.append({"path": filename, "window": str(root.size), "image": str(picture.get_size()), "logical": str(root.get_visible_rect().size),
		"view_rect": str(view.get_global_rect()), "framing": view.effective_framing(), "focus_x": view.focus_x,
		"scale": view.view_scale, "marker": str(world.marker_position), "desk_slot": world.desk_slot})

func _mouse_event(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = down
	root.push_input(event, true)

func _click(point: Vector2) -> void:
	await _settle()
	_mouse_event(point, true)
	_mouse_event(point, false)
	await _settle()

func _touch(point: Vector2) -> void:
	var physical := root.get_final_transform() * point
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = physical
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	await _settle()

func _settle() -> void:
	for i in range(6):
		await process_frame
	var deadline := Time.get_ticks_msec() + 3000
	while not app.safe_layout.is_layout_settled() or app.transitioning:
		if Time.get_ticks_msec() > deadline:
			_check(false, "空间布局三秒内稳定")
			return
		await process_frame

func _on_screen(control: Control) -> bool:
	return control.is_visible_in_tree() and root.get_visible_rect().encloses(control.get_global_rect())

func _has_3d(node: Node) -> bool:
	if node is Node3D:
		return true
	for child in node.get_children():
		if _has_3d(child):
			return true
	return false

func _check(condition: bool, label: String) -> void:
	checks.append({"name": label, "passed": condition})
	if condition:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)
