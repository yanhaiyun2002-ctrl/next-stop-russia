extends "res://tests/ribbon_tests.gd"
## Exercises the actual default game; R/V suites retain spatial fixtures.
var cat_states: Array[Dictionary] = []
var repeats: Array[Dictionary] = []
var _reference_anchor := Vector3(INF, 0, 0)
var _reference_peek := false
var _reference_parts: Array[Dictionary] = []
var input_trace: Node

func _run() -> void:
	evidence = OS.get_environment("P0_EVIDENCE_DIR")
	if evidence.is_empty():
		evidence = "res://docs/evidence/p0-04/cat_hunt"
	DirAccess.make_dir_recursive_absolute(evidence)
	create_timer(180).timeout.connect(func():
		push_error("P0_CAT_TIMEOUT")
		quit(124))
	app = MAIN.instantiate()
	root.add_child(app)
	await _settle()
	var map_instance: int = app.map_view.get_instance_id()
	app.enter_building(&"dormitory")
	await _settle()
	_bind_room()
	input_trace = preload("res://tests/cat_input_trace.gd").new()
	input_trace.target = app
	root.add_child(input_trace)
	room.hunt_action.gui_input.connect(func(event):
		if event is InputEventMouseButton:
			input_trace.record("button_gui", event))
	view.gui_input.connect(func(event):
		if event is InputEventMouseButton or event is InputEventMouseMotion:
			input_trace.record("view_gui", event))
	_check(world.is_hunt_active() and room.hunt_panel.visible, "真实默认宿舍启用找猫")
	_check(not room.debug_panel.visible and not _has_3d(room), "局部 2D 原型与默认收起调试")
	_check(world.furniture.size() == 3 and world.get_child_count() == 3, "找猫状态未增加场景管理节点")
	_check(CatHunt.SPOTS.size() == 3, "三个有稳定 ID 的藏点")
	var ids: Array[StringName] = []
	var expected := {&"under_bed": "Кот под кроватью.", &"under_desk": "Кот под столом.", &"by_wardrobe": "Кот у шкафа."}
	for spot in CatHunt.SPOTS:
		_check(not ids.has(spot.id) and world.furniture.has(spot.furniture), "藏点唯一且引用有效家具 %s" % spot.id)
		ids.append(spot.id)
		_check(spot.ru == expected[spot.id], "位置绑定的俄语原文 %s" % spot.id)
		for letter in String(spot.ru) + "Где кот? Вот кот!":
			var code := letter.unicode_at(0)
			if code >= 0x400 and code <= 0x4ff:
				_check(room.hunt_prompt.get_theme_font("font").has_char(code), "本机字体覆盖俄文字符 %s" % letter)
	_check(not world.hunt.next_search(), "未找到前不能跳过本次藏点")
	for pixels in [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1080, 1920), Vector2i(1170, 2532), Vector2i(360, 780)]:
		root.size = pixels
		app.safe_layout.refresh()
		await _settle()
		for index in range(3):
			_place(index)
			var spot := world.hunt.current_spot()
			var tag := "%s_%dx%d_%s" % ["phone" if pixels.y > pixels.x else "pc", pixels.x, pixels.y, spot.id]
			await _click(room.selection_bar.get_child(index).get_global_rect().get_center())
			_check(not world.hunt.found and world.hunt.prompt().contains("Где кот?"), "导航家具不自动找到猫 " + tag)
			var floor: Vector2 = world.furniture[spot.furniture].floor_position
			_check(world.hunt.anchor(world.furniture) == Vector3(floor.x, 0, floor.y) + Vector3(spot.offset), "藏点使用空间锚点 " + tag)
			var point := _head_point()
			_check(Rect2(Vector2.ZERO, view.size).has_point(point) and view.pick(point) == &"cat" and _oracle(point) == &"cat", "当前视图可发现猫头 " + tag)
			await _record_hunt(tag + "_search")
			await _sample_scene(tag)
			# A covered cat pixel is furniture, never an invisible full-cat button.
			if index == 0:
				var a := world.hunt.anchor(world.furniture)
				var covered := view.project(a + Vector3(-0.3, 0.26, 0))
				_check(view.pick(covered) == &"bed" and _oracle(covered) == &"bed", "床体优先于被遮住的猫身 " + tag)
				var found_before := world.hunt.found_count
				await _click(view.global_position + covered)
				_check(not world.hunt.found and world.hunt.found_count == found_before, "点击遮挡处不会穿透找猫 " + tag)
			var attempts := world.hunt.attempt_count
			await _click(view.global_position + _empty_point())
			_check(not world.hunt.found and world.hunt.attempt_count == attempts + 1 and world.hunt.feedback_kind == &"miss", "空白点击有轻松的失败反馈 " + tag)
			_check(not room.hunt_prompt.text.contains("Вот кот!"), "未找到不宣称成功 " + tag)
			input_trace.phase = tag + "_hint" if pixels == Vector2i(1920, 1080) else ""
			await _touch(room.hunt_action.get_global_rect().get_center())
			_check(room.hunt_prompt.text.contains(spot.ru) and room.hunt_prompt.text.contains(spot.zh), "实际提示与藏点一致 " + tag)
			for other in CatHunt.SPOTS:
				if other.id != spot.id:
					_check(not room.hunt_prompt.text.contains(other.ru), "无不相关俄语提示 %s %s" % [tag, other.id])
			if pixels in [Vector2i(1920, 1080), Vector2i(1080, 1920)]:
				await _record_hunt(tag + "_hint")
			var count := world.hunt.found_count
			point = _head_point()
			input_trace.phase = tag + "_drag" if pixels == Vector2i(1920, 1080) else ""
			await _drag(point, Vector2(50, 0), index % 2 == 1)
			_check(not world.hunt.found and world.hunt.found_count == count, "猫上开始拖动不算找到 " + tag)
			point = _head_point()
			var camera := view.focus_x
			input_trace.phase = tag + "_find" if pixels == Vector2i(1920, 1080) else ""
			if index % 2 == 0:
				await _click(view.global_position + point)
			else:
				await _touch(view.global_position + point)
			_check(world.hunt.found and world.hunt.found_count == count + 1, "可见猫优先且只找到一次 " + tag)
			_check(room.hunt_prompt.text.contains("Вот кот!") and room.hunt_prompt.text.contains(spot.ru) and room.hunt_action.text == "再找一次", "成功后反馈和俄语对应 " + tag)
			_check(is_equal_approx(view.focus_x, camera), "找到时不跳镜头 " + tag)
			await _click(view.global_position + _head_point())
			_check(world.hunt.found_count == count + 1, "重复点击猫不重复结算 " + tag)
			await _record_hunt(tag + "_found")
			var previous: int = world.hunt.spot_index
			input_trace.phase = tag + "_again" if pixels == Vector2i(1920, 1080) else ""
			await _touch(room.hunt_action.get_global_rect().get_center())
			_check(not world.hunt.found and world.hunt.spot_index != previous and not world.hunt.hint_requested, "再次寻找排除上一藏点 " + tag)
	# Ten complete searches use the normal chooser and real buttons, not fixtures.
	world.hunt.rng.seed = 20261029
	world.hunt.restart()
	world.hunt.changed.emit()
	await _settle()
	var previous := -1
	for i in range(10):
		var index: int = world.hunt.spot_index
		var spot := world.hunt.current_spot()
		_check(index != previous and not world.hunt.found, "连续游玩不相邻重复 %d" % i)
		await _touch(room.selection_bar.get_child(index).get_global_rect().get_center())
		if i % 2 == 0:
			await _touch(room.hunt_action.get_global_rect().get_center())
		var anchor := world.hunt.anchor(world.furniture)
		var point := _head_point()
		if i % 2 == 0:
			await _touch(view.global_position + point)
		else:
			await _click(view.global_position + point)
		_check(world.hunt.found and world.hunt.found_count == i + 1, "连续完整找到 %d" % i)
		_check(room.hunt_prompt.text.contains(spot.ru), "连续游玩语言不串藏点 %d" % i)
		repeats.append({"iteration": i + 1, "spot": String(spot.id), "anchor": str(anchor), "ru": spot.ru, "found_count": world.hunt.found_count})
		if i == 9:
			await _record_hunt("phone_360x780_repeat_ten_found")
		previous = index
		await _click(room.hunt_action.get_global_rect().get_center())
	_check(world.hunt.found_count == 10 and not world.hunt.found, "十轮后可继续且没有线性通关")
	# Stable object anchor follows a permitted debug relocation of the desk.
	_place(1)
	var old_anchor := world.hunt.anchor(world.furniture)
	await _click(room.debug_button.get_global_rect().get_center())
	_check(world.hunt_paused and not room.hunt_panel.visible and view.visible_point(&"cat").x < 0, "技术面板暂停并隐藏猫，不覆盖主要画面")
	await _click(room.swap_button.get_global_rect().get_center())
	await _click(room.debug_button.get_global_rect().get_center())
	_check(world.hunt.anchor(world.furniture) != old_anchor and world.hunt.current_spot().id == &"under_desk", "家具移动后藏点仍绑定对象 ID")
	await _click(room.selection_bar.get_child(1).get_global_rect().get_center())
	_check(view.pick(_head_point()) == &"cat" and world.hunt.current_spot().ru == "Кот под столом.", "换位后可发现且语义仍为桌下")
	await _record_hunt("phone_360x780_moved_desk")
	world.toggle_desk()
	# Rotation during a cat press must not complete a search at stale pixels.
	_place(0)
	view.frame_object("bed")
	await _settle()
	var point := view.global_position + _head_point()
	_mouse_event(point, true)
	root.size = Vector2i(1280, 800)
	app.safe_layout.refresh()
	_mouse_event(point, false)
	await _settle()
	_check(not world.hunt.found and not view._pointer_down, "横竖屏切换取消猫的旧按下")
	root.size = Vector2i(1170, 2532)
	app.safe_layout.safe_override_pixels = Rect2(0, 150, 1170, 2280)
	app.safe_layout.refresh()
	await _settle()
	view.frame_object("bed")
	await _settle()
	var scale := minf(1170.0 / 360, 2532.0 / 780)
	var safe := Rect2(0, 150 / scale, 1170 / scale, 2280 / scale)
	_check(safe.encloses(room.hunt_panel.get_global_rect()) and safe.encloses(view.get_global_rect()) and safe.encloses(room.back_button.get_global_rect()), "模拟安全区内语言提示、猫和返回")
	await _touch(view.global_position + _head_point())
	_check(world.hunt.found, "模拟安全区内合成触摸可找到猫")
	await _record_hunt("phone_simulated_safe_area_found")
	app.safe_layout.safe_override_pixels = Rect2(-1, -1, 0, 0)
	app.safe_layout.refresh()
	await _settle()
	for i in range(5):
		if i % 2 == 0:
			_place(i % 3)
		var old_hunt := world.hunt.get_instance_id()
		await _click(room.back_button.get_global_rect().get_center())
		_check(app.active_room == null and app.map_view.get_instance_id() == map_instance and app.safe_layout.get_child_count() == 1, "搜索或找到均可退出且无残留 %d" % i)
		_check(root.gui_get_focus_owner() == app.map_view.buttons[&"dormitory"], "找猫退出恢复导航焦点 %d" % i)
		await _click(app.map_view.buttons[&"dormitory"].get_global_rect().get_center())
		_bind_room()
		_check(world.hunt.get_instance_id() != old_hunt and world.hunt.found_count == 0 and not world.hunt.found and world.is_hunt_active(), "重入为新局部状态而非旧宠物存档 %d" % i)
	var output := FileAccess.open(evidence.path_join("cat_hunt_results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(), "passed": passed, "failed": failed,
		"checks": checks, "cat_states": cat_states, "screenshots": captures, "ray_samples": samples, "drags": drags, "repeat_searches": repeats, "input_trace": input_trace.records,
		"scope": "Actual Windows viewport and synthetic input, not Android device / human playtesting."}, "\t"))
	output.close()
	print("P0_CAT_RESULT passed=%d failed=%d display=%s" % [passed, failed, DisplayServer.get_name()])
	app.queue_free()
	input_trace.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)

