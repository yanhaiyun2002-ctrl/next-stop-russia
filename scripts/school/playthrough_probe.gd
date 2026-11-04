extends Node
## Explicit QA-only player walkthrough. Every transition is real GUI input.
## Never attached during ordinary play; only isolated test directories accepted.
var app: Control
var view: BuildingRoom
var integrated := false
var evidence := ""
var clicks: Array = []
var checks: Array = []
var failed := 0
var quantity := 1
var root: Window
var force_wrong := false

func _ready() -> void: _run.call_deferred()
func frames(n := 8) -> void:
	for i in n: await get_tree().process_frame
func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"name":label})
	if not ok:
		failed += 1
		push_error(label)
func page() -> String:
	return view.page_id if is_instance_valid(view) else "MAP_OR_DORMITORY"
func snapshot(name: String) -> void:
	await frames(10)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence.path_join(name+".png"))
func body_button(prefix: String) -> Button:
	var pending: Array = [view.active_page_root()]
	while not pending.is_empty():
		var node: Node = pending.pop_front()
		if node is Button and node.text.begins_with(prefix): return node
		pending.append_array(node.get_children())
	return null
func click(button: Button) -> void:
	if not is_instance_valid(button):
		check(false,"requested UI button exists")
		return
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await frames(12)
	var point := button.get_global_rect().get_center()
	var caption: String = button.get_meta("caption",button.text)
	var entry := {"text":caption,"control":button.name,"x":point.x,"y":point.y,"pageBefore":page(),"disabled":button.disabled}
	check(not button.disabled,"player button enabled: "+caption)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event,true)
		await frames(4)
	await frames(12)
	entry.pageAfter = page()
	clicks.append(entry)
	_save_clicks()
