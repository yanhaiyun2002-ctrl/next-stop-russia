extends "res://tests/dormitory_tests.gd"
## R default-mode tests. V's coordinate fixtures are replayed separately.
var views: Array[Dictionary] = []
var drags: Array[Dictionary] = []

func _run() -> void:
	evidence = OS.get_environment("P0_EVIDENCE_DIR")
	if evidence.is_empty():
		evidence = "res://docs/evidence/p0-03r/ribbon"
	DirAccess.make_dir_recursive_absolute(evidence)
	create_timer(180).timeout.connect(func():
		push_error("P0_RIBBON_TIMEOUT")
		quit(124))
	app = MAIN.instantiate()
	root.add_child(app)
	await _settle()
	var map_instance: int = app.map_view.get_instance_id()
	_check(app.enter_building(&"dormitory"), "原宿舍 ID 加载新横向空间")
	await _settle()
	_bind_room()
	_check(view.composition == "ribbon" and world.layout_kind == "ribbon", "R 为真实默认入口")
	_check(not room.debug_panel.visible and not room.focus_button.visible, "默认收起测试，移除不必要聚焦入口")
	_check(world.furniture.size() == 3 and world.get_child_count() == 3 and not _has_3d(room), "三家具复用 2D，无额外场景/3D")
	var original_positions := _positions()
	var world_id := world.get_instance_id()
	for pixels in [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1080, 1920), Vector2i(1170, 2532), Vector2i(360, 780)]:
		root.size = pixels
		app.safe_layout.refresh()
		await _settle()
		await _click(room.overview_button.get_global_rect().get_center())
		var default_x := view.focus_x
		var default_scale := view.view_scale
		var label := "%dx%d" % [pixels.x, pixels.y]
		_check(view.effective_framing() == "browse" and view.pan_limits.x <= view.focus_x and view.focus_x <= view.pan_limits.y, "默认有界浏览 " + label)
		_check(view.view_scale >= 1 and view.size.x / view.view_scale < 1100, "不把整个横向房间缩入手机 " + label)
		if pixels.y > pixels.x:
			_check(view.size.x / view.view_scale < 400, "手机默认为足够大比例的局部 " + label)
		else:
			for id in [&"bed", &"desk", &"wardrobe"]:
				_check(view.visible_point(id).x >= 0, "PC 默认宽视野可读 %s %s" % [label, id])
		await _record_case(("phone_" if pixels.y > pixels.x else "pc_") + label + "_middle")
		await _sample_scene("middle_" + label)
		var count := selected.size()
		for i in range(7):
			await _drag(Vector2(view.size.x * 0.15, view.size.y * 0.65), Vector2(view.size.x * 0.7, 0), false)
		_check(is_equal_approx(view.focus_x, view.pan_limits.x), "拖到左侧边界 " + label)
		_check(selected.size() == count, "横拖不激活家具 " + label)
		_check(is_equal_approx(view.view_scale, default_scale), "横拖尺度不变 " + label)
		await _record_case(("phone_" if pixels.y > pixels.x else "pc_") + label + "_left")
		await _sample_scene("left_" + label)
		_check(view.visible_point(&"bed").x >= 0, "左侧床可见 " + label)
		_check(_item_on_screen(&"bed"), "左端床体范围完整可读 " + label)
		await _click_surface(&"bed", label)
		for i in range(7):
			await _drag(Vector2(view.size.x * 0.85, view.size.y * 0.65), Vector2(-view.size.x * 0.7, 0), true)
		_check(is_equal_approx(view.focus_x, view.pan_limits.y), "合成触摸拖到右侧边界 " + label)
		await _record_case(("phone_" if pixels.y > pixels.x else "pc_") + label + "_right")
		await _sample_scene("right_" + label)
		_check(view.visible_point(&"wardrobe").x >= 0, "右侧衣柜可见 " + label)
		_check(_item_on_screen(&"wardrobe"), "右端衣柜范围完整可读 " + label)
		await _click_surface(&"wardrobe", label)
		await _click(room.overview_button.get_global_rect().get_center())
		_check(is_equal_approx(view.focus_x, default_x), "简单复位返回默认取景 " + label)
		_check(_positions() == original_positions and world.get_instance_id() == world_id, "横竖屏相机不移动/复制家具 " + label)
		for index in range(3):
			var id: StringName = [&"bed", &"desk", &"wardrobe"][index]
			var button: Button = room.selection_bar.get_child(index)
			await _touch(button.get_global_rect().get_center())
			_check(view.visible_point(id).x >= 0 and room.selected_furniture == id, "具名按钮平移至家具 %s %s" % [label, id])
			_check(is_equal_approx(view.view_scale, default_scale), "具名浏览不额外缩放 %s %s" % [label, id])
	# Gesture threshold and cancellation at the smallest requested viewport.
	view.frame_object("bed")
	await _settle()
	var point := _interior_point(&"bed")
	_check(point.x >= 0, "床体有可测的内部触摸区域")
	var before := selected.size()
	var camera := view.focus_x
	await _drag(point, Vector2(3, 0), false)
	_check(selected.size() == before + 1 and selected.back() == &"bed" and is_equal_approx(view.focus_x, camera), "小幅抖动仍为一次点击")
	before = selected.size()
	await _drag(point, Vector2(0, 40), false)
	_check(selected.size() == before and is_equal_approx(view.focus_x, camera), "竖向移动取消点击且不横移")
	await _drag(point, Vector2(70, 0), false)
	_check(selected.size() == before, "家具上开始横拖也不点击")
	_mouse_event(view.global_position + point, false)
	await _settle()
	_check(selected.size() == before, "拖动后重复释放不激活")
	view.frame_object("bed")
	await _settle()
	point = _interior_point(&"bed")
	_mouse_event(view.global_position + point, true)
	view.pan(1)
	_mouse_event(view.global_position + point, false)
	await _settle()
	_check(selected.size() == before and not view._pointer_down, "外部取景变化取消旧按下")
	_mouse_event(view.global_position + Vector2(100, 100), true)
	root.size = Vector2i(1280, 800)
	app.safe_layout.refresh()
	_mouse_event(view.global_position + Vector2(100, 100), false)
	await _settle()
	_check(not view._pointer_down and selected.size() == before, "方向变化取消未释放的浏览手势")
	# New-layout occlusion, keeping camera fixed within each comparison.
	root.size = Vector2i(1920, 1080)
	app.safe_layout.refresh()
	await _settle()
	view.reset_browse()
	world.set_marker(Vector2(-3.4, 0.85))
	await _settle()
	var probe := view.project(Vector3(-3.4, 0.74, 0.85))
	_check(view.pick(probe) == &"marker" and _oracle(probe) == &"marker", "新前景床前标记可见")
	await _record_case("occlusion_bed_front")
	await _sample_scene("occlusion_bed_front")
	world.set_marker(Vector2(-3.4, 3.6))
	await _settle()
	probe = view.project(Vector3(-3.4, 0.74, 3.6))
	_check(view.pick(probe) == &"bed" and _oracle(probe) == &"bed", "新床后遮挡及热点不穿透")
	await _record_case("occlusion_bed_back")
	await _sample_scene("occlusion_bed_back")
	world.set_marker(Vector2(0, 4.35))
	await _settle()
	probe = view.project(Vector3(0, 0.4, 4.35))
	_check(view.pick(probe) == &"marker" and _oracle(probe) == &"marker", "中景桌腿空隙仍可见")
	await _record_case("occlusion_desk_gap")
	await _sample_scene("occlusion_desk_gap")
	world.set_marker(Vector2(-2.0, 1.6))
	await _settle()
	probe = view.project(Vector3(-2.0, 0.86, 1.6))
	_check(view.pick(probe) == &"marker", "换位前标记上缘可见")
	await _record_case("desk_before_move")
	await _click(room.debug_button.get_global_rect().get_center())
	await _click(room.swap_button.get_global_rect().get_center())
	await _click(room.debug_button.get_global_rect().get_center())
	probe = view.project(Vector3(-2.0, 0.86, 1.6))
	_check(world.desk_slot == 1 and view.pick(probe) == &"desk" and _oracle(probe) == &"desk", "新前景换位更新遮挡")
	await _record_case("desk_front_overlap")
	await _sample_scene("desk_front_overlap")
	_check(not world.move_furniture(&"unknown", Vector2.ZERO), "新布局拒绝未知家具")
	_check(not world.move_furniture(&"desk", Vector2(9, 0)), "新布局拒绝越界")
	_check(not world.move_furniture(&"desk", Vector2(-3.4, 1.4)), "新布局拒绝家具相交")
	world.toggle_desk()
	world.set_marker(Vector2(3.5, 5.25))
	await _settle()
	probe = view.project(Vector3(3.5, 0.74, 5.25))
	_check(view.pick(probe) == &"wardrobe" and _oracle(probe) == &"wardrobe", "后景衣柜遮挡标记")
	await _sample_scene("occlusion_wardrobe_back")
	root.size = Vector2i(1170, 2532)
	app.safe_layout.safe_override_pixels = Rect2(0, 150, 1170, 2280)
	app.safe_layout.refresh()
	await _settle()
	view.reset_browse()
	var scale := minf(1170.0 / 360, 2532.0 / 780)
	var safe := Rect2(0, 150 / scale, 1170 / scale, 2280 / scale)
	_check(safe.encloses(view.get_global_rect()) and safe.encloses(room.selection_bar.get_global_rect()) and safe.encloses(room.back_button.get_global_rect()), "模拟安全区保护浏览区域和常驻 UI")
	await _record_case("phone_simulated_safe_area")
	app.safe_layout.safe_override_pixels = Rect2(-1, -1, 0, 0)
	app.safe_layout.refresh()
	await _settle()
	for i in range(4):
		await _click(room.back_button.get_global_rect().get_center())
		_check(app.active_room == null and app.map_view.get_instance_id() == map_instance and root.gui_get_focus_owner() == app.map_view.buttons[&"dormitory"], "返回同一地图并恢复焦点 %d" % i)
		_check(app.safe_layout.get_child_count() == 1, "退出无横向空间节点残留 %d" % i)
		await _click(app.map_view.buttons[&"dormitory"].get_global_rect().get_center())
		_bind_room()
		_check(view.composition == "ribbon" and is_equal_approx(view.focus_x, 640) and not view._pointer_down and world.desk_slot == 0, "重入默认中部且无旧手势 %d" % i)
	var output := FileAccess.open(evidence.path_join("ribbon_results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(), "passed": passed, "failed": failed,
		"checks": checks, "views": views, "screenshots": captures, "ray_samples": samples, "drags": drags,
		"scope": "Actual Godot viewport / synthetic mouse and touch. No Android device or human playtest."}, "\t"))
	output.close()
	print("P0_RIBBON_RESULT passed=%d failed=%d display=%s" % [passed, failed, DisplayServer.get_name()])
	app.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)

