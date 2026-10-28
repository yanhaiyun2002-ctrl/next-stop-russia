extends SceneTree
const MAIN = preload("res://scenes/main.tscn")
var app: Control
var passed := 0
var failed := 0
var checks: Array[Dictionary] = []
var evidence := ""
var motion_samples: Array[Dictionary] = []
var force_restart := false

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if ok:
		passed += 1
	else:
		failed += 1
		push_error(label)

func _frames(count := 5) -> void:
	for i in range(count):
		await process_frame

func _settle() -> void:
	var deadline := Time.get_ticks_msec() + 3500
	while app.transitioning or not app.safe_layout.is_layout_settled():
		if Time.get_ticks_msec() > deadline:
			check(false, "P1 布局 3.5 秒内稳定")
			return
		await process_frame
	await _frames(3)

func _mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = point
	root.push_input(event, true)

func _touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = down
	event.position = root.get_final_transform() * point
	Input.parse_input_event(event)

func _click(control: Control, touch := false) -> void:
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await _settle()
	var point := control.get_global_rect().get_center()
	if touch:
		_touch(point, true)
		await _frames(2)
		_touch(point, false)
	else:
		_mouse(point, true)
		await _frames(2)
		_mouse(point, false)
	await _frames(5)

func _wait_phase(target: String) -> void:
	var deadline := Time.get_ticks_msec() + 7000
	var encounter: P1CatEncounter = app.active_room.p1_controller.encounter
	var previous := encounter.anchor
	var moving := 0
	while encounter.phase != target:
		if Time.get_ticks_msec() > deadline:
			check(false, "猫阶段超时，目标 " + target + " 实际 " + encounter.phase)
			return
		await process_frame
		if not previous.is_equal_approx(encounter.anchor):
			moving += 1
		previous = encounter.anchor
	motion_samples.append({"spot":encounter.spot.get("spotId", ""), "target":target, "movingFrames":moving})
	await _settle()

func _picture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(label + ".png")) == OK, "真实渲染截图 " + label)

func _pet(touch := false) -> void:
	var home = app.active_room
	var point: Vector2 = home.room_view.visible_point(&"cat")
	check(point.x >= 0, "走出后猫咪可见可摸")
	if point.x < 0:
		return
	await _settle()
	point += home.room_view.global_position
	if touch:
		_touch(point, true)
		await _frames(2)
		_touch(point, false)
	else:
		_mouse(point, true)
		await _frames(2)
		_mouse(point, false)
	await _frames(2)
	check(home.p1_controller.encounter.phase == "pet_reaction", "点击猫进入摸猫反馈")

func _restart() -> void:
	var revision_before: float = app.session.state.revision
	app.queue_free()
	await _frames(5)
	app = MAIN.instantiate()
	root.add_child(app)
	await _settle()
	check(app.map_view.visible and app.active_room == null and app.story_flow.modal_kind.is_empty(), "每次重启先到一级地图")
	check(app.session.state.revision == revision_before, "地图启动不改变既有存档状态")
	await _click(app.story_flow.primary_button)
	await _settle()

func _drag(control: Control, delta: Vector2, touch: bool) -> void:
	await _settle()
	var origin := control.get_global_rect().get_center()
	if touch:
		_touch(origin, true)
	else:
		_mouse(origin, true)
	await _frames(3)
	for i in range(1, 7):
		var point := origin + delta * float(i) / 6
		if touch:
			var event := InputEventScreenDrag.new()
			event.index = 0
			event.position = root.get_final_transform() * point
			event.relative = root.get_final_transform().basis_xform(delta / 6)
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseMotion.new()
			event.position = point
			event.relative = delta / 6
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(event, true)
		await _frames(3)
	if control.get_parent() is P1OrganizationBoard:
		await _picture("06_drag_%s_%s" % [control.item_id,"touch" if touch else "mouse"])
	if touch:
		_touch(origin + delta, false)
	else:
		_mouse(origin + delta, false)
	await _frames(4)

