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
	_record(FileAccess.file_exists("res://data/p1/content.json") and FileAccess.file_exists("res://data/p1/organization_tutorial.json"),"独立内容 JSON 已打包")
	_record(JSON.parse_string(FileAccess.get_file_as_string("res://assets/temp/p1_manifest.json")).releaseStatus == "ART_PENDING","TEMP 清单打包且明确 ART_PENDING")
	_record(app.story_flow.modal_kind == "title" and not app.technical_mode,"包默认正常 P1 玩家入口")
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
	for pair in [["textbook","A"],["passport","B"],["scarf","B"],["washbag","C"]]:
		await _click(app.story_flow.item_buttons[pair[0]])
		await _click(app.story_flow.bin_buttons[pair[1]])
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
