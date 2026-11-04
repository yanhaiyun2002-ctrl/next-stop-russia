extends SceneTree
const DEMO = preload("res://scenes/school_demo.tscn")
var app: Control
var view: BuildingRoom
var checks: Array = []
var failures := 0
var clock_time := 1800000000
var evidence := "res://docs/evidence/school-v04/ui"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:
		failures += 1
		push_error(label)

func frames(count := 5) -> void:
	for i in count:
		await process_frame

func capture(name: String) -> void:
	await frames(8)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence.path_join(name+".png"))

func click(button: Button, touch := false) -> void:
	if view.board_scroll.is_ancestor_of(button): view.board_scroll.ensure_control_visible(button)
	await frames(8)
	var center := button.get_global_rect().get_center()
	if touch:
		var press := InputEventScreenTouch.new()
		press.index = 0
		press.position = root.get_final_transform()*center
		press.pressed = true
		Input.parse_input_event(press)
		await frames(2)
		var release := InputEventScreenTouch.new()
		release.index = 0
		release.position = root.get_final_transform()*center
		release.pressed = false
		Input.parse_input_event(release)
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = center
		root.push_input(motion,true)
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = center
			event.pressed = pressed
			root.push_input(event,true)
	await frames(4)

func body_button(text: String) -> Button:
	for child in view.body.get_children():
		if child is Button and child.text == text:
			return child
	return null

func show_next() -> void:
	if view.study.state.session.status == "completed":
		return
	view.study.next_question()
	if view.study.state.session.phase == "waiting":
		clock_time += 5
		view.study.next_question()
	view.show_session()
	await frames(3)

