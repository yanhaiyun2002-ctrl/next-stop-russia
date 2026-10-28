extends "res://tests/dormitory_tests.gd"
## P0-03V uses the existing independent ray/pixel oracle, not a new sorter.
var measurements: Array[Dictionary] = []

func _run() -> void:
	if not OS.get_environment("P0_EVIDENCE_DIR").is_empty():
		evidence = OS.get_environment("P0_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	create_timer(180).timeout.connect(func():
		push_error("P0_COMPOSITION_TIMEOUT")
		quit(124))
	app = MAIN.instantiate()
	root.add_child(app)
	await _settle()
	app.enter_building(&"dormitory")
	await _settle()
	room = app.active_room
	view = room.room_view
	world = room.world
	# This is the preserved V suite; R/default drag coverage is separate.
	view.set_composition("compact")
	await _settle()
	view.object_selected.connect(func(id): selected.append(id))
	_check(not room.debug_panel.visible and view.effective_framing() == "overview", "进入宿舍先完整展示，调试默认收起")
	var world_id := world.get_instance_id()
	var furniture_ids: Array[int] = []
	var positions: Array[Vector2] = []
	for item in world.furniture.values():
		furniture_ids.append(item.get_instance_id())
		positions.append(item.floor_position)
	for pixels in [Vector2i(1920, 1080), Vector2i(1280, 800)]:
		await _resize(pixels)
		for composition in ["original", "balanced", "compact"]:
			view.set_composition(composition)
			for ceiling in [true, false]:
				view.set_ceiling_emphasis(ceiling)
				var label := "pc_%dx%d_%s_%s" % [pixels.x, pixels.y, composition, "ceiling" if ceiling else "soft"]
				await _case(label)
	# Isolate eye-height, holding compact room dimensions/distance fixed.
	await _resize(Vector2i(1920, 1080))
	view.set_composition("compact")
	view.eye_height = 1.5
	view.set_ceiling_emphasis(true)
	await _case("pc_compact_eye150_ceiling")
	view.set_composition("compact")
	for pixels in [Vector2i(1080, 1920), Vector2i(1170, 2532), Vector2i(360, 780)]:
		await _resize(pixels)
		for scheme in ["A", "B"]:
			room.set_phone_scheme(scheme)
			for ceiling in [true, false]:
				view.set_ceiling_emphasis(ceiling)
				await _case("phone_%dx%d_%s_%s_entry" % [pixels.x, pixels.y, scheme, "ceiling" if ceiling else "soft"])
			view.set_ceiling_emphasis(true)
			for id in [&"bed", &"desk", &"wardrobe"]:
				view.frame_object("overview")
				await _settle()
				var before := selected.size()
				var point := view.visible_point(id)
				await _touch(view.global_position + point)
				_check(selected.size() == before + 1 and selected.back() == id, "全景合成触摸单次命中 %s %s %s" % [pixels, scheme, id])
				_check(view.effective_framing() == ("overview" if scheme == "A" else String(id)), "手机方案点击策略 %s %s %s" % [pixels, scheme, id])
				# Named 48-unit buttons are an accessible alternative to thin legs.
				if scheme == "A":
					await _click(room.focus_button.get_global_rect().get_center())
					_check(view.effective_framing() == String(id), "A 可明确按聚焦放大已选家具 %s %s" % [pixels, id])
				await _case("phone_%dx%d_%s_focus_%s" % [pixels.x, pixels.y, scheme, id], false)
				await _click(room.overview_button.get_global_rect().get_center())
				_check(view.effective_framing() == "overview", "常驻全景一键返回 %s %s %s" % [pixels, scheme, id])
			# Actual named-button touch path is also tested, not only tiny surfaces.
			for index in range(3):
				var button: Button = room.selection_bar.get_child(index)
				await _touch(button.get_global_rect().get_center())
				_check(room.selected_furniture == [&"bed", &"desk", &"wardrobe"][index], "具名触摸入口 %s %s %s" % [pixels, scheme, index])
				await _click(room.overview_button.get_global_rect().get_center())
		await _click(room.debug_button.get_global_rect().get_center())
		_check(room.debug_panel.visible, "真实控件展开测试面板 %s" % pixels)
		await _settle()
		for button in room.controls.get_children():
			_check(_on_screen(button), "测试操作仍可访问 %s %s" % [pixels, button.text])
		var count := room.interaction_count
		await _click(room.action_button.get_global_rect().get_center())
		_check(room.interaction_count == count + 1, "展开后可移动标记 %s" % pixels)
		await _click(room.swap_button.get_global_rect().get_center())
		_check(world.desk_slot == 1, "展开后可换位 %s" % pixels)
		await _sample_scene("portrait_desk_front_%s" % pixels)
		world.toggle_desk()
		world.set_marker(world.MARKER_POINTS[0])
		await _capture("debug_expanded_%dx%d" % [pixels.x, pixels.y])
		await _click(room.debug_button.get_global_rect().get_center())
		_check(not room.debug_panel.visible, "收起测试面板恢复画布 %s" % pixels)
	_check(world.get_instance_id() == world_id, "横竖屏与两方案未复制房间实例")
	var index := 0
	for item in world.furniture.values():
		_check(item.get_instance_id() == furniture_ids[index] and item.floor_position == positions[index], "家具 %s 实例/数据共享" % item.furniture_id)
		index += 1
	await _resize(Vector2i(1170, 2532))
	app.safe_layout.safe_override_pixels = Rect2(0, 150, 1170, 2280)
	app.safe_layout.refresh()
	view.frame_object("overview")
	await _settle()
	_check(_on_screen(view) and _on_screen(room.back_button), "模拟安全区内全景和返回")
	await _case("phone_simulated_safe_area", false)
	app.safe_layout.safe_override_pixels = Rect2(-1, -1, 0, 0)
	var map_id: int = app.map_view.get_instance_id()
	await _click(room.back_button.get_global_rect().get_center())
	_check(app.active_room == null and app.map_view.get_instance_id() == map_id, "构图实验结束可返回同一地图")
	_check(root.gui_get_focus_owner() == app.map_view.buttons[&"dormitory"] and app.safe_layout.get_child_count() == 1, "返回焦点恢复且无空间节点残留")
	var output := FileAccess.open(evidence.path_join("composition_results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(), "passed": passed, "failed": failed,
		"checks": checks, "measurements": measurements, "screenshots": captures, "ray_samples": samples,
		"scope": "Windows rendered/synthetic touch only; no human playtest or mobile device validation"}, "\t"))
	output.close()
	print("P0_COMPOSITION_RESULT passed=%d failed=%d display=%s" % [passed, failed, DisplayServer.get_name()])
	app.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)

