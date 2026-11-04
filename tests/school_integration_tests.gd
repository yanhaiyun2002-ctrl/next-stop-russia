extends SceneTree
const MAIN = preload("res://scenes/main.tscn")
const FIXTURE = preload("res://scripts/dev_tools/module_preview.gd")
var checks: Array = []
var failures := 0
var evidence := ""

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:
		failures += 1
		push_error(label)

func frames(count := 12) -> void:
	for i in count:
		await process_frame

func _run() -> void:
	evidence = OS.get_environment("SCHOOL_EVIDENCE_DIR")
	if evidence.is_empty():
		quit(2)
		return
	create_timer(60).timeout.connect(func(): quit(124))
	var base := P1SaveStore.storage_root()
	var catalog := P1ProfileCatalog.new("PLAYTEST",base)
	var complete := FIXTURE.fixture("home",base)
	var first := catalog.create_playtest()
	var first_store := P1SaveStore.new("PLAYTEST",base,first)
	check(first_store.write_save(complete.state) and catalog.select(first),"seed isolated completed Q00-Q03 profile through existing services")
	var main_hash := FileAccess.get_sha256(first_store.directory.path_join("save.json"))
	var app := MAIN.instantiate()
	root.add_child(app)
	await frames()
	check(app.active_profile == first and app.session.state.story.cityUnlocked,"main scene loads selected completed profile")
	check(app.enter_building(&"school"),"real school map navigation accepts unlocked school")
	await frames()
	var school: BuildingRoom = app.active_room
	check(school.study.store.path == first_store.directory.path_join("school_v04.json"),"school sidecar uses active mode/profile directory")
	for letter in school.study.content.letters:
		school.study.alphabet_view(letter.id)
		school.study.alphabet_answer(letter.id,letter.lower)
	school._start("new",1)
	while school.study.state.session.phase == "preview":
		school.study.preview_next()
	school.show_session()
	var q: Dictionary = school.study.state.session.activeQuestion
	var wrong: String = q.options[(int(q.correctSlot)+1)%q.options.size()].id
	school._answer(q.id,wrong)
	check(app.return_to_map(),"return to map from school")
	await frames()
	check(app.enter_building(&"school"),"school re-entry")
	await frames()
	school = app.active_room
	school._resume()
	check(school.study.state.session.activeQuestion.id == q.id and school.study.state.session.activeQuestion.submitted and school.study.state.session.items[q.wordId].remainingCorrect == 2,"real map roundtrip preserves current feedback and strengthening")
	check(FileAccess.get_sha256(first_store.directory.path_join("save.json")) == main_hash,"school never rewrites Q00-Q03 save.json")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape,true)
	await frames()
	check(app.active_room == null and app.map_view.visible,"existing Escape navigation exits school and saves")
	var second := catalog.create_playtest()
	var second_store := P1SaveStore.new("PLAYTEST",base,second)
	second_store.write_save(complete.state)
	check(await app.choose_profile(second),"switch profile using existing selector")
	app.enter_building(&"school")
	await frames()
	school = app.active_room
	check(school.study.state.alphabet.is_empty() and school.study.state.session.is_empty() and school.study.store.path != first_store.directory.path_join("school_v04.json"),"second profile cannot inherit another player's alphabet/session")
	app.return_to_map()
	await frames()
	await app.choose_profile("legacy")
	check(not app.enter_building(&"school") and app.last_rejection == &"story_locked","school preserves existing main-story lock for new profile")
	var out := FileAccess.open(evidence.path_join("integration_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks,"scope":"actual main scene and real mode/profile services, isolated test saves"},"\t"))
	out.close()
	app.queue_free()
	await frames(3)
	print("SCHOOL_INTEGRATION_RESULT passed=%d failed=%d" % [checks.size()-failures,failures])
	quit(0 if failures == 0 else 1)
