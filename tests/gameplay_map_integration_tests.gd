extends SceneTree
const MODEL = preload("res://scripts/p1/luggage_tidy/model.gd")
const PREVIEW = preload("res://scripts/dev_tools/module_preview.gd")
const INPUT = preload("res://tests/luggage_input.gd")
var checks: Array[Dictionary] = []
var evidence := ""
var app: Control

func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: push_error(label)
func frames(count := 8) -> void:
	for i in range(count): await process_frame
func picture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(evidence.path_join(name+".png")) == OK,"真实Godot截图 "+name)

func compatibility() -> void:
	var base := evidence.path_join("compatibility-data")
	var old_mid := PREVIEW.fixture("q02",base)
	old_mid.state.organization.placements = {"passport":"B","textbook":"A"}
	old_mid.state.organization.history = [{},{"passport":"B"}]
	var store := P1SaveStore.new("PLAYTEST",base)
	check(store.write_save(old_mid.state),"构造合法旧ABC中途档，无空间字段")
	var digest := FileAccess.get_sha256(store.directory.path_join("save.json"))
	var player := P1Session.new("PLAYTEST",base)
	check(not player.store.blocked and player.state.quests.q02_organize == "active" and player.luggage_model().poses == MODEL.new().poses,"旧中途档主线不丢，新空间从初始局面进入")
	check(player.state.organization.placements == old_mid.state.organization.placements and FileAccess.get_sha256(store.directory.path_join("save.json")) == digest,"读取旧档不自动迁移、不改ABC原始数据或文件")
	check(not player.complete_organization(),"旧ABC记录不能冒充新空间完成")
	var old_done := PREVIEW.fixture("home",base)
	old_done.state.organization.erase("spatial")
	old_done.state.organization.placements = {"textbook":"A","passport":"B","scarf":"B","washbag":"C"}
	check(store.write_save(old_done.state),"构造合法旧已完成Q02/Q03档")
	player = P1Session.new("PLAYTEST",base)
	var revision: int = player.state.revision
	var date: String = player.state.organization.journalDate
	check(player.state.story.cityUnlocked and player.complete_organization() and player.state.revision == revision and player.state.organization.journalDate == date and player.state.rewards.size() == 2,"旧完成档有效，重复完成不改日期/奖励/revision")
	var broken := MODEL.new().snapshot()
	broken.poses.passport.turn = 0.5
	check(not MODEL.valid_snapshot(broken),"拒绝小数转向")
	broken = MODEL.new().snapshot()
	broken.poses.passport.x = -100
	check(not MODEL.valid_snapshot(broken),"拒绝越界存档坐标")
	broken = MODEL.new().snapshot()
	broken.poses.passport.x = true
	check(not MODEL.valid_snapshot(broken),"拒绝布尔坐标")
	var model = MODEL.new()
	model.place("passport",{"position":Vector2(100,260),"turn":0})
	check(player.save_luggage(model.snapshot()),"新空间布局持久化")
	check(P1Session.new("PLAYTEST",base).luggage_model().poses == model.poses,"JSON往返恢复空间坐标和整数转向")
	var checkpoint: Dictionary = player.state.duplicate(true)
	player.store.blocked = true
	model.place("passport",{"position":Vector2(100,270),"turn":0})
	check(not player.save_luggage(model.snapshot()) and player.state == checkpoint,"写入失败空间状态不提交")

func map_drag(board: Control, source: Vector2, delta: Vector2, touch: bool) -> void:
	INPUT.pointer(self,source,true,touch)
	await frames(2)
	for i in range(1,5):
		var point := source+delta*float(i)/4
		if touch:
			var event := InputEventScreenDrag.new()
			event.index = 0
			event.position = root.get_final_transform()*point
			event.relative = root.get_final_transform().basis_xform(delta/4)
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseMotion.new()
			event.position = point
			event.relative = delta/4
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(event,true)
		await frames(2)
	INPUT.pointer(self,source+delta,false,touch)
	await frames()