func _resize(pixels: Vector2i) -> void:
	root.size = pixels
	app.safe_layout.refresh()
	await _settle()

func _case(label: String, oracle := true) -> void:
	await _settle()
	_check(_on_screen(view) and _on_screen(room.selection_bar) and _on_screen(room.feedback), "画布/常驻控件/反馈不溢出 " + label)
	for button in room.selection_bar.get_children():
		_check(button.size.x >= 48 and button.size.y >= 48, "常驻触摸按钮至少 48 单位 %s %s" % [label, button.text])
	var furniture := {}
	for id in world.furniture:
		var item: GrayboxFurniture = world.furniture[id]
		var bounds: Rect2 = view._item_bounds(item)
		var a := view.size / 2 + (bounds.position - Vector2(view.focus_x, view.focus_y)) * view.view_scale
		var rect := Rect2(a, bounds.size * view.view_scale)
		furniture[String(id)] = {"rect": str(rect), "width": rect.size.x, "height": rect.size.y, "visible": view.visible_point(id).x >= 0}
		if view.effective_framing() == "overview":
			_check(Rect2(Vector2.ZERO, view.size).encloses(rect) and view.visible_point(id).x >= 0, "全景家具完整可见 %s %s" % [label, id])
	var w := world.room_half_width
	var d := world.room_depth
	var h := world.room_height
	var roof := PackedVector2Array([view.project(Vector3(-w, h, 0)), view.project(Vector3(-w, h, d)), view.project(Vector3(w, h, d)), view.project(Vector3(w, h, 0))])
	var clip := view.shell_clip_rect()
	var screen := PackedVector2Array([clip.position, Vector2(clip.end.x, clip.position.y), clip.end, Vector2(clip.position.x, clip.end.y)])
	var clipped := Geometry2D.intersect_polygons(roof, screen)
	var area := 0.0
	for polygon in clipped:
		for i in range(polygon.size()):
			area += polygon[i].cross(polygon[(i + 1) % polygon.size()]) / 2
	area = absf(area)
	if view.effective_framing() == "overview":
		_check(area > 0 and area / (view.size.x * view.size.y) < 0.3, "全景天花板可见且占画布不足三成 " + label)
	var pixel_total := 0
	var pixel_roof := 0
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var roof_color := Color("b8bdb7") if view.ceiling_emphasis else Color("d1d4cc")
		for x in range(3, int(view.size.x), 7):
			for y in range(3, int(view.size.y), 7):
				var p := Vector2i(root.get_final_transform() * (view.global_position + Vector2(x, y)))
				var color := picture.get_pixelv(p)
				pixel_total += 1
				if Vector3(color.r - roof_color.r, color.g - roof_color.g, color.b - roof_color.b).length() < 0.01:
					pixel_roof += 1
		if view.effective_framing() == "overview":
			_check(pixel_roof > 0, "真实渲染存在天花板平面像素 " + label)
	measurements.append({"scene": label, "window": str(root.size), "scheme": room.phone_scheme, "composition": view.composition,
		"room": [w * 2, d, h], "eye_height": view.eye_height, "camera_distance": view.camera_distance, "focal": view.focal,
		"ceiling_emphasis": view.ceiling_emphasis, "framing": view.effective_framing(), "debug_visible": room.debug_panel.visible,
		"canvas": str(view.size), "overview_bounds": str(view.overview_bounds), "scale": view.view_scale,
		"ceiling_screen_fraction": area / (view.size.x * view.size.y), "sampled_canvas_pixels": pixel_total, "sampled_ceiling_pixels": pixel_roof, "furniture": furniture})
	if "_soft" in label:
		var previous := label.replace("_soft", "_ceiling")
		for measured in measurements:
			if measured.scene == previous:
				_check(area / (view.size.x * view.size.y) < measured.ceiling_screen_fraction, "弱化方案确实减少天花板可见面积 " + label)
				if pixel_total > 0:
					_check(float(pixel_roof) / pixel_total < float(measured.sampled_ceiling_pixels) / measured.sampled_canvas_pixels, "弱化方案真实天花板像素占比下降 " + label)
	await _capture(label)
	if oracle:
		await _sample_scene(label)
