extends SceneTree
const MODEL = preload("res://scripts/p1/luggage_tidy/model.gd")
var app: Control
var view: Control
var evidence := ""
var checks: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, name: String) -> void:
	checks.append({"passed":ok,"name":name})
	if not ok:
		push_error(name)

func _frames(count := 6) -> void:
	for i in range(count):
		await process_frame

func _mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	root.push_input(event,true)

func _touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = root.get_final_transform()*point
	event.pressed = pressed
	Input.parse_input_event(event)

func _tap(point: Vector2, touch := false) -> void:
	if touch: _touch(point,true)
	else: _mouse(point,true)
	await _frames(2)
	if touch: _touch(point,false)
	else: _mouse(point,false)
	await _frames()

func _click(control: Control, touch := false) -> void:
	var ancestor := control.get_parent()
	while ancestor:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await _frames(10)
	await _tap(control.get_global_rect().get_center(),touch)

func _drag(id: String, target: Vector2, touch: bool) -> void:
	var source: Vector2 = view.world_to_screen(view.model.poses[id].position)
	var destination: Vector2 = view.world_to_screen(target)
	if touch: _touch(source,true)
	else: _mouse(source,true)
	await _frames(2)
	for index in range(1,7):
		var point := source.lerp(destination,float(index)/6)
		if touch:
			var event := InputEventScreenDrag.new()
			event.index = 0
			event.position = root.get_final_transform()*point
			event.relative = root.get_final_transform().basis_xform((destination-source)/6)
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseMotion.new()
			event.position = point
			event.relative = (destination-source)/6
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(event,true)
		await _frames(2)
	check(view.dragging and view.held == id,"真实抓取并跟随 "+id)
	if id == "passport":
		await _picture("02_dragging_passport")
	if touch: _touch(destination,false)
	else: _mouse(destination,false)
	await _frames()

func _picture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(name+".png")) == OK,"真实渲染 "+name)

func _solution(model, alternate := false) -> void:
	var positions := {"passport":Vector2(83,332.5),"washbag":Vector2(206.5,305),"textbook":Vector2(360,290),"scarf":Vector2(498.5,260)}
	if alternate:
		positions = {"scarf":Vector2(77.5,220),"textbook":Vector2(216,190),"washbag":Vector2(369.5,175),"passport":Vector2(493,147.5)}
	for id in MODEL.IDS:
		check(model.place(id,{"position":positions[id],"turn":0}),"几何摆放有效 "+id+str(alternate))

func _unit() -> void:
	var model = MODEL.new()
	var initial: Dictionary = model.poses.duplicate(true)
	check(not model.result().complete,"初始散放不自动完成")
	for id in MODEL.IDS:
		check(MODEL.AREA.encloses(model.footprint(id)),"初始物件在面内 "+id)
	_solution(model)
	check(model.result().complete,"递增底齐解有效")
	model.restart()
	_solution(model,true)
	check(model.result().complete,"不同位置的递减顶齐解有效")
	for id in MODEL.IDS:
		var old: Vector2 = model.poses[id].position
		model.place(id,{"position":Vector2(600-old.y,old.x),"turn":1})
	check(model.result().complete,"整体换轴后的竖排解有效")
	var valid_snapshot: Dictionary = model.poses.duplicate(true)
	check(not model.place("passport",{"position":Vector2(-50,0),"turn":0}) and model.poses == valid_snapshot,"桌面外放置不改状态")
	model.restart()
	check(model.poses == initial and model.history.is_empty(),"重来固定同一局面")
	var overlapped := {"position":model.poses.textbook.position,"turn":0}
	check(model.place("passport",overlapped) and not model.result().complete,"允许临时叠放但不能当整理完成")
	check(model.undo() and model.poses == initial,"撤销真实空间修改")
	var distant := {"position":Vector2(500,500),"turn":0}
	check(model.snap("passport",distant,18).pose == distant,"远处不自动代摆")
	model.restart()
	_solution(model)
	var near := {"position":Vector2(360,296),"turn":0}
	check(is_equal_approx(model.snap("textbook",near,18).pose.position.y,290),"附近真实边缘吸附")
	model.place("textbook",{"position":Vector2(360,340),"turn":0})
	check(not model.result().complete,"乱齐边不能完成")
	model.restart()
	var chain_ready: bool = model.place("washbag",{"position":Vector2(225,207),"turn":0}) and model.place("textbook",{"position":Vector2(300,232),"turn":0}) and model.place("scarf",{"position":Vector2(350,270),"turn":0})
	var raw := {"position":Vector2(100,167.5),"turn":0}
	check(chain_ready and absf(model.snap("passport",raw,12).pose.position.y-raw.position.y) <= 12.001,"多个对齐候选不会累加成远距离吸附")
	chain_ready = model.place("washbag",{"position":Vector2(235.5,225),"turn":0}) and model.place("textbook",{"position":Vector2(258,210),"turn":0}) and model.place("scarf",{"position":Vector2(238.5,180),"turn":0})
	raw = {"position":Vector2(100,252.5),"turn":0}
	check(chain_ready and absf(model.snap("passport",raw,12).pose.position.x-raw.position.x) <= 12.001,"多个相邻边候选只修正一次原始位置")

