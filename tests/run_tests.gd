extends SceneTree
## Real Godot integration tests. --headless checks logic/layout, not rendering.
## Without --headless also captures actual rendered viewport images.

const MAIN = preload("res://scenes/main.tscn")
var app: Control
var passes := 0
var failures := 0
var entries := 0
var checks: Array[Dictionary] = []
var layouts: Array[Dictionary] = []
var evidence_dir := "res://docs/evidence"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not OS.get_environment("P0_EVIDENCE_DIR").is_empty():
		evidence_dir = OS.get_environment("P0_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	create_timer(90).timeout.connect(func():
		push_error("P0_TEST_TIMEOUT: integration suite did not finish")
		quit(124))
	app = MAIN.instantiate()
	root.add_child(app)
	app.room_entered.connect(func(_id): entries += 1)
	await _frames()
	_check(app.map_view.visible and app.active_room == null, "地图为真实启动入口")
	_check(app.buildings.size() == 3 and app.map_view.buttons.size() == 3, "三栋建筑配置")
	_check(not app.enter_building(&"unknown") and app.last_rejection == &"invalid_id", "无效建筑 ID 有反馈")
	_check(not app.enter_building(&"shop") and app.last_rejection == &"locked", "锁定商店可点击并反馈")
	_check(not app.map_view.status_label.text.is_empty(), "拒绝操作保留可见提示")
	await _invalid_destinations()
	var map_instance: int = app.map_view.get_instance_id()
	for id in [&"dormitory", &"school"]:
		_check(app.enter_building(id), "请求进入 %s" % id)
		_check(not app.enter_building(id), "同帧重复进入被拦截 %s" % id)
		await _frames()
		_check(app.active_id == id and app.active_room != null, "独立场景已进入 %s" % id)
		_check(not app.map_view.visible, "室内隐藏地图 %s" % id)
		app.active_room.action_button.pressed.emit()
		_check(app.active_room.interaction_count == 1, "临时场景简单交互 %s" % id)
		_check(not app.active_room.feedback.text.is_empty(), "临时交互显示结果 %s" % id)
		app.active_room.back_button.pressed.emit()
		_check(not app.return_to_map(), "同帧重复返回被拦截 %s" % id)
		await _frames()
		_check(app.active_room == null and app.map_view.visible, "返回地图 %s" % id)
		_check(app.map_view.get_instance_id() == map_instance, "保留地图实例 %s" % id)
		_check(app.map_view.selected_id == id, "保留建筑选择 %s" % id)
		_check(root.gui_get_focus_owner() == app.map_view.buttons[id], "恢复建筑焦点 %s" % id)
	for i in range(20):
		var id := &"dormitory" if i % 2 == 0 else &"school"
		app.enter_building(id)
		await _frames(3)
		app.return_to_map()
		await _frames(3)
	_check(entries == 22 and app.active_room == null, "20 轮额外往返无重复实例")
	_check(app.safe_layout.get_child_count() == 1, "返回后无室内节点残留")
	await _resize_regressions()
	for pixels in [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1080, 1920), Vector2i(1170, 2532), Vector2i(360, 780)]:
		await _check_layout(pixels)
	await _safe_area()
	# The same map stays alive through orientation changes and room return.
	app.enter_building(&"dormitory")
	await _frames()
	root.size = Vector2i(1280, 720)
	app.safe_layout.refresh()
	await _frames()
	_check(_on_screen(app.active_room.back_button), "方向切换后室内返回可访问")
	app.return_to_map()
	await _frames()
	await _input_checks()
	app.enter_building(&"school")
	await _frames()
	_check(not quit_on_go_back, "禁用引擎默认系统返回即退出")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames()
	_check(app.active_room == null and app.map_view.visible, "合成系统返回通知回到地图")
	app.enter_building(&"dormitory")
	await _frames()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await _frames()
	_check(app.active_room == null and app.map_view.visible, "Escape 返回地图")
	var report := {
		"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(),
		"passed": passes, "failed": failures, "checks": checks, "layouts": layouts,
		"scope": "synthetic desktop viewport/input; not mobile device tests"
	}
	var filename := "headless_results.json" if DisplayServer.get_name() == "headless" else "rendered_results.json"
	var file := FileAccess.open(evidence_dir.path_join(filename), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("P0_TEST_RESULT passed=%d failed=%d display=%s" % [passes, failures, DisplayServer.get_name()])
	app.queue_free()
	await _frames(2)
	quit(0 if failures == 0 else 1)

func _invalid_destinations() -> void:
	var bad := BuildingDefinition.new()
	bad.id = &"broken"
	bad.display_name = "错误配置测试"
	bad.is_open = true
	app.buildings[bad.id] = bad
	_check(not app.enter_building(bad.id) and app.last_rejection == &"missing_scene", "空场景路径被拦截")
	bad.destination = "res://scenes/does_not_exist.tscn"
	_check(not app.enter_building(bad.id) and app.last_rejection == &"missing_scene", "缺失场景路径被拦截")
	bad.destination = "res://tests/fixtures/wrong_room.tscn"
	_check(not app.enter_building(bad.id) and app.last_rejection == &"invalid_scene", "错误场景接口被拦截")
	_check(app.map_view.visible and app.active_room == null, "失败保持地图可用")
	app.buildings.erase(bad.id)

func _check_layout(pixels: Vector2i) -> void:
	root.size = pixels
	app.safe_layout.refresh()
	await _frames(10)
	await _wait_layout()
	var logical := root.get_visible_rect().size
	var rects: Array[Rect2] = []
	var building_rects := {}
	# Capture all three at one instant, before navigating or changing containers.
	for id in [&"dormitory", &"school", &"shop"]:
		var snapshot: Rect2 = app.map_view.buttons[id].get_global_rect()
		building_rects[id] = {"x": snapshot.position.x, "y": snapshot.position.y, "w": snapshot.size.x, "h": snapshot.size.y}
	_check(app.map_view.board.portrait == (pixels.y > pixels.x), "方向布局 %s" % pixels)
	for id in [&"dormitory", &"school", &"shop"]:
		var button: Button = app.map_view.buttons[id]
		var rect := button.get_global_rect()
		_check(_on_screen(button), "热点可见 %s %s" % [pixels, id])
		_check(Rect2(Vector2.ZERO, app.map_view.board.size).encloses(Rect2(button.position, button.size)), "热点在地图内 %s %s" % [pixels, id])
		_check(button.size.x >= 48 and button.size.y >= 48, "热点最小触摸尺寸 %s %s" % [pixels, id])
		for other in rects:
			_check(not rect.intersects(other), "热点无重叠 %s %s" % [pixels, id])
		rects.append(rect)
		# Exercise actual GUI mouse path at each layout, including locked feedback.
		await _mouse_click(button)
		if id == &"shop":
			_check(app.active_room == null and app.last_rejection == &"locked", "比例内点击商店反馈 %s" % pixels)
		else:
			_check(app.active_id == id, "比例内点击进入 %s %s" % [pixels, id])
			if app.active_room != null:
				_check(_on_screen(app.active_room.back_button) and _on_screen(app.active_room.action_button), "室内控件可见 %s %s" % [pixels, id])
				await _mouse_click(app.active_room.action_button)
				_check(app.active_room.interaction_count == 1, "GUI 交互 %s %s" % [pixels, id])
				if DisplayServer.get_name() != "headless" and pixels in [Vector2i(1280, 800), Vector2i(360, 780)]:
					await RenderingServer.frame_post_draw
					var room_path := evidence_dir.path_join("%s_%dx%d.png" % [id, pixels.x, pixels.y])
					_check(root.get_texture().get_image().save_png(room_path) == OK, "室内实际渲染截图 %s %s" % [pixels, id])
				await _mouse_click(app.active_room.back_button)
				_check(app.active_room == null, "GUI 返回 %s %s" % [pixels, id])
	app.map_view.show_feedback("选择建筑进入；商店暂未开放。")
	await _frames()
	var image_path := ""
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		image_path = evidence_dir.path_join("map_%dx%d.png" % [pixels.x, pixels.y])
		var picture := root.get_texture().get_image()
		_check(picture.save_png(image_path) == OK, "实际渲染截图 %s" % pixels)
		_check(picture.get_size() == pixels, "截图尺寸符合请求 %s" % pixels)
	layouts.append({"requested_pixels": str(pixels), "actual_window": str(root.size),
		"logical_viewport": str(logical), "portrait": app.map_view.board.portrait,
		"buildings": building_rects, "screenshot": image_path})

func _safe_area() -> void:
	root.size = Vector2i(1170, 2532)
	app.safe_layout.safe_override_pixels = Rect2(0, 150, 1170, 2280)
	app.safe_layout.refresh()
	await _frames(10)
	await _wait_layout()
	var scale := minf(1170.0 / 360.0, 2532.0 / 780.0)
	var safe := Rect2(0, 150 / scale, 1170 / scale, 2280 / scale)
	for id in app.map_view.buttons:
		_check(safe.encloses(app.map_view.buttons[id].get_global_rect()), "模拟刘海安全区内热点 %s" % id)
	app.enter_building(&"school")
	await _frames()
	_check(safe.encloses(app.active_room.back_button.get_global_rect()), "模拟底部安全区内返回按钮")
	app.return_to_map()
	await _frames()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence_dir.path_join("map_safe_area.png"))
	app.safe_layout.safe_override_pixels = Rect2(-1, -1, 0, 0)
	app.safe_layout.refresh()
	await _frames()