func _bind_room() -> void:
	room = app.active_room
	view = room.room_view
	world = room.world
	view.object_selected.connect(func(id): selected.append(id))

func _positions() -> Array:
	var result: Array = []
	for item in world.furniture.values():
		result.append([item.get_instance_id(), item.floor_position, item.dimensions])
	return result

func _item_on_screen(id: StringName) -> bool:
	var bounds := view._item_bounds(world.furniture[id])
	var start := view.size / 2 + (bounds.position - Vector2(view.focus_x, view.focus_y)) * view.view_scale
	return Rect2(Vector2.ZERO, view.size).encloses(Rect2(start, bounds.size * view.view_scale))

func _click_surface(id: StringName, label: String) -> void:
	var point := view.visible_point(id)
	var before := selected.size()
	var camera := view.focus_x
	await _click(view.global_position + point)
	_check(selected.size() == before + 1 and selected.back() == id, "移动后鼠标热点对应 %s %s" % [label, id])
	before = selected.size()
	await _touch(view.global_position + point)
	_check(selected.size() == before + 1 and selected.back() == id, "移动后合成触摸单次对应 %s %s" % [label, id])
	_check(is_equal_approx(view.focus_x, camera), "点击家具不跳镜头 %s %s" % [label, id])

func _interior_point(id: StringName) -> Vector2:
	for x in range(8, int(view.size.x) - 8, 5):
		for y in range(8, int(view.size.y) - 8, 5):
			var point := Vector2(x, y)
			var valid := true
			for delta in [Vector2.ZERO, Vector2(6, 0), Vector2(-6, 0), Vector2(0, 6), Vector2(0, -6)]:
				valid = valid and view.pick(point + delta) == id
			if valid:
				return point
	return Vector2(-1, -1)