func _run() -> void:
	create_timer(120).timeout.connect(func(): quit(124))
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	_unit()
	root.size = Vector2i(360,780) if OS.get_environment("P1_FULL_PORTRAIT") == "1" else Vector2i(1280,720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(20)
	check(app.runtime_mode.can_dev,"使用实际DEV能力入口")
	check(app.session.store.write_save(app.session.state),"只在证据目录建立隔离验收样本")
	var state: Dictionary = app.session.state.duplicate(true)
	var save_path: String = app.session.store.directory.path_join("save.json")
	var digest := FileAccess.get_sha256(save_path)
	var selection_path: String = app.profiles.directory.path_join("selected_profile.json")
	var selection_hash := FileAccess.get_sha256(selection_path) if FileAccess.file_exists(selection_path) else "ABSENT"
	app.transitioning = true
	check(not app.dev_tools.open_luggage_experiment(),"场景切换期间拒绝打开以隔离待执行主线回调")
	app.transitioning = false
	await _click(app.story_flow.dev_module_button)
	await _click(app.dev_tools.luggage_button)
	view = app.dev_tools.luggage_experiment
	check(is_instance_valid(view) and app.process_mode == Node.PROCESS_MODE_DISABLED,"实际DEV菜单打开并隔离下层输入")
	await _frames(10)
	await _picture("01_initial")
	var touch := OS.get_environment("P1_FULL_PORTRAIT") == "1"
	# Rotate the initially horizontal scarf from its visible exposed end.
	await _tap(view.world_to_screen(Vector2(490,345)),touch)
	await _click(view.action_buttons["转向"],touch)
	check(view.model.poses.scarf.turn == 0,"真实按钮转向围巾")
	await _drag("scarf",Vector2(498.5,260),touch)
	await _tap(view.world_to_screen(view.model.poses.washbag.position),touch)
	await _click(view.action_buttons["转向"],touch)
	await _drag("washbag",Vector2(206.5,305),touch)
	await _drag("textbook",Vector2(360,290),touch)
	await _drag("passport",Vector2(83,332.5),touch)
	await create_timer(0.4).timeout
	check(view.model.result().complete and view.done,"直接拖放达到空间关系并自动完成反馈")
	check(view.sound.stream != null and view.sound.stream.data.size() > 0,"完成音生成实际音频数据（不等于真人听感验收）")
	await _picture("03_complete")
	var complete_pose: Dictionary = view.model.poses.duplicate(true)
	await _drag("passport",Vector2(-100,-100),touch)
	check(view.model.poses == complete_pose,"越界松手回原处")
	await _click(view.action_buttons["撤销"],touch)
	check(not view.model.result().complete,"完成后仍可撤销调整")
	await _click(view.action_buttons["重来"],touch)
	check(view.model.poses == MODEL.new().poses,"实际重来回同一局面")
	var before_resize: Dictionary = view.model.poses.duplicate(true)
	var start: Vector2 = view.world_to_screen(view.model.poses.passport.position)
	_mouse(start,true)
	await _frames(2)
	root.size = Vector2i(780,360) if touch else Vector2i(720,800)
	await _frames(10)
	_mouse(start,false)
	await _frames()
	check(view.held.is_empty() and view.model.poses == before_resize,"方向改变取消旧手势且不改摆法")
	check(app.session.state == state and FileAccess.get_sha256(save_path) == digest,"打开/拖放/完成/重来全过程不写原档或任务状态")
	check((FileAccess.get_sha256(selection_path) if FileAccess.file_exists(selection_path) else "ABSENT") == selection_hash,"原型不创建或修改所选档位记录")
	var focus: Control = view.prior_focus.get_ref() if view.prior_focus != null else null
	await _click(view.action_buttons["退出"])
	await _frames()
	check(app.process_mode == Node.PROCESS_MODE_INHERIT and app.story_flow.modal_kind == "dev_modules","退出恢复原处理模式与菜单")
	check(app.session.state == state and FileAccess.get_sha256(save_path) == digest,"退出不改旧存档")
	check(focus == null or focus.has_focus(),"退出恢复原菜单焦点")
	await _click(app.dev_tools.luggage_button)
	view = app.dev_tools.luggage_experiment
	check(view.model.poses == MODEL.new().poses,"重复进入是独立内存初始局面")
	await _click(view.action_buttons["退出"])
	# A running cat scene must pause without altering its prior encounter process flag.
	await app.dev_tools.launch("q01")
	await _frames(12)
	var encounter = app.active_room.p1_controller.encounter
	var anchor: Vector3 = encounter.anchor
	var prior_flag: bool = encounter.is_processing()
	var revision: float = app.session.state.revision
	app.dev_tools.open_luggage_experiment()
	view = app.dev_tools.luggage_experiment
	await create_timer(0.25).timeout
	check(encounter.anchor == anchor and app.session.state.revision == revision,"运行中的猫场景被隔离暂停，不发生隐藏任务进度")
	await _click(view.action_buttons["退出"])
	check(encounter.is_processing() == prior_flag,"退出不强行改变原猫处理标志")
	var failed := checks.filter(func(row):return not row.passed).size()
	var output := FileAccess.open(evidence.path_join("prototype_results.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"display":DisplayServer.get_name(),"actualWindow":str(root.size),"note":"engineering checks only; shared runtime regression; owner approved retention; final integration acceptance pending"},"\t"))
	output.close()
	print("LUGGAGE_PROTOTYPE passed=%d failed=%d" % [checks.size()-failed,failed])
	quit(0 if failed == 0 else 1)
