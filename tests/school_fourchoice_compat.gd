extends SceneTree
var failures := 0
var checks: Array = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures += 1; push_error(label)
func _run() -> void:
	var evidence := OS.get_environment("SCHOOL_EVIDENCE_DIR")
	if evidence.is_empty() or not OS.get_environment("NSR_DATA_ROOT").begins_with(evidence): quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	var dir := evidence.path_join("player-data/legacy")
	var s := SchoolStudyService.new(null,SchoolProgressStore.new(dir))
	s.start("basic.demo",2)
	while s.state.session.phase == "preview": s.preview_next()
	s.next_question()
	# Faithful R1 state: 3 introduced cards and an unanswered 3-option question.
	var legacy := s.state.duplicate(true)
	var known: Array = legacy.session.previewIds.slice(0,3)
	for id in legacy.records.keys():
		if id not in known: legacy.records.erase(id)
	legacy.session.previewIds = known.duplicate()
	legacy.session.previewIndex = known.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var q := s.content.make_question(legacy.session.targetLexemeIds[0],"ZH_TO_RU",known,rng,-1,3)
	q.id = legacy.session.activeQuestion.id
	legacy.session.activeQuestion = q
	legacy.session.status = "paused"
	check(SchoolProgressStore.valid(legacy) and s.store.write_save(legacy),"R1 three-choice fixture is valid on unchanged schema")
	var reopened := SchoolStudyService.new(null,SchoolProgressStore.new(dir))
	var items: Dictionary = reopened.state.session.items.duplicate(true)
	check(reopened.resume() and reopened.state.session.phase == "preview","legacy unanswered question first previews missing fourth support word")
	check(reopened.state.session.activeQuestion.id == q.id and reopened.state.session.items == items,"upgrade preserves question identity and every learning counter")
	while reopened.state.session.phase == "preview": reopened.preview_next()
	var upgraded: Dictionary = reopened.state.session.activeQuestion
	check(upgraded.options.size() == 4 and upgraded.wordId == q.wordId and upgraded.assisted == q.assisted,"legacy unanswered question becomes four-choice without changing target or assistance")
	check(reopened.submit(upgraded.id,upgraded.wordId),"upgraded persisted question accepts a real valid answer")
	# Old submitted feedback is restored byte-for-byte until the player continues.
	legacy.session.activeQuestion.submitted = true
	legacy.session.activeQuestion.result = {"correct":false,"assisted":false,"wordId":q.wordId,"selectedId":q.options.filter(func(o): return o.id != q.wordId)[0].id,"remainingCorrect":2,"wordPassed":false,"strengthening":true,"correctInStrengthening":0}
	legacy.session.phase = "feedback"
	legacy.session.items[q.wordId].remainingCorrect = 2
	legacy.session.items[q.wordId].everWrong = true
	legacy.session.items[q.wordId].attempts = 1
	s.store.write_save(legacy)
	reopened = SchoolStudyService.new(null,SchoolProgressStore.new(dir))
	check(reopened.resume() and reopened.state.session.activeQuestion == JSON.parse_string(JSON.stringify(legacy.session.activeQuestion)),"submitted R1 three-choice feedback remains immutable across restart")
	var out := FileAccess.open(evidence.path_join("compat_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks},"\t")); out.close()
	print("SCHOOL_FOURCHOICE_COMPAT passed=",checks.size()-failures," failed=",failures)
	quit(0 if failures == 0 else 1)