func _drag(local: Vector2, delta: Vector2, touch: bool) -> void:
	await _settle()
	var start := view.global_position + local
	var start_camera := view.focus_x
	var scale := view.view_scale
	var anchor := Vector3(-1.1, 0.7, 2.5)
	var initial := view.project(anchor)
	var steps: Array = []
	var continuous := true
	if touch:
		var press := InputEventScreenTouch.new()
		press.index = 0
		press.pressed = true
		press.position = root.get_final_transform() * start
		Input.parse_input_event(press)
		# Touch->mouse emulation is delivered on the engine frame, not before
		# parse_input_event returns. Observe delivered states, not queued input.
		await process_frame
		await process_frame
	else:
		_mouse_event(start, true)
	for i in range(1, 9):
		var position := start + delta * i / 8.0
		if touch:
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.position = root.get_final_transform() * position
			drag.relative = root.get_final_transform().basis_xform(delta / 8)
			Input.parse_input_event(drag)
			await process_frame
			await process_frame
		else:
			var motion := InputEventMouseMotion.new()
			motion.position = position
			motion.relative = delta / 8
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(motion, true)
		steps.append({"camera": view.focus_x, "screen_anchor": str(view.project(anchor)), "scale": view.view_scale})
		var expected := start_camera
		if absf(delta.x) >= absf(delta.y) and delta.length() * i / 8 >= view.DRAG_THRESHOLD:
			expected = clampf(start_camera - delta.x * i / 8 / scale, view.pan_limits.x, view.pan_limits.y)
		var screen_shift := view.project(anchor) - initial
		continuous = continuous and absf(view.focus_x - expected) < 0.02 and absf(screen_shift.x + (view.focus_x - start_camera) * scale) < 0.02 and absf(screen_shift.y) < 0.02
	if touch:
		var release := InputEventScreenTouch.new()
		release.index = 0
		release.position = root.get_final_transform() * (start + delta)
		release.pressed = false
		Input.parse_input_event(release)
	else:
		_mouse_event(start + delta, false)
	await _settle()
	var shift := view.project(anchor) - initial
	continuous = continuous and is_equal_approx(view.view_scale, scale) and absf(shift.x + (view.focus_x - start_camera) * scale) < 0.02 and absf(shift.y) < 0.02
	_check(continuous, "拖动统一平移且无透视/纵向跳变")
	drags.append({"touch": touch, "touch_samples_after_frame_delivery": touch, "delta": str(delta), "start_camera": start_camera, "end_camera": view.focus_x, "limits": str(view.pan_limits), "steps": steps, "continuous": continuous})