func _input_checks() -> void:
	await _wait_layout()
	_check(Input.emulate_mouse_from_touch and not Input.emulate_touch_from_mouse, "单向触摸模拟配置")
	var button: Button = app.map_view.buttons[&"dormitory"]
	var before := entries
	# Input.parse_input_event goes through the engine's touch->mouse emulation.
	var logical := button.get_global_rect().get_center()
	var physical := root.get_final_transform() * logical
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = physical
	touch.pressed = true
	Input.parse_input_event(touch)
	await _frames(2)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = physical
	release.pressed = false
	Input.parse_input_event(release)
	await _frames()
	_check(entries == before + 1 and app.active_id == &"dormitory", "合成触摸仅进入一次")
	if app.active_room != null:
		app.return_to_map()
		await _frames()
	# Press-drag-release outside a hotspot should cancel, not navigate.
	before = entries
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = button.get_global_rect().get_center()
	root.push_input(down, true)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(2, 2)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(2, 2)
	root.push_input(up, true)
	await _frames()
	_check(entries == before and app.active_room == null, "拖出热点取消点击")

func _mouse_click(button: Button) -> void:
	await _wait_layout()
	# A click is one pair at a single observed coordinate; native mouse motion must
	# not be interleaved by artificial frame waits between synthetic down/up.
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
	await _frames()
	await _wait_layout()

