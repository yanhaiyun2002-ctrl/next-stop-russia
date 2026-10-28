extends "res://tests/cat_hunt_tests.gd"
## Bounded diagnostic: records engine-delivered events instead of guessing.
class PointerTrace extends Node:
	var records: Array = []
	var phase := ""
	var target: Control
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton or event is InputEventScreenTouch or (event is InputEventMouseMotion and event.button_mask != 0):
			records.append({"phase": phase, "path": "input", "type": event.get_class(), "position": str(event.position), "pressed": event.pressed if event is InputEventMouseButton or event is InputEventScreenTouch else null,
				"settled": target.safe_layout.is_layout_settled(), "mouse_down": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)})

func _run() -> void:
	evidence = OS.get_environment("P0_EVIDENCE_DIR")
	if evidence.is_empty():
		evidence = "res://docs/evidence/p0-04/touch_probe"
	if FileAccess.file_exists(evidence.path_join("touch_probe.json")):
		push_error("Preserve previous probe evidence; choose a new P0_EVIDENCE_DIR")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	app = MAIN.instantiate()
	root.add_child(app)
	await _settle()
	app.enter_building(&"dormitory")
	await _settle()
	_bind_room()
	root.size = Vector2i(1920, 1080)
	app.safe_layout.refresh()
	await _settle()
	var trace := PointerTrace.new()
	trace.target = app
	root.add_child(trace)
	room.hunt_action.gui_input.connect(func(event):
		if event is InputEventMouseButton:
			trace.records.append({"phase": trace.phase, "path": "button_gui", "pressed": event.pressed, "position": str(event.position)}))
	room.hunt_action.pressed.connect(func(): trace.records.append({"phase": trace.phase, "path": "pressed_signal"}))
	var results: Array = []
	for phase in ["one_frame", "two_frames", "atomic", "mixed_one_frame", "mixed_atomic", "mixed_two_frames", "window_origin"]:
		_place(0)
		view.frame_object("bed")
		await _settle()
		if phase.begins_with("mixed"):
			await _click(view.global_position + view.project(world.hunt.anchor(world.furniture) + Vector3(-0.3, 0.26, 0)))
			await _click(view.global_position + _empty_point())
		if phase == "window_origin":
			root.position = Vector2i.ZERO
		await _settle()
		trace.phase = phase
		var point: Vector2 = room.hunt_action.get_global_rect().get_center()
		var physical := root.get_final_transform() * point
		for down in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = physical
			touch.pressed = down
			Input.parse_input_event(touch)
			if phase in ["one_frame", "mixed_one_frame", "window_origin"]:
				await process_frame
			elif phase in ["two_frames", "mixed_two_frames"]:
				await process_frame
				await process_frame
		await _settle()
		results.append({"phase": phase, "window_position": str(root.position), "window": str(root.size), "logical": str(root.get_visible_rect().size), "transform": str(root.get_final_transform()),
			"button": str(room.hunt_action.get_global_rect()), "logical_point": str(point), "physical_point": str(physical), "hint_requested": world.hunt.hint_requested})
	var output := FileAccess.open(evidence.path_join("touch_probe.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"results": results, "events": trace.records}, "\t"))
	output.close()
	print("CAT_TOUCH_PROBE ", JSON.stringify(results))
	app.queue_free()
	trace.queue_free()
	await process_frame
	quit()