func _record_case(label: String) -> void:
	await _settle()
	_check(_on_screen(view) and _on_screen(room.selection_bar) and _on_screen(room.back_button), "浏览画布与 UI 未溢出 " + label)
	for button in room.selection_bar.get_children():
		if button.visible:
			_check(button.size.x >= 48 and button.size.y >= 48, "常驻按钮触摸尺寸 %s %s" % [label, button.text])
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var empty := 0
		for x in [3.0, view.size.x / 2, view.size.x - 3]:
			for y in [3.0, view.size.y * 0.15, view.size.y / 2, view.size.y * 0.85, view.size.y - 3]:
				var p := Vector2i(root.get_final_transform() * (view.global_position + Vector2(x, y)))
				var color := picture.get_pixelv(p)
				if Vector3(color.r - 0x17 / 255.0, color.g - 0x24 / 255.0, color.b - 0x2b / 255.0).length() < 0.01:
					empty += 1
		_check(empty == 0, "真实画布边缘无无意义空白 " + label)
	var rects := {}
	for id in world.furniture:
		var bounds := view._item_bounds(world.furniture[id])
		rects[String(id)] = {"width": bounds.size.x * view.view_scale, "height": bounds.size.y * view.view_scale, "visible": view.visible_point(id).x >= 0}
	views.append({"scene": label, "window": str(root.size), "canvas": str(view.size), "camera_x": view.focus_x, "limits": str(view.pan_limits), "scale": view.view_scale,
		"world_positions": str(_positions()), "framing": view.effective_framing(), "furniture": rects, "marker": str(world.marker_position), "desk_slot": world.desk_slot})
	await _capture(label)