func _bind_room() -> void:
	room = app.active_room
	view = room.room_view
	world = room.world
	view.object_selected.connect(func(id): selected.append(id))

func _place(index: int) -> void:
	# Explicit fixture only. Normal progression is separately tested via UI.
	world.hunt.spot_index = index
	world.hunt.found = false
	world.hunt.hint_requested = false
	world.hunt.feedback_kind = &"search"
	world.hunt.changed.emit()

func _head_point() -> Vector2:
	var anchor := world.hunt.anchor(world.furniture)
	var peek: bool = world.hunt.current_spot().peek
	return view.project(anchor + Vector3(0.24, 0.3, -0.75 if peek else 0.0))

func _empty_point() -> Vector2:
	for y in range(15, int(view.size.y) - 15, 30):
		for x in range(15, int(view.size.x) - 15, 30):
			if view.pick(Vector2(x, y)) == &"":
				return Vector2(x, y)
	return Vector2(-1, -1)

func _oracle(point: Vector2) -> StringName:
	if not world.is_hunt_active():
		return super._oracle(point)
	var base := (point - view.size / 2) / view.view_scale + Vector2(view.focus_x, view.focus_y)
	var direction := Vector3((base.x - view.HORIZON.x) / view.focal, -(base.y - view.HORIZON.y) / view.focal, 1)
	var near := INF
	var owner: StringName = &""
	for box in world.all_boxes():
		var hit := _ray_box(direction, box)
		if hit < near:
			near = hit
			owner = box.owner
	var anchor := world.hunt.anchor(world.furniture)
	var peek: bool = world.hunt.current_spot().peek
	if anchor != _reference_anchor or peek != _reference_peek:
		_reference_parts.clear()
		_reference_anchor = anchor
		_reference_peek = peek
		for part in world.cat_parts():
			var polygon := PackedVector2Array()
			for vertex in part.points:
				polygon.append(Vector2(vertex.x, vertex.y))
			_reference_parts.append({"polygon": polygon, "depth": part.depth})
	for part in _reference_parts:
		var t: float = part.depth + view.camera_distance
		if t < near and Geometry2D.is_point_in_polygon(Vector2(direction.x * t, view.eye_height + direction.y * t), part.polygon):
			near = t
			owner = &"cat"
	return owner