func _run() -> void:
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	create_timer(300).timeout.connect(func():
		push_error("P1_PLAYABLE_TIMEOUT")
		quit(124))
	Engine.time_scale = 3.0
	root.size = Vector2i(360, 780) if OS.get_environment("P1_FULL_PORTRAIT") == "1" else Vector2i(1280, 720)
	app = MAIN.instantiate()
	root.add_child(app)
	await _settle()
	check(not app.technical_mode and app.story_flow.modal_kind.is_empty() and app.map_view.visible and app.active_room == null, "默认玩家入口为一级地图；QA仍隐藏")
	check(not app.enter_building(&"school") and app.last_rejection == &"story_locked", "地图入口不绕过首日其他地点门禁")
	await _picture("01_title")
	await _click(app.story_flow.primary_button)
	for i in range(5):
		check(app.story_flow.modal_kind == "arrival", "Q00 正常对白 %d" % i)
		var line: Dictionary = P1Content.data().arrival[i]
		check(app.story_flow.russian_line.text == line.ru and app.story_flow.chinese_line.text == line.zhSubtitle, "俄语与中文字幕同显 " + line.id)
		check(app.story_flow.stage != null and P1Art.texture(app.story_flow.stage.background_id) != null and P1Art.texture(app.story_flow.stage.character_id) != null, "Q00真实背景与独立人物 " + line.id)
		if i == 2:
			await _picture("02_admin_key")
		elif i == 0:
			await _picture("02_arrival_anna")
		await _click(app.story_flow.primary_button, i % 2 == 0)
	check(app.session.state.story.hasHomeKey and not app.session.state.story.homeEntered, "对白结束持钥匙，尚未直接跳猫任务")
	await _click(app.story_flow.primary_button)
	await _settle()
	check(app.active_id == &"dormitory" and not app.active_room.debug_button.visible, "Q00 入原宿舍，测试入口隐藏")
	await _picture("03_cat_first_visible")
	await _wait_phase("guessing")
	var home = app.active_room
	var controller: P1HomeController = home.p1_controller
	var encounter := controller.encounter
	var original_spot: String = encounter.spot.spotId
	check(not app.return_to_map() and app.active_id == &"dormitory", "首日返回地图门禁")
	check(controller.organize_button.disabled and not app.session.advance_message(), "不能先整理或跳消息")
	var wrong: Dictionary = P1Content.data().spots.filter(func(entry): return entry.spotId != original_spot)[0]
	home.room_view.set_browse_center(home.room_view.project_base(P1Content.object_anchor(home.world, wrong.roomObjectId)).x)
	await _settle()
	check(controller.labels[wrong.roomObjectId].visible, "错误候选世界标签可见")
	await _click(controller.labels[wrong.roomObjectId])
	check(encounter.phase == "guessing" and encounter.spot.spotId == original_spot and app.session.state.rewards.is_empty(), "错选不换点、不处罚、不发奖")
	check(encounter.audio_status.contains("文字回退"), "同次尝试明确无音频回退")
	home.room_view.set_browse_center(home.room_view.project_base(P1Content.object_anchor(home.world, encounter.spot.roomObjectId)).x)
	await _settle()
	await _click(controller.labels[encounter.spot.roomObjectId])
	await _wait_phase("await_pet")
	check(app.session.state.rewards.is_empty(), "选对走出后未摸猫不奖励")
	await _picture("04_await_pet")
	await _restart()
	check(app.session.state.rewards.is_empty(), "摸猫前退出重启仍无奖励")
	await _wait_phase("guessing")
	controller = app.active_room.p1_controller
	encounter = controller.encounter
	await _click(controller.labels[encounter.spot.roomObjectId], true)
	await _wait_phase("await_pet")
	await _pet(true)
	check(app.session.state.rewards.is_empty(), "摸猫反馈尚未结束不抢先奖励")
	await _wait_phase("name_required")
	check(app.session.state.rewards.size() == 1 and app.session.state.cat.namePending and app.session.state.quests.q01_cat == "active", "反馈完成奖励一次，Q01 等待命名")
	await _picture("05_name_required")
	check(not app.return_to_map(), "命名不可通过返回绕过")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await _frames()
	check(app.story_flow.modal_kind == "naming", "Escape 和系统返回不跳过命名")
	await _restart()
	check(app.story_flow.modal_kind == "naming" and app.session.state.rewards.size() == 1, "命名前退出恢复命名、不重领奖")
	await _click(app.story_flow.primary_button)
	check(app.session.state.cat.namePending, "空名字在实际 UI 被拒绝")
	app.story_flow.name_input.text = "小雪 Снег"
	await _click(app.story_flow.primary_button, true)
	check(app.session.state.quests.q01_cat == "completed" and app.active_room.p1_controller.organize_button.disabled == false, "实际确认名字推进 Q01 和独立整理按钮")
	await _click(app.active_room.p1_controller.organize_button)
	await _click(app.story_flow.item_buttons.textbook)
	await _click(app.story_flow.bin_buttons.B)
	await _click(app.story_flow.primary_button)
	check(not app.session.state.organization.tutorialCompleted, "实际非法/不完整摆放不能推进")
	check(app.return_to_map() == false and app.story_flow.modal_kind.is_empty(), "整理退出保留进度且不出门")
	await _click(app.active_room.p1_controller.organize_button)
	check(not app.session.state.organization.placements.has("textbook") and not app.story_flow.org_status.text.is_empty(), "非法放置保持原状态且重进不丢合法数据")
	check(app.story_flow.selected_item.is_empty(), "重进整理清除旧选择，提示与操作一致")
	var board: P1OrganizationBoard = app.story_flow.organization_board
	await _drag(board.item_controls.textbook, board.bin_rect("A").get_center()-board.item_rect("textbook").get_center(), false)
	check(app.session.state.organization.placements.get("textbook") == "A", "实际剧情弹窗内鼠标拖放吸附并保存")
	await _click(app.story_flow.undo_button)
	check(app.session.state.organization.placements.is_empty(), "实际撤销按钮恢复拖放前状态")
	await _drag(board.item_controls.washbag, board.bin_rect("C").get_center()-board.item_rect("washbag").get_center(), true)
	check(app.session.state.organization.placements.get("washbag") == "C", "实际剧情弹窗内合成触摸拖放")
	await _click(app.story_flow.reset_button, true)
	check(app.session.state.organization.placements.is_empty(), "实际重置按钮清空摆放")
	await _click(board.item_controls.passport, true)
	var empty_slot := board.bin_rect("B").get_center()
	_touch(empty_slot,true)
	await _frames(2)
	_touch(empty_slot,false)
	await _frames(4)
	check(app.session.state.organization.placements.get("passport") == "B", "选择物品后触摸空格位也可放置")
	await _drag(board.item_controls.passport, board.bin_rect("C").get_center()-board.item_rect("passport").get_center(), false)
	check(app.session.state.organization.placements.get("passport") == "B" and not board.last_drop_valid, "已放置物品可重拖；非法目标反馈并保留原位")
	await _click(app.story_flow.reset_button)
	# Exercise the actual Flow ScrollContainer, including content that requires scrolling.
	var scroll: ScrollContainer = app.story_flow.body.get_parent()
	var overflow := Control.new()
	overflow.custom_minimum_size.y = 300
	app.story_flow.body.add_child(overflow)
	scroll.scroll_vertical = 0
	await _frames(6)
	var drag_origin := board.item_rect("passport").get_center()
	_mouse(drag_origin,true)
	await _frames(2)
	var move := InputEventMouseMotion.new()
	move.position = drag_origin+Vector2(12,0)
	move.relative = Vector2(12,0)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move,true)
	await _frames(2)
	check(board.pointer_active and board.dragging, "实际整理弹窗开始拖动")
	scroll.scroll_vertical = 24
	await _frames(3)
	_mouse(board.bin_rect("B").get_center(),false)
	await _frames(3)
	check(scroll.scroll_vertical > 0 and not board.pointer_active and app.session.state.organization.placements.is_empty(), "实际弹窗滚动取消旧拖放且不误存档")
	overflow.queue_free()
	scroll.scroll_vertical = 0
	await _frames(6)
	for pair in [["textbook","A"],["passport","B"],["scarf","B"],["washbag","C"]]:
		await _click(app.story_flow.item_buttons[pair[0]], true)
		await _click(app.story_flow.bin_buttons[pair[1]], true)
	await _picture("06_organization")
	await _click(app.story_flow.primary_button)
	check(app.story_flow.modal_kind == "message" and not app.session.state.story.cityUnlocked, "Q02 完成进入安娜消息但未提前开放城市")
	check(app.story_flow.russian_line.text == P1Content.data().annaMessage[0].ru and app.story_flow.chinese_line.text == P1Content.data().annaMessage[0].zhSubtitle, "安娜消息俄语和中文同显")
	await _picture("07_anna_message")
	await _click(app.story_flow.primary_button)
	await _click(app.story_flow.primary_button, true)
	check(app.session.state.story.cityUnlocked and app.session.state.quests.q03_anna_message == "completed", "正常 UI 连续路径 Q00→Q03 解锁城市")
	await _picture("08_first_playable_complete")
	await _click(app.story_flow.primary_button)
	# Four explicit DEV-style fixtures in tests only. No fixture controls in PLAYTEST UI.
	for pixels in [Vector2i(1280,720), Vector2i(360,780)]:
		root.size = pixels
		app.safe_layout.refresh()
		await _settle()
		controller = app.active_room.p1_controller
		encounter = controller.encounter
		for entry in P1Content.data().spots:
			check(encounter.begin_round(false, entry.spotId), "可复现四藏点 " + entry.spotId)
			check(encounter.audio_status.is_empty() and encounter.last_attempt.is_empty(), "新轮清理旧词汇反馈 " + entry.spotId)
			await _wait_phase("guessing")
			var label: Control = controller.labels[entry.roomObjectId]
			check(label.visible, "家具世界标签可见 %s %s" % [pixels, entry.spotId])
			var visible: Vector2 = app.active_room.room_view.visible_point(&"cat")
			check(visible.x >= 0, "藏猫真实可见线索 %s %s" % [pixels, entry.spotId])
			var anchor: Vector3 = P1Content.object_anchor(app.active_room.world, entry.roomObjectId) + P1Content.vector(entry.hideOffset)
			check(encounter.anchor.is_equal_approx(anchor), "藏点由物件和世界偏移定位 " + entry.spotId)
			await _picture("spot_%dx%d_%s" % [pixels.x,pixels.y,entry.spotId])
			var before := encounter.anchor
			var initial_camera: float = app.active_room.room_view.focus_x
			var expected_camera: float = clampf(initial_camera - 34.0 / app.active_room.room_view.view_scale, app.active_room.room_view.pan_limits.x, app.active_room.room_view.pan_limits.y)
			await _drag(label, Vector2(34,0), pixels.x < pixels.y)
			check(encounter.phase == "guessing" and encounter.anchor == before, "标签上横拖不误判 " + entry.spotId)
			check(is_equal_approx(expected_camera, app.active_room.room_view.focus_x), "标签横拖按边界平移视角 " + entry.spotId)
			app.active_room.room_view.set_browse_center(app.active_room.room_view.project_base(anchor).x)
			await _settle()
			await _click(label, pixels.x < pixels.y)
			await _wait_phase("await_pet")
			await _pet(pixels.x < pixels.y)
			await _wait_phase("complete")
			check(app.session.state.rewards.size() == 2 and not app.session.state.cat.namePending, "重玩不重复纪念与命名 " + entry.spotId)
	# Unforced random replay uses the normal button; always avoids adjacency.
	for i in range(11):
		controller = app.active_room.p1_controller
		encounter = controller.encounter
		var prior: String = encounter.spot.spotId
		await _click(controller.replay_button, i % 2 == 0)
		await _wait_phase("guessing")
		check(encounter.spot.spotId != prior, "自由随机连续轮次不相邻重复 %d" % i)
		await _click(controller.labels[encounter.spot.roomObjectId], i % 2 == 0)
		await _wait_phase("await_pet")
		await _pet(i % 2 == 0)
		await _wait_phase("complete")
	check(app.session.state.cat.rounds == 20 and not app.session.state.cat.namePending, "累计 20 次摸猫、11 次自然随机重玩无再次命名")
	check(app.return_to_map(), "完成首段可返回原地图")
	await _settle()
	check(app.map_view.visible and app.enter_building(&"school"), "城市开放仍可进技术学校")
	await _settle()
	check(app.return_to_map(), "学校返回保持原导航")
	await _settle()
	check(not app.enter_building(&"shop") and app.last_rejection == &"locked", "商店仍锁定，无 Q04/Q05 实现")
	await _click(app.map_view.buttons[&"dormitory"])
	await _wait_phase("guessing")
	check(app.session.state.story.cityUnlocked and not app.session.state.cat.namePending, "地图重入保留任务与猫名字")
	await _picture("09_phone_reentry")
	var output := FileAccess.open(evidence.path_join("playable_results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":checks,"motion":motion_samples,"display":DisplayServer.get_name(),"note":"synthetic desktop mouse/touch; not human or physical phone acceptance"},"\t"))
	output.close()
	print("P1_PLAYABLE passed=%d failed=%d" % [passed,failed])
	app.queue_free()
	await _frames()
	quit(0 if failed == 0 else 1)
