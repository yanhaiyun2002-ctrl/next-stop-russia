extends SceneTree
const INPUT = preload("res://tests/luggage_input.gd")
const PREVIEW = preload("res://scripts/dev_tools/module_preview.gd")
var app: Control
var evidence := ""
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: push_error(label)
func frames(count := 12) -> void:
	for i in range(count): await process_frame
func picture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(evidence.path_join(name+".png")) == OK,"实际Godot画面 "+name)
func point(id: String) -> Vector2:
	return app.map_view.board.global_position+app.map_view.board.label_rects[id].get_center()

func map_checks(touch: bool) -> void:
	var board: Control = app.map_view.board
	check(board.get_global_rect().is_equal_approx(root.get_visible_rect()),"地图画布覆盖真实有效视口")
	check(Rect2(board.map_offset,board.texture_size*board.map_scale).grow(0.1).encloses(Rect2(Vector2.ZERO,board.size)),"等比cover无图片contain留边")
	var prior: Array[Rect2] = []
	for id in ["dormitory","school","shop"]:
		var plaque: Control = board.plaques[id]
		var rect: Rect2 = board.label_rects[id]
		check(plaque.is_visible_in_tree() and board.label_safe_rect.grow(0.1).encloses(rect),"常驻双语标牌在安全区可见 "+id)
		check(plaque.caption.text.contains(board.locations[id].label.ru) and plaque.caption.text.contains(board.locations[id].label.zh),"地点中俄文字来自地点数据 "+id)
		check(board.hit_test(rect.get_center()) == StringName(id),"标牌命中对应业务ID "+id)
		for other in prior: check(not rect.intersects(other),"标牌彼此不叠压 "+id)
		prior.append(rect)
	check(board.plaques.school.locked and board.plaques.shop.locked,"学校显示剧情锁、商店显示配置锁")
	await picture("01_map_fullscreen")
	await INPUT.tap(self,point("school"),touch)
	await frames()
	check(app.last_rejection == &"story_locked" and app.active_room == null and board.selected_id == &"school" and board.plaques.school.selected,"点击大学标牌金色反馈但不绕剧情门禁")
	await picture("02_school_locked")
	await INPUT.tap(self,point("shop"),touch)
	await frames()
	check(app.active_room == null and board.selected_id == &"shop" and board.plaques.shop.locked,"锁定商店只给锁定反馈")
	await picture("03_shop_locked")
	# Find actual empty artwork, not a HUD or label.
	var blank := Vector2.ZERO
	for y in range(170,int(board.size.y)-200,30):
		for x in range(160,int(board.size.x)-12,35):
			var candidate := Vector2(x,y)
			var clear: bool = board.hit_test(candidate).is_empty()
			for rect in board.label_avoid_rects: clear = clear and not rect.has_point(candidate)
			if clear: blank = candidate
	check(blank != Vector2.ZERO,"存在可交互空白城市画面")
	await INPUT.tap(self,blank,touch)
	check(board.selected_id.is_empty(),"点空白清除选中")
	app.map_view.restore_focus()
	check(root.gui_get_focus_owner() == board.plaques.shop,"折叠地点列表时也可恢复地点键盘焦点")
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key,true)
	await frames()
	check(board.selected_id == &"shop" and app.active_room == null,"标牌键盘确认复用锁定导航")
	var original_scale: float = board.map_scale
	board.set_zoom(1.3)
	board.locate(&"dormitory")
	await frames()
	check(board.map_scale > original_scale and board.hit_test(board.label_rects.dormitory.get_center()) == &"dormitory","缩放定位后标牌与变换一致")
	var start: Vector2 = board.global_position+board.size/2
	INPUT.pointer(self,start,true,touch)
	await frames(2)
	if touch:
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = root.get_final_transform()*(start+Vector2(60,0))
		event.relative = root.get_final_transform().basis_xform(Vector2(60,0))
		Input.parse_input_event(event)
	else:
		var event := InputEventMouseMotion.new()
		event.position = start+Vector2(60,0)
		event.relative = Vector2(60,0)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(event,true)
	await frames(2)
	INPUT.pointer(self,start+Vector2(60,0),false,touch)
	await frames()
	check(app.active_room == null and app.story_flow.modal_kind.is_empty() and not board.pressed,"标牌/地图拖动不误触导航且正常释放")
	board.set_zoom(1)
	board.locate(&"dormitory")
	await frames()
	INPUT.pointer(self,point("dormitory"),true,touch)
	await frames(3)
	check(board.selected_id == &"dormitory" and board.plaques.dormitory.selected,"按住宿舍标牌有自然金色选中反馈")
	await picture("04_dormitory_selected")
	INPUT.pointer(self,point("dormitory"),false,touch)
	await frames()
	check(app.story_flow.modal_kind == "arrival","宿舍标牌复用原Q00引导")
	check(app.story_flow.russian_line.text == P1Content.data().arrival[0].ru and app.story_flow.chinese_line.text == P1Content.data().arrival[0].zhSubtitle,"Q00俄中内容未改")
	check(app.story_flow.stage.get_global_rect().is_equal_approx(root.get_visible_rect()),"Q00背景全屏、字幕独立安全区")
	await picture("05_q00_dialogue")
	app.story_flow._clear()
	# Simulated notch only affects safe UI; background remains edge-to-edge.
	app.safe_layout.safe_override_pixels = Rect2(0,40,root.size.x,root.size.y-70)
	app.safe_layout.refresh()
	await frames(20)
	check(board.get_global_rect().is_equal_approx(root.get_visible_rect()),"模拟安全区不缩小背景画布")
	var safe := Rect2(0,40,root.get_visible_rect().size.x,root.get_visible_rect().size.y-70)
	check(safe.encloses(app.map_view.header.get_global_rect()) and safe.encloses(app.map_view.footer.get_global_rect()),"地图主要HUD处于模拟安全区")
	await picture("06_safe_area")
	app.safe_layout.safe_override_pixels = Rect2(-1,-1,0,0)
	app.safe_layout.refresh()
	await frames()

