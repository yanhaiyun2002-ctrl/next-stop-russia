extends SceneTree
var checks: Array = []
var failures := 0
var clock_time := 1800000000
var evidence := "res://docs/evidence/school-v04/domain"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:
		failures += 1
		push_error(label)

func service(storage: SchoolProgressStore = null) -> SchoolStudyService:
	var s := SchoolStudyService.new(null,storage,func(): return clock_time)
	return s

func alphabet(s: SchoolStudyService) -> void:
	for letter in s.content.letters:
		s.alphabet_view(letter.id)
		s.alphabet_answer(letter.id,letter.lower)

func preview(s: SchoolStudyService) -> void:
	while s.state.session.phase == "preview":
		if not s.preview_next():
			check(false,"preview commits: "+s.error)
			break

func question(s: SchoolStudyService) -> Dictionary:
	if not s.next_question():
		check(false,"next question commits: "+s.error)
	if s.state.session.phase == "waiting":
		clock_time += s.round_delay_seconds
		if not s.next_question():
			check(false,"delayed question commits: "+s.error)
	return s.state.session.activeQuestion

func wrong_id(q: Dictionary) -> String:
	for option in q.options:
		if option.id != q.wordId:
			return option.id
	return "invalid"

func finish(s: SchoolStudyService) -> void:
	for step in 200:
		if s.state.session.status == "completed":
			return
		var q := question(s)
		if q.is_empty():
			return
		if not s.submit(q.id,q.wordId):
			check(false,"finish submit commits: "+s.error)
			return
	check(false,"scheduler must terminate")

