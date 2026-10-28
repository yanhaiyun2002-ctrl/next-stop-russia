extends SceneTree
## Actual renderer snapshots from explicit visual fixtures, not gameplay acceptance.
var app: Control
var evidence := ""

func _initialize() -> void:
	_run.call_deferred()

func _frames(count := 15) -> void:
	for i in range(count):
		await process_frame

func _picture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name+".png"))

func _run() -> void:
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	for pixels in [Vector2i(1280,720),Vector2i(360,780)]:
		root.size = pixels
		app = load("res://scenes/main.tscn").instantiate()
		root.add_child(app)
		await _frames(30)
		app.story_flow.show_arrival()
		await create_timer(0.4).timeout
		await _picture("story_%dx%d" % [pixels.x,pixels.y])
		app.session.state.quests.q01_cat = "completed"
		app.session.state.story.homeEntered = true
		app.story_flow.show_organization()
		await _frames(30)
		await _picture("organization_%dx%d" % [pixels.x,pixels.y])
		app.story_flow._clear()
		app.enter_building(&"dormitory")
		await _frames(90)
		await _picture("home_%dx%d" % [pixels.x,pixels.y])
		app.queue_free()
		await _frames()
	print("P1R_LAYOUT_PREVIEW complete; explicit fixtures, not interaction acceptance")
	quit()