func _run() -> void:
	create_timer(110).timeout.connect(func(): quit(124))
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	compatibility()
	var touch := OS.get_environment("P1_FULL_PORTRAIT") == "1"
	root.size = Vector2i(360,780) if touch else Vector2i(1280,720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(25)
	check(app.map_view.visible and app.active_room == null,"每次启动先地图")
	var board: Control = app.map_view.board
	check(board.texture != null and board.texture_size == Vector2(1952,1087),"负责人地图实际加载且保持原图坐标系")
	check(board.locations.keys().size() == 3 and board.locations.has("dormitory") and board.locations.has("school") and board.locations.has("shop"),"ABC映射既有业务ID，没有新增地点")
	await picture("01_map_initial")
	for id in board.locations:
		var anchor: Array = board.locations[id].anchor
		var point := Vector2(anchor[0],anchor[1])
		board.locate(StringName(id))
		check(board.local_to_texture(board.texture_to_local(point)).distance_to(point) < 0.01,"纹理坐标往返 "+id)
		check(board.hit_test(board.texture_to_local(point)) == StringName(id),"轮廓和触摸中心正确 "+id)
	board.set_zoom(2.5)
	board.locate(&"school")
	await frames()
	var anchor: Array = board.locations.school.anchor
	var school_point: Vector2 = board.global_position+board.texture_to_local(Vector2(anchor[0],anchor[1]))
	await INPUT.tap(self,school_point,touch)
	check(app.active_room == null and app.last_rejection == &"story_locked","缩放平移后点学校仍执行原剧情门禁")
	board.locate(&"dormitory")
	await frames()
	var before: Vector2 = board.map_offset
	var source := board.global_position+board.size/2
	await map_drag(board,source,Vector2(65,0),touch)
	check(board.map_offset != before and app.story_flow.modal_kind.is_empty() and app.active_room == null,"地图鼠标/触摸拖动浏览不误入剧情或建筑")
	await INPUT.tap(self,app.map_view.task_button.get_global_rect().get_center(),touch)
	check(board.selected_id == &"dormitory","任务定位指向当前宿舍")
	await picture("02_map_task")
	var prior_size := root.size
	var press := board.global_position+board.size/2
	INPUT.pointer(self,press,true,touch)
	await frames(2)
	root.size = Vector2i(780,360) if touch else Vector2i(360,780)
	await frames(15)
	INPUT.pointer(self,press,false,touch)
	await frames()
	check(not board.pressed and app.active_room == null and app.story_flow.modal_kind.is_empty(),"地图跨方向按下/释放取消且不误导航")
	root.size = prior_size
	await frames(15)
	# Open/close Q02 from a legal isolated session, then restart must still show map.
	var player := PREVIEW.fixture("q02",evidence.path_join("preview-data"))
	app.queue_free()
	await frames()
	var store := P1SaveStore.new("PLAYTEST")
	check(store.write_save(player.state),"只在测试数据根目录模拟Q02未完成玩家")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(25)
	check(app.map_view.visible and app.story_flow.modal_kind.is_empty() and app.session.state.quests.q02_organize == "active","Q02未完成重启仍先地图，不绕过必做继续入口")
	await INPUT.tap(self,app.story_flow.map_continue.get_global_rect().get_center(),touch)
	await frames(25)
	var view: Control = app.story_flow.organization_board
	check(is_instance_valid(view) and view.player == app.session and not view.info.text.contains("DEV"),"地图继续直达共享正式Q02，无DEV标题")
	await picture("03_q02_initial")
	await INPUT.drag(self,view,"passport",Vector2(100,260),touch)
	var saved: Dictionary = view.model.snapshot()
	await INPUT.tap(self,view.action_buttons["退出"].get_global_rect().get_center(),touch)
	app.story_flow.show_organization()
	await frames()
	view = app.story_flow.organization_board
	check(view.model.snapshot() == saved,"正常退出再进入恢复空间摆放")
	await INPUT.tap(self,view.action_buttons["重来"].get_global_rect().get_center(),touch)
	await INPUT.solve(self,view,touch)
	check(view.done and not app.session.state.organization.tutorialCompleted,"完成反馈等待明确继续，未提前结算")
	await picture("04_q02_complete")
	await INPUT.tap(self,view.continue_button.get_global_rect().get_center(),touch)
	check(app.story_flow.modal_kind == "message" and app.session.state.rewards.size() == 2 and not app.session.state.story.cityUnlocked,"继续原子完成Q02并进入Q03，城市尚锁")
	await INPUT.tap(self,app.story_flow.primary_button.get_global_rect().get_center(),touch)
	await INPUT.tap(self,app.story_flow.primary_button.get_global_rect().get_center(),touch)
	check(app.session.state.story.cityUnlocked,"原安娜消息完成后解锁城市")
	var failed := checks.filter(func(c): return not c.passed).size()
	var file := FileAccess.open(evidence.path_join("integration_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"display":DisplayServer.get_name(),"note":"synthetic desktop mouse/touch, not human or physical phone acceptance"},"\t"))
	file.close()
	print("GAMEPLAY_MAP passed=%d failed=%d" % [checks.size()-failed,failed])
	quit(0 if failed == 0 else 1)