func _record_hunt(label: String) -> void:
	await _settle()
	_check(_on_screen(room.hunt_panel) and _on_screen(room.hunt_action) and _on_screen(view) and _on_screen(room.feedback), "玩法 UI 不遮挡/溢出 " + label)
	_check(not room.hunt_panel.get_global_rect().intersects(view.get_global_rect()), "提示位于画布外 " + label)
	_check(room.hunt_action.size.x >= 48 and room.hunt_action.size.y >= 48, "提示/再找按钮触摸尺寸 " + label)
	var point := _head_point()
	_check(view.pick(point) == &"cat" and _oracle(point) == &"cat", "猫屏幕位置与空间锚点一致 " + label)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var pixel := Vector2i(root.get_final_transform() * (view.global_position + point))
		var color := picture.get_pixelv(pixel)
		_check(Vector3(color.r - GrayboxCat.HEAD.r, color.g - GrayboxCat.HEAD.g, color.b - GrayboxCat.HEAD.b).length() < 0.035, "真实像素显示当前猫头 " + label)
	var spot := world.hunt.current_spot()
	cat_states.append({"scene": label, "spot": String(spot.id), "furniture_id": String(spot.furniture), "anchor": str(world.hunt.anchor(world.furniture)),
		"found": world.hunt.found, "found_count": world.hunt.found_count, "hint": world.hunt.hint_requested, "prompt": room.hunt_prompt.text,
		"window": str(root.size), "cat_head_local": str(point), "camera_x": view.focus_x, "scale": view.view_scale})
	await _capture(label)
