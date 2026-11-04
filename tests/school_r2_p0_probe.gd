extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var app := preload("res://scenes/school_demo.tscn").instantiate()
	root.add_child(app)
	for i in 20: await process_frame
	var view = app.get_node("SafeLayout").get_child(0)
	var button: Button
	for child in view.body.get_children():
		if child is Button and child.text == "学习新词 →": button = child
	view.board_scroll.ensure_control_visible(button)
	for i in 12: await process_frame
	var before: String = view.screen
	var point := button.get_global_rect().get_center()
	var report := {"entry":"previous source + copied actual PLAYTEST school sidecar","beforeScreen":before,"buttonDisabled":button.disabled,"pressedConnections":button.pressed.get_connections().size(),"buttonRect":str(button.get_global_rect()),"click":str(point),"eligibleNew":view.study.available("basic.demo","new").size(),"requestedCount":view.requested_count,"alphabetComplete":view.study.alphabet_complete(),"savePath":view.study.store.path}
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event,true)
	for i in 12: await process_frame
	report.afterScreen = view.screen
	report.sessionCreated = not view.study.state.session.is_empty()
	await RenderingServer.frame_post_draw
	var evidence := OS.get_environment("SCHOOL_EVIDENCE_DIR")
	root.get_texture().get_image().save_png(evidence.path_join("old_button_no_response.png"))
	var file := FileAccess.open(evidence.path_join("reproduction.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("P0_REPRO=",JSON.stringify(report))
	app.queue_free()
	await process_frame
	quit()
