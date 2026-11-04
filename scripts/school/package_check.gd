extends Node
## Only invoked by an explicit package verification flag in the SCHOOL PLAYTEST.
var view: BuildingRoom
var checks: Array = []
var evidence: String

func _ready() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:
		push_error(label)

func frames(count := 8) -> void:
	for i in count:
		await get_tree().process_frame

func picture(name: String) -> void:
	await frames()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(evidence.path_join(name+".png"))

func _run() -> void:
	evidence = OS.get_environment("SCHOOL_PACKAGE_EVIDENCE")
	if evidence.is_empty():
		push_error("Package verification requires an isolated SCHOOL_PACKAGE_EVIDENCE directory.")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	get_tree().create_timer(60).timeout.connect(func(): get_tree().quit(124))
	await frames()
	check(view.study.content.words.size() == 6 and view.study.content.letters.size() == 33,"packaged JSON loaded")
	check(view.board.texture != null and view.teacher.texture != null,"packaged separate art resources loaded")
	for letter in view.study.content.letters:
		view.study.alphabet_view(letter.id)
		view.study.alphabet_answer(letter.id,letter.lower)
	view._start("new",2)
	check(view.screen == "preview","packaged learning preview")
	while view.study.state.session.phase == "preview":
		view.study.preview_next()
	view.show_session()
	await picture("package_ready")
	var q: Dictionary = view.study.state.session.activeQuestion
	var first: String = q.wordId
	var wrong := ""
	for option in q.options:
		if option.id != first:
			wrong = option.id
	view._answer(q.id,wrong)
	check(view.study.state.session.items[first].remainingCorrect == 2,"packaged wrong requires two independent correct")
	await picture("package_wrong")
	view.study.pause()
	var saved: Dictionary = view.study.state.session.activeQuestion.duplicate(true)
	var storage: SchoolProgressStore = SchoolProgressStore.new(view.study.store.path.get_base_dir())
	view.study = SchoolStudyService.new(null,storage)
	check(view.study.state.session.activeQuestion == JSON.parse_string(JSON.stringify(saved)),"packaged disk restore exact feedback")
	view._resume()
	for i in 20:
		if view.study.state.session.status == "completed":
			break
		view.study.next_question()
		if view.study.state.session.phase == "waiting":
			view.show_session()
			await get_tree().create_timer(5.1).timeout
			view.study.next_question()
		view.show_session()
		q = view.study.state.session.activeQuestion
		view._answer(q.id,q.wordId)
	check(view.study.state.session.status == "completed" and view.study.progress().passed == 2,"packaged complete learning + strengthening loop")
	view.study.next_question()
	view.show_session()
	await picture("package_completed")
	var failed: int = checks.filter(func(c): return not c.passed).size()
	var out := FileAccess.open(evidence.path_join("package_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"savePath":view.study.store.path,"display":DisplayServer.get_name(),"scope":"actual exported Windows executable; scripted input/service calls, no human acceptance"},"\t"))
	out.close()
	print("SCHOOL_PACKAGE_RESULT passed=%d failed=%d" % [checks.size()-failed,failed])
	get_tree().quit(0 if failed == 0 else 1)
