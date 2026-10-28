extends SceneTree
## Deterministic regression: input in the same event turn as a viewport resize.
var app: Control
var samples: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	root.size = Vector2i(1280, 800)
	await _frames(12)
	var old_center: Vector2 = app.map_view.buttons[&"dormitory"].get_global_rect().get_center()
	_snapshot("before_resize")
	root.size = Vector2i(360, 780)
	app.safe_layout.refresh()
	_snapshot("before_container_sort")
	# Do not wait: exercise the documented vulnerable event boundary.
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = old_center
		root.push_input(event, true)
	await _frames(12)
	_snapshot("after_pending_input")
	var passed: bool = app.active_room == null
	var output := OS.get_environment("P0_PROBE_OUTPUT")
	if output.is_empty():
		output = "res://docs/evidence/p0-02/03_diagnostic/resize_probe.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "samples": samples}, "\t"))
	file.close()
	print("RESIZE_PROBE passed=", passed)
	app.queue_free()
	await _frames(2)
	quit(0 if passed else 1)

func _snapshot(tag: String) -> void:
	var rects := {}
	for id in app.map_view.buttons:
		rects[id] = str(app.map_view.buttons[id].get_global_rect())
	samples.append({"tag": tag, "frame": Engine.get_process_frames(), "window": str(root.size),
		"viewport": str(root.get_visible_rect().size), "portrait": app.map_view.board.portrait,
		"buttons": rects, "active_id": app.active_id, "transitioning": app.transitioning})

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
