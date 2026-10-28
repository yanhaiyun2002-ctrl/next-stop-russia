extends "res://tests/run_tests.gd"
## Passive tracing of the unchanged P0-01 suite; no extra waits or relaxed checks.
var trace_file: FileAccess

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/evidence/p0-02/03_diagnostic")
	trace_file = FileAccess.open("res://docs/evidence/p0-02/03_diagnostic/trace.jsonl", FileAccess.WRITE)
	root.size_changed.connect(func(): _mark("window_size_changed"))
	if OS.get_environment("P0_DIAGNOSTIC_FAST") == "1":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	super()

func _check_layout(pixels: Vector2i) -> void:
	if not app.map_view.board.has_meta("trace_connected"):
		app.map_view.board.set_meta("trace_connected", true)
		app.map_view.board.resized.connect(func(): _mark("board_resized"))
		app.map_view.resized.connect(func(): _mark("map_resized"))
		for id in app.map_view.buttons:
			app.map_view.buttons[id].gui_input.connect(func(event):
				if event is InputEventMouseButton:
					_mark("gui_received", {"id": id, "pressed": event.pressed, "position": str(event.position)}))
	_mark("layout_requested", {"pixels": str(pixels)})
	await super(pixels)

func _finalize() -> void:
	if trace_file:
		trace_file.flush()

func _frames(count: int = 6) -> void:
	for i in range(count):
		await process_frame
		_mark("frame")

func _mouse_click(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = button.get_global_rect().get_center()
		_mark("mouse_down" if pressed else "mouse_up", {"target": str(button.get_path()), "position": str(event.position)})
		root.push_input(event, true)
		await _frames(2)
	await _frames()

func _check(condition: bool, description: String) -> void:
	_mark("assert", {"name": description, "passed": condition})
	super(condition, description)

func _mark(event: String, details: Dictionary = {}) -> void:
	if trace_file == null:
		return
	var focus := root.gui_get_focus_owner()
	var row := {"event": event, "frame": Engine.get_process_frames(), "usec": Time.get_ticks_usec(),
		"window": str(root.size), "base": str(root.content_scale_size), "viewport": str(root.get_visible_rect().size),
		"mouse": str(root.get_mouse_position()), "focus": str(focus.get_path()) if focus else "", "details": details}
	if is_instance_valid(app) and is_instance_valid(app.map_view):
		row["active_id"] = app.active_id
		row["transitioning"] = app.transitioning
		row["map_visible"] = app.map_view.visible
		row["board_size"] = str(app.map_view.board.size)
		row["portrait"] = app.map_view.board.portrait
		row["rejection"] = app.last_rejection
		var rects := {}
		for id in app.map_view.buttons:
			rects[id] = str(app.map_view.buttons[id].get_global_rect())
		row["buttons"] = rects
	trace_file.store_line(JSON.stringify(row))
