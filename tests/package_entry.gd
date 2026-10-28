extends Node
## Only the p0_test export feature selects this entry. Default launches the real
## main scene unchanged; the explicit user flag enables package verification.
const MAIN = preload("res://scenes/main.tscn")
var app: Control
var checks: Array[Dictionary] = []
var evidence: String

func _ready() -> void:
	app = MAIN.instantiate()
	add_child(app)
	if "--verify-package" in OS.get_cmdline_user_args():
		evidence = OS.get_environment("P0_EVIDENCE_DIR")
		if evidence.is_empty():
			get_tree().quit(2)
			return
		DirAccess.make_dir_recursive_absolute(evidence)
		_verify.call_deferred()

func _verify() -> void:
	get_tree().create_timer(40).timeout.connect(func(): get_tree().quit(124))
	await _settle()
	_record(not OS.has_feature("editor"), "实际导出模板运行，非编辑器二进制")
	_record(app.map_view.visible, "地图入口可见")
	_record(not DirAccess.dir_exists_absolute("res://docs"), "文档/证据未打包")
	_record(not DirAccess.dir_exists_absolute("res://.tools"), "工具与密钥未打包")
	await _picture("map")
	for id in [&"dormitory", &"school"]:
		_record(ResourceLoader.exists(app.buildings[id].destination), "包内场景完整 %s" % id)
		await _click(app.map_view.buttons[id])
		_record(app.active_id == id and app.active_room != null, "GUI 进入 %s" % id)
		if app.active_room:
			await _click(app.active_room.action_button)
			_record(app.active_room.interaction_count == 1, "GUI 交互 %s" % id)
			await _picture(String(id))
			await _click(app.active_room.back_button)
			_record(app.active_room == null and app.map_view.visible, "GUI 返回 %s" % id)
	await _click(app.map_view.buttons[&"shop"])
	_record(app.last_rejection == &"locked" and app.active_room == null, "商店锁定反馈")
	_record(not app.enter_building(&"invalid") and app.last_rejection == &"invalid_id", "无效 ID 防护")
	var failed := checks.filter(func(row): return not row.passed).size()
	var report := {"executable": OS.get_executable_path(), "resource_root": ProjectSettings.globalize_path("res://"),
		"editor_feature": OS.has_feature("editor"), "template_feature": OS.has_feature("template"),
		"engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "viewport": str(get_viewport().get_visible_rect().size),
		"passed": checks.size() - failed, "failed": failed, "checks": checks}
	var file := FileAccess.open(evidence.path_join("package_results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	get_tree().quit(0 if failed == 0 else 1)

func _settle() -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while not app.safe_layout.is_layout_settled() or app.transitioning:
		if Time.get_ticks_msec() > deadline:
			_record(false, "布局 3 秒内稳定")
			return
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _click(button: Button) -> void:
	await _settle()
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		get_viewport().push_input(event, true)
	for i in range(5):
		await get_tree().process_frame
	await _settle()

func _picture(label: String) -> void:
	await RenderingServer.frame_post_draw
	_record(get_viewport().get_texture().get_image().save_png(evidence.path_join(label + ".png")) == OK, "实际导出程序截图 %s" % label)

func _record(passed: bool, description: String) -> void:
	checks.append({"name": description, "passed": passed})