func _run() -> void:
	if not OS.get_environment("SCHOOL_EVIDENCE_DIR").is_empty():
		evidence = OS.get_environment("SCHOOL_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	create_timer(100).timeout.connect(func(): push_error("SCHOOL_UI_TIMEOUT"); quit(124))
	root.size = Vector2i(1280,720)
	app = DEMO.instantiate()
	root.add_child(app)
	view = app.get_node("SafeLayout").get_child(0)
	view.study.now = func(): return clock_time
	await frames(12)
	check(view.screen == "home" and view.board.texture != null and view.teacher.texture != null,"UI01 school actual scene + separate board and tutor textures")
	check(view.footer.get_children().all(func(b): return root.get_visible_rect().encloses(b.get_global_rect()) and b.size.y <= 60),"initial footer geometry remains inside screen")
	check(view.speech.size.y <= view.canvas.size.y*.20 and view.speech.position.y == 0,"initial tutor speech follows reference-sized region")
	await capture("00_home")
	# Use the actual alphabet screen handlers for all 33 recognitions.
	view.interact()
	for i in 33:
		view.alphabet_index = i
		view.alphabet_test = false
		view.show_alphabet()
		var letter: Dictionary = view.study.content.letters[i]
		body_button("开始辨形 →").pressed.emit()
		body_button(letter.lower).pressed.emit()
	check(view.study.alphabet_complete(),"33 alphabet cards + recognition through UI")
	view.show_home()
	view.requested_count = 5
	view._start("new",5)
	check(view.screen == "preview","word preview entry")
	check(view.study.state.records[view.study.state.session.previewIds[0]].introduced,"visible card immediately records introduced, without firstLearned")
	await capture("01_preview")
	while view.study.state.session.phase == "preview":
		view.study.preview_next()
	view.show_session()
	await frames(8)
	var q: Dictionary = view.study.state.session.activeQuestion
	check(q.kind == "ZH_TO_RU" and view.speech.text.find(view.study.content.words[q.wordId].displayRu) == -1 and view.audio_button.disabled,"UI03/UI05 no teacher/audio leak; missing audio disabled")
	check(view.option_buttons.size() == 4,"UI01 four real answer buttons")
	await capture("02_ready")
	var first: String = q.wordId
	var wrong: Button
	for button in view.option_buttons:
		if button.text != view.study.content.words[first].displayRu:
			wrong = button
	await click(wrong)
	check(view.study.state.session.items[first].remainingCorrect == 2 and view.study.state.session.activeQuestion.submitted,"UI07 real mouse input enters strengthening")
	var rev: int = view.study.state.revision
	view._answer(q.id,first)
	check(view.study.state.revision == rev,"UI11 stale second click cannot submit twice")
	check(view.next_button != null and view.option_buttons.all(func(b): return b.disabled),"UI07 wrong feedback waits for user, answers locked")
	await capture("03_wrong")
	var saved_q: Dictionary = JSON.parse_string(JSON.stringify(view.study.state.session.activeQuestion))
	view._pause()
	check(view.study.state.session.status == "paused","UI12 paused at wrong feedback")
	var store_path: String = view.study.store.path
	app.queue_free()
	await frames(4)
	app = DEMO.instantiate()
	root.add_child(app)
	view = app.get_node("SafeLayout").get_child(0)
	view.study.now = func(): return clock_time
	await frames(8)
	view._resume()
	check(view.study.state.session.activeQuestion == saved_q and view.study.store.path == store_path and view.next_button != null,"UI12 fresh scene restores exact wrong feedback")
	var strength_captured := false
	for i in 50:
		if view.study.state.session.status == "completed":
			break
		await show_next()
		q = view.study.state.session.activeQuestion
		if q.is_empty():
			break
		var before: int = view.study.progress().passed
		view._answer(q.id,q.wordId)
		if q.wordId == first and view.study.state.session.items[first].remainingCorrect == 1:
			check(view.study.progress().passed == before,"UI08 first strengthening correct doesn't add progress")
			await capture("04_strengthen_1")
			strength_captured = true
		elif not strength_captured:
			await capture("04_correct")
	check(view.study.state.session.status == "completed" and view.study.progress().passed == 5,"UI10/UI19 all targets actually completed")
	view.study.next_question()
	view.show_session()
	await capture("05_completed")
	var snap := JSON.stringify(view.study.state.session)
	var board_rect: Rect2 = view.board.get_global_rect()
	view._toggle_teacher()
	await frames(5)
	check(not view.teacher.visible and view.board.get_global_rect() == board_rect,"UI13 teacher collapse preserves board rectangle")
	view.study.set_setting("reducedMotion",true)
	view.study.set_setting("themeId","classroom_blackboard_muted")
	view._redraw_screen()
	check(JSON.stringify(view.study.state.session) == snap,"UI15/UI16 presenter palette/motion cannot mutate session")
	view.show_notebook()
	check(view.study.state.records.values().filter(func(r): return r.firstLearned).size() == 5,"notebook populated from real learned words")
	await capture("06_notebook")
	view.show_home()
	view._start("new",1)
	while view.study.state.session.phase == "preview":
		view.study.preview_next()
	view.show_session()
	q = view.study.state.session.activeQuestion
	view.show_notebook()
	view._return_from_auxiliary()
	check(view.study.state.session.activeQuestion.assisted,"dictionary during question marks assisted")
	view._answer(q.id,q.wordId)
	check(view.study.state.session.items[q.wordId].remainingCorrect == 2,"UI17 notebook/hint cannot bypass independent success")
	view.study.set_setting("teacher",true)
	view._refresh_header()
	# Rendering and bounds at PC/portrait sizes, not mobile device claims.
	for pixels in [Vector2i(1920,1080),Vector2i(1280,800),Vector2i(360,780),Vector2i(1080,1920),Vector2i(1170,2532)]:
		root.size = pixels
		await frames(15)
		view._layout()
		await frames(8)
		var viewport := root.get_visible_rect()
		check(viewport.encloses(view.back_button.get_global_rect()) and viewport.encloses(view.tutor.get_global_rect()),"UI14 controls within viewport "+str(pixels))
		check(view.board_scroll.get_global_rect().size.x > 200 and view.board_scroll.get_global_rect().size.y > 250,"UI14 readable board scroll area "+str(pixels))
		check(view.portrait == (pixels.y > pixels.x),"independent portrait layout "+str(pixels))
		check(view.tutor_actions.get_children().all(func(b): return root.get_visible_rect().encloses(b.get_global_rect())),"tutor actions remain on screen "+str(pixels))
		await capture("layout_%dx%d" % [pixels.x,pixels.y])
	# Long texts: factory-provided data, text wrapping and scrolling.
	root.size = Vector2i(360,780)
	await frames(12)
	view.study.state.session.activeQuestion.prompt = "这是一条用来检查中文长题面能否自动换行的测试说明，测试夹具不属于词库。"
	for option in view.study.state.session.activeQuestion.options:
		option.text += " · проверка длинного текста"
	view.show_quiz()
	await frames(8)
	check(view.option_buttons.all(func(b): return b.get_global_rect().size.x <= view.board_scroll.size.x),"UI14 long option wraps within board")
	await capture("layout_long_text")
	app.get_node("SafeLayout").safe_override_pixels = Rect2(8,32,344,724)
	app.get_node("SafeLayout").refresh()
	await frames(16)
	var safe := Rect2(8,32,344,724)
	check(safe.encloses(view.back_button.get_global_rect()) and safe.encloses(view.portrait_settings.get_global_rect()) and view.tutor_actions.get_children().all(func(b): return safe.encloses(b.get_global_rect())),"visible mobile navigation and actions respect simulated notch and bottom safe area")
	await capture("layout_safe_area")
	# Restore authoritative disk state: long-text fixture is never committed.
	view.study.state = view.study.store.read_save()
	view.study.resume()
	view.show_session()
	await show_next()
	q = view.study.state.session.activeQuestion
	var prior_attempts: int = view.study.state.session.items[q.wordId].attempts
	await click(view.option_buttons[int(q.correctSlot)],true)
	check(view.study.state.session.items[q.wordId].attempts == prior_attempts+1 and view.study.state.session.activeQuestion.submitted,"portrait synthetic native touch submits exactly once")
	var report := {"passed":checks.size()-failures,"failed":failures,"checks":checks,"display":DisplayServer.get_name(),"scope":"synthetic mouse/viewport + actual Godot rendering if not headless; no physical device or human acceptance"}
	var out := FileAccess.open(evidence.path_join("ui_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t"))
	out.close()
	app.queue_free()
	await frames(3)
	print("SCHOOL_UI_RESULT passed=%d failed=%d display=%s" % [checks.size()-failures,failures,DisplayServer.get_name()])
	quit(0 if failures == 0 else 1)
