extends SceneTree
var evidence := ""
var results: Array = []
func _initialize() -> void: _run.call_deferred()
func frames(n: int) -> void:
	for i in n: await process_frame
func geometry(node: Node, result: Dictionary) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Control: result[str(node.get_path())] = str(node.get_global_rect())
	for child in node.get_children(): geometry(child,result)
func click(button: Button, app: Control, stage: String) -> void:
	await frames(15)
	var prior: Dictionary = {}
	geometry(app,prior)
	var point := button.get_global_rect().get_center()
	var before: bool = app.get_node("SafeLayout").is_layout_settled()
	var event := InputEventMouseButton.new()
	event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	root.push_input(event,true)
	await frames(4)
	var after: Dictionary = {}
	geometry(app,after)
	var changed: Array = []
	for path in prior:
		if prior[path] != after.get(path): changed.append({"path":path,"before":prior[path],"after":after.get(path)})
	results.append({"stage":stage,"settledBefore":before,"settledAtRelease":app.get_node("SafeLayout").is_layout_settled(),"changedOnPress":changed})
	event = InputEventMouseButton.new()
	event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = false
	root.push_input(event,true)
	await frames(12)
func _run() -> void:
	evidence = OS.get_environment("SCHOOL_EVIDENCE_DIR")
	if evidence.is_empty() or not OS.get_environment("NSR_DATA_ROOT").begins_with(evidence): quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size = Vector2i(1280,720)
	var app := preload("res://scenes/school_demo.tscn").instantiate()
	root.add_child(app)
	await frames(20)
	var view = app.get_node("SafeLayout").get_child(0)
	await click(view.mode_buttons.new,app,"mode_new")
	await click(view.count_buttons[1],app,"quantity_1")
	results.append({"selectedCount":view.requested_count})
	await click(view.start_button,app,"start")
	results.append({"screen":view.screen})
	var fonts: Array = []
	for family in ["Georgia","Times New Roman","Arial","Noto Serif SC"]:
		var font := SystemFont.new()
		font.font_names = PackedStringArray([family])
		fonts.append({"family":family,"plain":font.get_string_size("книга",HORIZONTAL_ALIGNMENT_LEFT,-1,50).x,"stressed":font.get_string_size("кни́га",HORIZONTAL_ALIGNMENT_LEFT,-1,50).x,"hasAcute":font.has_char(0x0301)})
	var themed: Font = view.theme.default_font
	fonts.append({"family":"school_composite","plain":themed.get_string_size("книга",HORIZONTAL_ALIGNMENT_LEFT,-1,50).x,"stressed":themed.get_string_size("кни́га",HORIZONTAL_ALIGNMENT_LEFT,-1,50).x})
	var failed := 0
	for result in results:
		if result.has("changedOnPress") and (not result.settledBefore or not result.settledAtRelease or not result.changedOnPress.is_empty()): failed += 1
	if view.requested_count != 1 or view.screen != "preview": failed += 1
	for stressed in ["кни́га","молоко́","ко́фе","вода́","шко́ла"]:
		if absf(themed.get_string_size(stressed,HORIZONTAL_ALIGNMENT_LEFT,-1,50).x-themed.get_string_size(stressed.replace("́",""),HORIZONTAL_ALIGNMENT_LEFT,-1,50).x) > .1: failed += 1
	var out := FileAccess.open(evidence.path_join("stability_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"clicks":results,"fonts":fonts,"passed":9-failed,"failed":failed},"\t")); out.close()
	print("STABILITY ",JSON.stringify(results)); print("FONTS ",JSON.stringify(fonts))
	quit(0 if failed == 0 else 1)
