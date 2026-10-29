extends Node
## Explicit standalone-package verification only. Never enabled by normal UI.
var app: Control
var evidence := ""
var checks: Array[Dictionary] = []

func _ready() -> void:
	evidence = OS.get_environment("P1_PACKAGE_EVIDENCE")
	if evidence.is_empty():
		get_tree().quit(2)
		return
	_run.call_deferred()

func _record(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:
		push_error(label)

func _frames(count := 5) -> void:
	for i in range(count):
		await get_tree().process_frame

func _settle() -> void:
	if app.process_mode == Node.PROCESS_MODE_DISABLED and is_instance_valid(app.story_flow.organization_board):
		var view: Control = app.story_flow.organization_board
		var previous: Array = []
		var stable := 0
		var until := Time.get_ticks_msec()+4000
		while stable < 3:
			var current: Array = view._signature()
			stable = stable+1 if current == previous else 0
			previous = current
			if Time.get_ticks_msec() > until:
				_record(false,"包内空间整理布局稳定超时")
				return
			await get_tree().process_frame
		return
	await _frames(6)
	var deadline := Time.get_ticks_msec() + 4000
	while app.transitioning or not app.safe_layout.is_layout_settled():
		if Time.get_ticks_msec() > deadline:
			_record(false,"包内布局稳定超时")
			return
		await get_tree().process_frame

func _click(control: Control) -> void:
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await _settle()
	var point := control.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		get_viewport().push_input(event,true)
		await _frames(2)
	await _frames(4)

func _phase(target: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while app.active_room.p1_controller.encounter.phase != target:
		if Time.get_ticks_msec() > deadline:
			_record(false,"包内猫流程阶段超时 " + target)
			return false
		await get_tree().process_frame
	await _settle()
	return true

func _picture(label: String) -> void:
	await RenderingServer.frame_post_draw
	_record(get_viewport().get_texture().get_image().save_png(evidence.path_join(label + ".png")) == OK,"包内真实截图 " + label)

func _run() -> void:
	get_tree().create_timer(90).timeout.connect(func(): get_tree().quit(124))
	DirAccess.make_dir_recursive_absolute(evidence)
	await _settle()
	_record(OS.has_feature("template") and not OS.has_feature("editor"),"实际 Windows 导出模板运行")
	_record(not DirAccess.dir_exists_absolute("res://docs") and not DirAccess.dir_exists_absolute("res://.tools") and not DirAccess.dir_exists_absolute("res://tests"),"包内无策划参考/证据/工具密钥/原测试目录")
	_record(FileAccess.file_exists("res://data/p1/content.json") and FileAccess.file_exists("res://data/city_map.json") and not FileAccess.file_exists("res://data/p1/organization_tutorial.json"),"当前剧情/地图JSON打包，旧ABC题目不入运行包")
	_record(P1Art.texture("city.map") != null and P1Art.texture("story.anna") != null and P1Art.texture("home.background") != null and P1Art.texture("cat") != null,"统一登记表与地图/剧情/宿舍/猫素材在独立包可加载")
	_record(JSON.parse_string(FileAccess.get_file_as_string("res://assets/temp/p1_manifest.json")).releaseStatus == "ART_PENDING","TEMP 清单打包且明确 ART_PENDING")
	_record(app.map_view.visible and app.active_room == null and not app.technical_mode,"包默认正常地图玩家入口")
	await _picture("standalone_title")
	await _click(app.story_flow.primary_button)
	for i in range(6):
		await _click(app.story_flow.primary_button)
	await _settle()
	_record(app.active_id == &"dormitory" and app.session.state.quests.q00_arrival == "completed","独立包 Q00 实际 UI 入宿舍")
	if not await _phase("guessing"):
		_finish()
		return
	var controller: P1HomeController = app.active_room.p1_controller
	await _click(controller.labels[controller.encounter.spot.roomObjectId])
	if not await _phase("await_pet"):
		_finish()
		return
	var view: DormitoryView = app.active_room.room_view
	var point := view.visible_point(&"cat") + view.global_position
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		get_viewport().push_input(event,true)
		await _frames(2)
	if not await _phase("name_required"):
		_finish()
		return
	await _picture("standalone_naming")
	app.story_flow.name_input.text = "Снег"
	await _click(app.story_flow.primary_button)
	_record(app.session.state.quests.q01_cat == "completed","独立包摸猫和名字确认推进 Q01")
	await _click(controller.organize_button)
	var board: Control = app.story_flow.organization_board
	await solve(get_tree(),board,false)
	_record(board.done and board.continue_button.visible,"Windows正式Q02真实拖放和完成反馈")
	await _picture("standalone_q02")
	await _click(app.story_flow.primary_button)
	await _click(app.story_flow.primary_button)
	await _click(app.story_flow.primary_button)
	_record(app.session.state.story.cityUnlocked and app.session.state.rewards.size() == 2,"独立包 Q02 Q03 完整连续流程与两次纪念记录")
	await _picture("standalone_complete")
	_finish()

func _finish() -> void:
	var failed := checks.filter(func(row):return not row.passed).size()
	var file := FileAccess.open(evidence.path_join("package_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"executable":OS.get_executable_path(),"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"saveDirectory":app.session.store.directory},"\t"))
	file.close()
	print("P1_PACKAGE passed=%d failed=%d" % [checks.size()-failed,failed])
	get_tree().quit(0 if failed == 0 else 1)

func frames(tree: SceneTree, count := 5) -> void:
	for i in range(count): await tree.process_frame

func pointer(tree: SceneTree, point: Vector2, down: bool, touch := false) -> void:
	if touch:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = tree.root.get_final_transform()*point
		event.pressed = down
		Input.parse_input_event(event)
	else:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		tree.root.push_input(event,true)

func tap(tree: SceneTree, point: Vector2, touch := false) -> void:
	pointer(tree,point,true,touch)
	await frames(tree,2)
	pointer(tree,point,false,touch)
	await frames(tree)

func drag(tree: SceneTree, view: Control, id: String, target: Vector2, touch := false) -> void:
	var source: Vector2 = view.world_to_screen(view.model.poses[id].position)
	var destination: Vector2 = view.world_to_screen(target)
	pointer(tree,source,true,touch)
	await frames(tree,2)
	for i in range(1,7):
		var point := source.lerp(destination,float(i)/6)
		if touch:
			var event := InputEventScreenDrag.new()
			event.index = 0
			event.position = tree.root.get_final_transform()*point
			event.relative = tree.root.get_final_transform().basis_xform((destination-source)/6)
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseMotion.new()
			event.position = point
			event.relative = (destination-source)/6
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			tree.root.push_input(event,true)
		await frames(tree,2)
	pointer(tree,destination,false,touch)
	await frames(tree)

func solve(tree: SceneTree, view: Control, touch := false) -> void:
	await tap(tree,view.world_to_screen(Vector2(490,345)),touch)
	await tap(tree,view.action_buttons["转向"].get_global_rect().get_center(),touch)
	await drag(tree,view,"scarf",Vector2(498.5,260),touch)
	await tap(tree,view.world_to_screen(view.model.poses.washbag.position),touch)
	await tap(tree,view.action_buttons["转向"].get_global_rect().get_center(),touch)
	await drag(tree,view,"washbag",Vector2(206.5,305),touch)
	await drag(tree,view,"textbook",Vector2(360,290),touch)
	await drag(tree,view,"passport",Vector2(83,332.5),touch)
	await tree.create_timer(0.4).timeout