func _save_clicks() -> void:
	var out := FileAccess.open(evidence.path_join("input_events.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify(clicks,"\t")); out.close()
func _enter_school() -> void:
	if is_instance_valid(app.active_room):
		if not app.story_flow.modal_kind.is_empty():
			for node in app.story_flow.body.get_children():
				if node is Button and node.text == "看看城市地图":
					await click(node)
					break
		if is_instance_valid(app.active_room): await click(app.active_room.back_button)
	await frames(15)
	if not app.map_view.location_row.visible:
		for node in app.map_view.tools.get_children():
			if node is Button and node.text == "地点": await click(node); break
	await click(app.map_view.buttons[&"school"])
	await frames(15)
	view = app.active_room
	check(is_instance_valid(view) and app.active_id == &"school","real map location UI enters integrated school")
func _previews(prefix := "") -> void:
	check(view.page_id == "WORD_PREVIEW","real start click creates session and routes to preview")
	await snapshot(prefix+"03_preview_first")
	for i in 20:
		if view.page_id != "WORD_PREVIEW": break
		if body_button("开始测验") != null:
			await snapshot(prefix+"04_preview_last")
			await click(body_button("开始测验"))
		else:
			await click(body_button("记下并查看下一张"))
	check(view.page_id == "QUIZ_BLACKBOARD" and view.board.visible,"preview CTA enters real blackboard question")
	await snapshot(prefix+"05_quiz_ready")
func _quiz(prefix := "", allow_wrong := false) -> void:
	var first := ""
	var first_wrong := false
	var repeat_wrong := false
	for i in 80:
		if view.page_id == "RESULTS": break
		if view.screen == "waiting":
			await get_tree().create_timer(5.1).timeout
			await click(view.next_button)
			continue
		var q: Dictionary = view.study.state.session.activeQuestion
		if q.is_empty(): check(false,"quiz has active question"); break
		if not q.submitted:
			check(q.options.size() == 4 and view.option_buttons.size() == 4,"every new question renders four dynamic choices")
			if view.portrait:
				var clip: Rect2 = view.teacher_clip.get_global_rect()
				check(view.option_buttons.all(func(b): return not b.get_global_rect().intersects(clip)),"portrait choices do not overlap teacher display region")
			var item: Dictionary = view.study.state.session.items[q.wordId]
			var index := int(q.correctSlot)
			var intentional_wrong := false
			if allow_wrong and not first_wrong:
				first = q.wordId
				first_wrong = true
				intentional_wrong = true
			elif allow_wrong and q.wordId == first and item.remainingCorrect == 1 and not repeat_wrong:
				repeat_wrong = true
				intentional_wrong = true
			if intentional_wrong: index = (index+1)%q.options.size()
			var before_passed: int = view.study.progress().passed
			await click(view.option_buttons[index])
			if intentional_wrong:
				check(view.study.state.session.items[q.wordId].remainingCorrect == (1 if repeat_wrong else 2),"wrong keeps exact strengthening requirement")
				await snapshot(prefix+("09_wrong_after_strengthen_1" if repeat_wrong else "07_wrong"))
				if not repeat_wrong:
					var before_feedback: Dictionary = JSON.parse_string(JSON.stringify(view.study.state.session.activeQuestion))
					await click(view.pause_button)
					check(view.screen == "paused","feedback can pause through actual UI")
					if integrated:
						await click(view.back_button)
						view = null
						await _enter_school()
						await click(view.start_button)
					else:
						await click(body_button("继续学习"))
					check(JSON.parse_string(JSON.stringify(view.study.state.session.activeQuestion)) == before_feedback,"paused/returned feedback restored exactly")
			elif item.everWrong and view.study.state.session.items[q.wordId].remainingCorrect == 1:
				check(view.study.progress().passed == before_passed,"strengthening 1/2 does not count word passed")
				await snapshot(prefix+"08_strengthen_1")
			elif i == 0 or (allow_wrong and i == 1):
				await snapshot(prefix+"06_quiz_correct")
		await click(view.next_button)
	check(view.page_id == "RESULTS" and not view.board.visible,"all words finish on separate parchment results page")
	await snapshot(prefix+"10_results")
func _run() -> void:
	root = get_tree().root
	evidence = OS.get_environment("SCHOOL_EVIDENCE_DIR")
	if evidence.is_empty() or not OS.get_environment("NSR_DATA_ROOT").begins_with(evidence):
		push_error("R2 walkthrough requires an isolated evidence/player-data namespace")
		get_tree().quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	if not OS.get_environment("SCHOOL_QUANTITY").is_empty(): quantity = int(OS.get_environment("SCHOOL_QUANTITY"))
	force_wrong = OS.get_environment("SCHOOL_FORCE_WRONG") == "1"
	get_tree().create_timer(180).timeout.connect(func(): push_error("R2_E2E_TIMEOUT"); get_tree().quit(124))
	var width := int(OS.get_environment("SCHOOL_WIDTH"))
	var height := int(OS.get_environment("SCHOOL_HEIGHT"))
	root.size = Vector2i(width if width > 0 else 1280,height if height > 0 else 720)
	await frames(20)
	if integrated: await _enter_school()
	check(view.page_id == "STUDY_PREPARATION" and not view.board.visible,"independent preparation page has no green board")
	check(not view.study.alphabet_complete(),"clean player path does not require completed alphabet")
	await snapshot("01_preparation_unselected")
	await click(view.mode_buttons.new)
	check(not view.count_buttons.has(10) and not view.count_buttons.has(20),"unavailable 10/20 choices are not displayed")
	await click(view.count_buttons[quantity])
	await snapshot("02_preparation_selected")
	await click(view.start_button)
	await _previews()
	await _quiz("",force_wrong)
	check(view.study.progress().passed == quantity and view.study.state.session.status == "completed","actual selected distinct word count completed")
	await click(body_button("返回学习中心"))
	await click(view.mode_buttons.new)
	if OS.get_environment("SCHOOL_PARTIAL_ROUND") == "1":
		var remaining: int = view.study.available(view.deck_id,"new").size()
		check(remaining == 6-quantity,"partial profile reports actual remaining new words")
		await click(view.count_buttons[remaining])
		await click(view.start_button)
		await _previews("partial_")
		await _quiz("partial_")
		await click(body_button("返回学习中心"))
		await click(view.mode_buttons.new)
	if view.study.available(view.deck_id,"new").is_empty():
		await click(view.start_button)
		check(view.notice.contains("没有可学新词"),"zero-new-word CTA gives visible explanation")
		await snapshot("11_no_new_words")
		await click(view.mode_buttons.review)
		check(view.selected_mode == "review" and view._effective_mode() == "free_review","no-new profile offers honestly labelled free review")
	await click(view.mode_buttons.notebook)
	check(view.screen == "notebook","view notebook card opens notebook directly")
	await snapshot("12_notebook")
	var out := FileAccess.open(evidence.path_join("e2e_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"quantity":quantity,"entry":"integrated" if integrated else "standalone","version":preload("res://scripts/school/build_info.gd").VERSION,"checks":checks,"clicks":clicks,"savePath":view.study.store.path,"binary":OS.get_executable_path(),"scope":"actual Godot GUI mouse input; no direct learning/service transitions"},"\t")); out.close()
	print("SCHOOL_R2_E2E passed=%d failed=%d quantity=%d integrated=%s" % [checks.size()-failed,failed,quantity,integrated])
	get_tree().quit(0 if failed == 0 else 1)