func _run() -> void:
	var directory := OS.get_environment("SCHOOL_EVIDENCE_DIR")
	if not directory.is_empty():
		evidence = directory
	DirAccess.make_dir_recursive_absolute(evidence)
	var s := service()
	check(s.content.errors.is_empty(),"P1 data validation")
	check(s.content.letters.size() == 33,"Q26 full unique alphabet")
	var direct := service()
	check(direct.start("basic.demo",1) and not direct.alphabet_complete(),"R2 clean demo starts without forging alphabet progress")
	alphabet(s)
	check(s.alphabet_complete(),"33 viewed and identified letters unlock vocabulary")
	check(not s.start("basic.demo",10) and not s.start("basic.demo",20),"Q24 6 words cannot fabricate 10/20")
	check(s.start("basic.demo",1),"Q10 single target session")
	preview(s)
	check(s.state.session.targetLexemeIds.size() == 1 and s.state.records.size() == 4,"four-choice support cards explicit, not extra targets")
	var q := question(s)
	var target: String = q.wordId
	check(s.submit(q.id,wrong_id(q)),"Q02 first wrong commits")
	check(s.state.session.items[target].remainingCorrect == 2 and s.progress().passed == 0,"Q02 first wrong requires 2")
	check(not s.submit(q.id,q.wordId),"Q11 repeated/stale submit rejected")
	check(s.next_question() and s.state.session.phase == "waiting","Q09/Q10 single word round delay")
	check(not s.next_question(),"minimum non-answer delay enforced")
	clock_time += 5
	check(s.next_question(),"single target resumes after delay")
	var q2: Dictionary = s.state.session.activeQuestion
	check(q2.kind != q.kind and q2.correctSlot != q.correctSlot,"Q09 direction and correct position change")
	s.submit(q2.id,q2.wordId)
	check(s.state.session.items[target].remainingCorrect == 1 and s.progress().passed == 0,"Q03 first strengthening success not passed")
	q = question(s)
	s.submit(q.id,wrong_id(q))
	check(s.state.session.items[target].remainingCorrect == 1,"Q04 repeat wrong does not reset success")
	var root_path := ProjectSettings.globalize_path(evidence).path_join("save-test-"+str(Time.get_ticks_usec()))
	var store := SchoolProgressStore.new(root_path)
	s.store = store
	check(s.pause(),"Q19 pause commits without completion")
	var restored := service(SchoolProgressStore.new(root_path))
	check(restored.state.session.items[target].remainingCorrect == 1 and restored.state.session.activeQuestion == JSON.parse_string(JSON.stringify(s.state.session.activeQuestion)),"Q12 exact feedback and remaining restored")
	check(restored.state.session.status == "paused" and restored.state.events.is_empty(),"Q19 pause produces no completed event")
	restored.resume()
	q = question(restored)
	restored.submit(q.id,q.wordId)
	check(restored.state.session.status == "completed" and restored.progress().passed == 1,"Q05/Q08 final independent success completes")
	var revision: int = restored.state.revision
	check(not restored.submit(q.id,q.wordId) and restored.state.revision == revision,"Q08/Q11 completion idempotent")
	check(restored.state.records[target].firstLearned and restored.state.records[target].sessionHistory.size() == 1,"one lifetime word record")
	var event_count: int = restored.state.events.size()
	var reloaded := service(SchoolProgressStore.new(root_path))
	check(reloaded.state.events.size() == event_count and reloaded.state.records[target].sessionHistory.size() == 1,"reload cannot resettle")
	check(reloaded.available("basic.demo","review").is_empty(),"not due immediately")
	clock_time += 86400
	check(reloaded.available("basic.demo","review") == [target],"Q23 injected cross-day due date")
	check(reloaded.start("basic.demo",1,"review"),"start due review")
	preview(reloaded)
	q = question(reloaded)
	reloaded.submit(q.id,wrong_id(q))
	for repeat in 3:
		q = question(reloaded)
		reloaded.submit(q.id,wrong_id(q))
		check(reloaded.state.session.items[target].remainingCorrect == 2,"Q06 repeated strengthening wrong remains 2")
	finish(reloaded)
	check(reloaded.state.records[target].reviewState.lapseCount == 2 and reloaded.state.records[target].reviewState.intervalDays == 1,"Q23 failures shorten interval and record lapse")
	var c := s.content
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	check(c.make_question(target,"AUDIO_TO_RU",c.words.keys(),rng).has("error"),"Q13 audio factory rejects missing audio")
	var ids := c.words.keys()
	var duplicate: Dictionary = c.words[ids[1]].duplicate(true)
	c.words[ids[1]].zhMeanings = c.words[target].zhMeanings.duplicate()
	var ambiguous := c.make_question(target,"RU_TO_ZH",[target,ids[1]],rng)
	check(ambiguous.has("error"),"Q14 synonym/duplicate meanings excluded")
	c.words[ids[1]] = duplicate
	var four := c.make_question(target,"RU_TO_ZH",ids,rng,-1,4)
	check(four.options.size() == 4,"factory supports four choices")
	var a := service()
	alphabet(a)
	a.start("basic.demo",2)
	preview(a)
	q = question(a)
	a.use_hint(q.id)
	a.submit(q.id,q.wordId)
	check(a.state.session.items[q.wordId].remainingCorrect == 2 and a.progress().passed == 0,"UI17 revealing hint assisted, cannot pass")
	finish(a)
	check(a.progress().total == 2 and a.progress().passed == 2,"Q10 two-word session terminates")
	var b := service()
	alphabet(b)
	b.start("basic.demo",5)
	preview(b)
	q = question(b)
	var first: String = q.wordId
	b.submit(q.id,wrong_id(q))
	var intervening := {}
	for i in 2:
		q = question(b)
		intervening[q.wordId] = true
		b.submit(q.id,q.wordId)
	check(intervening.size() == 2 and not intervening.has(first),"Q09 at least 2 distinct intervening targets")
	var previous: int = b.progress().passed
	for i in 50:
		if b.state.session.status == "completed":
			break
		q = question(b)
		b.submit(q.id,q.wordId)
		check(b.progress().passed >= previous,"Q07 progress monotonic")
		previous = b.progress().passed
	check(b.progress().passed == 5,"Q01/Q08 5 target flow complete")
	var snap: Dictionary = b.state.session.duplicate(true)
	b.set_setting("themeId","classroom_blackboard_muted")
	b.set_setting("teacher",false)
	b.set_setting("reducedMotion",true)
	check(b.state.session == snap,"Q20/Q21 theme/teacher/reduced motion never alter session")
	var occurrence := {"sourceId":"test-only-dialogue","exampleId":"fixture-1","ruSentence":"книга","zhTranslation":"书","sourceType":"other","isVerified":true,"lexemeSpanBindings":[{"lexemeId":target,"surface":"книга"}]}
	var n := service()
	check(n.discover(target,occurrence) and n.discover(target,occurrence),"Q17/Q18 verified occurrence adapter")
	check(n.state.records[target].discovered and not n.state.records[target].firstLearned and n.state.records[target].sourceOccurrences.size() == 1,"Q17/Q18 discovery is not learning, deduplicated source")
	b.story_event("story.cafe_invitation_demo")
	check("scenario.cafe.demo" in b.state.availableDecks,"story adapter opens scenario pack")
	var missing := b.available("basic.demo","new")
	b.start("basic.demo",missing.size())
	preview(b)
	finish(b)
	check(b.state.unlocks.get("cafe_work_demo",false),"Q15/Q16 shared words complete scenario, permanent unlock")
	var events: int = b.state.events.size()
	b.story_event("story.cafe_invitation_demo")
	check(b.state.events.size() == events and b.state.records.size() == 6,"Q15/Q16 one record per word, events deduplicated")
	var old := {"schemaVersion":0,"records":b.state.records,"alphabet":b.state.alphabet}
	var migrated = SchoolProgressStore.migrate(old)
	check(SchoolProgressStore.valid(migrated) and migrated.records == old.records,"Q25 additive school schema migration preserves records")
	var failure_store := SchoolProgressStore.new(root_path.path_join("blocked"))
	failure_store.blocked = true
	var failed := service()
	failed.store = failure_store
	var before := failed.state.duplicate(true)
	check(not failed.alphabet_view(failed.content.letters[0].id) and failed.state == before,"failed disk write rolls back memory transaction")
	var malformed := b.state.duplicate(true)
	malformed.session.items[malformed.session.targetLexemeIds[0]].remainingCorrect = -1
	check(not SchoolProgressStore.valid(malformed),"invalid session snapshot rejected")
	var corrupt := FileAccess.open(store.path,FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var recovering := SchoolProgressStore.new(root_path)
	var recovered := recovering.read_save()
	check(not recovering.blocked and not recovering.notice.is_empty() and SchoolProgressStore.valid(recovered),"corrupt primary recovered from preserved valid backup")
	var future_dir := root_path.path_join("future")
	DirAccess.make_dir_recursive_absolute(future_dir)
	var future_file := FileAccess.open(future_dir.path_join("school_v04.json"),FileAccess.WRITE)
	future_file.store_string('{"schemaVersion":99}')
	future_file.close()
	var future := SchoolProgressStore.new(future_dir)
	future.read_save()
	check(future.blocked and not future.write_save(SchoolProgressStore.fresh()),"future schema blocked, never overwritten")
	# Larger quantities are synthetic fixtures, never shipped as Russian content.
	for quantity in [10,20]:
		var large := service()
		var synthetic: Array = []
		for index in 24:
			var synthetic_id := "test.fixture."+str(index)
			large.content.words[synthetic_id] = {"id":synthetic_id,"displayRu":"TEST_"+str(index),"zhMeanings":["测试夹具_"+str(index)],"audioRef":null}
			synthetic.append(synthetic_id)
		large.content.decks["basic.demo"].recommendedOrder = synthetic
		large.content.decks["basic.demo"].lexemeIds = synthetic
		alphabet(large)
		check(large.start("basic.demo",quantity),"Q24 larger fixture starts "+str(quantity))
		preview(large)
		finish(large)
		check(large.progress().passed == quantity and large.state.session.status == "completed","Q24 larger fixture completes "+str(quantity))
	var settings_before := s.state.duplicate(true)
	check(not s.set_setting("teacher","bad") and not s.set_setting("voiceVolume",2) and s.state == settings_before,"invalid settings rejected without mutation")
	var report := {"passed":checks.size()-failures,"failed":failures,"checks":checks,"engine":Engine.get_version_info(),"scope":"Godot pure domain + actual E-drive persistence, injected clock"}
	var out := FileAccess.open(evidence.path_join("domain_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t"))
	out.close()
	print("SCHOOL_DOMAIN_RESULT passed=%d failed=%d" % [checks.size()-failures,failures])
	quit(0 if failures == 0 else 1)