func _wait_layout() -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while not app.safe_layout.is_layout_settled() or app.transitioning:
		if Time.get_ticks_msec() >= deadline:
			_check(false, "布局/导航必须在 3 秒内稳定")
			return
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func _resize_regressions() -> void:
	for round_index in range(10):
		root.size = Vector2i(1280, 800)
		await _wait_layout()
		var old_center: Vector2 = app.map_view.buttons[&"dormitory"].get_global_rect().get_center()
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = old_center
		root.push_input(down, true)
		root.size = Vector2i(360, 780)
		app.safe_layout.refresh()
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = old_center
		root.push_input(up, true)
		await _wait_layout()
		_check(app.active_room == null, "跨尺寸按下/释放取消 %d" % round_index)
		_check(not app.map_view.buttons[&"dormitory"].is_pressed(), "取消后热点不保持按下 %d" % round_index)
		var board: Control = app.map_view.board
		_check(board.portrait, "连续方向切换完成 %d" % round_index)
		for id in app.map_view.buttons:
			_check(app.map_view.buttons[id].size.is_equal_approx(Vector2(156, 92)), "同一帧竖屏热点一致 %d %s" % [round_index, id])
		var id := &"dormitory" if round_index % 2 == 0 else &"school"
		await _mouse_click(app.map_view.buttons[id])
		_check(app.active_id == id, "切换后新热点进入 %d" % round_index)
		if app.active_room:
			await _mouse_click(app.active_room.action_button)
			_check(app.active_room.interaction_count == 1, "切换后交互 %d" % round_index)
			await _mouse_click(app.active_room.back_button)
			_check(app.active_room == null and app.map_view.visible, "切换后返回 %d" % round_index)
		await _mouse_click(app.map_view.buttons[&"shop"])
		_check(app.last_rejection == &"locked", "切换后锁定反馈 %d" % round_index)

func _on_screen(control: Control) -> bool:
	return control.is_visible_in_tree() and Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(control.get_global_rect())

func _check(condition: bool, description: String) -> void:
	checks.append({"name": description, "passed": condition})
	if condition:
		passes += 1
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _frames(count: int = 6) -> void:
	for i in range(count):
		await process_frame