func run() -> void:
	create_timer(100).timeout.connect(func(): quit(124))
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	var touch := OS.get_environment("P1_FULL_PORTRAIT") == "1"
	root.size = Vector2i(360,780) if touch else Vector2i(1280,720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(30)
	var font: Font = app.theme.default_font
	for target in [Vector2(1280,720),Vector2(360,780)]:
		var source := GameUI.cover_region(Vector2(2135,736),target)
		check(is_equal_approx(source.size.x/source.size.y,target.x/target.y) and Rect2(0,0,2135,736).encloses(source),"宿舍背景cover源区域等比裁切 "+str(target))
	for letter in "ОбщежитиеУниверситетМагазин宿舍大学商店":
		check(font.has_char(letter.unicode_at(0)),"本机系统字体真实字形覆盖 "+letter)
	await map_checks(touch)
	await formal_components(touch)
	var failed := checks.filter(func(c): return not c.passed).size()
	var file := FileAccess.open(evidence.path_join("ui_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"display":DisplayServer.get_name(),"fontNames":font.get("font_names"),"note":"synthetic Godot desktop render/input, not physical phone or human visual approval"},"\t"))
	file.close()
	print("UI_VISUAL passed=%d failed=%d" % [checks.size()-failed,failed])
	quit(0 if failed == 0 else 1)

func formal_components(touch: bool) -> void:
	app.queue_free()
	await frames()
	var seed := PREVIEW.fixture("q02",evidence.path_join("legal-test-fixture"))
	check(P1SaveStore.new("PLAYTEST").write_save(seed.state),"只在隔离测试根目录构造合法Q02验收状态")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(25)
	await INPUT.tap(self,app.story_flow.map_continue.get_global_rect().get_center(),touch)
	await frames(25)
	var view: Control = app.story_flow.organization_board
	check(is_instance_valid(view),"正式地图继续进入原空间Q02")
	if not is_instance_valid(view): return
	await INPUT.tap(self,view.action_buttons["退出"].get_global_rect().get_center(),touch)
	await frames()
	check(app.active_room.room_view.get_global_rect().is_equal_approx(root.get_visible_rect()),"宿舍真实画布铺满视口，HUD不挤压相机窗口")
	await picture("07_home_fullscreen")
	app.story_flow.show_organization()
	await frames()
	view = app.story_flow.organization_board
	app.safe_layout.safe_override_pixels = Rect2(0,40,root.size.x,root.size.y-70)
	app.safe_layout.refresh()
	await frames(15)
	var safe := Rect2(0,40,root.get_visible_rect().size.x,root.get_visible_rect().size.y-70)
	for button in view.action_buttons.values():
		check(safe.encloses(button.get_global_rect()) and button.size.y >= 48,"整理操作按钮位于模拟安全区 "+button.text)
	await picture("07_q02_safe_area")
	await INPUT.solve(self,view,touch)
	check(view.done and view.model.result().complete and safe.encloses(view.continue_button.get_global_rect()),"安全区布局仍可真实拖放旋转吸附完成且继续可用")
	await picture("08_q02_complete")
	await INPUT.tap(self,view.continue_button.get_global_rect().get_center(),touch)
	await frames()
	check(app.story_flow.modal_kind == "message" and app.story_flow.stage.get_global_rect().is_equal_approx(root.get_visible_rect()),"Q03使用整屏场景与独立纸张消息卡")
	check(app.story_flow.russian_line.text == P1Content.data().annaMessage[0].ru and app.story_flow.chinese_line.text == P1Content.data().annaMessage[0].zhSubtitle,"Q03俄中台词保持原内容")
	await picture("09_q03_message")
	await INPUT.tap(self,app.story_flow.primary_button.get_global_rect().get_center(),touch)
	await INPUT.tap(self,app.story_flow.primary_button.get_global_rect().get_center(),touch)
	app.story_flow._clear()
	app.return_to_map()
	await frames(25)
	check(app.map_view.visible and app.map_view.board.selected_id.is_empty() and root.gui_get_focus_owner() == app.map_view.board.plaques.dormitory,"退出房间清除金色选中并恢复地图键盘焦点")
