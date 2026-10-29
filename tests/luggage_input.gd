extends RefCounted
## Synthetic input helper only. Targets are a test fixture, never production answers.
static func frames(tree: SceneTree, count := 5) -> void:
	for i in range(count): await tree.process_frame

static func pointer(tree: SceneTree, point: Vector2, down: bool, touch := false) -> void:
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

static func tap(tree: SceneTree, point: Vector2, touch := false) -> void:
	pointer(tree,point,true,touch)
	await frames(tree,2)
	pointer(tree,point,false,touch)
	await frames(tree)

static func drag(tree: SceneTree, view: Control, id: String, target: Vector2, touch := false) -> void:
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

static func solve(tree: SceneTree, view: Control, touch := false) -> void:
	await tap(tree,view.world_to_screen(Vector2(490,345)),touch)
	await tap(tree,view.action_buttons["转向"].get_global_rect().get_center(),touch)
	await drag(tree,view,"scarf",Vector2(498.5,260),touch)
	await tap(tree,view.world_to_screen(view.model.poses.washbag.position),touch)
	await tap(tree,view.action_buttons["转向"].get_global_rect().get_center(),touch)
	await drag(tree,view,"washbag",Vector2(206.5,305),touch)
	await drag(tree,view,"textbook",Vector2(360,290),touch)
	await drag(tree,view,"passport",Vector2(83,332.5),touch)
	await tree.create_timer(0.4).timeout
