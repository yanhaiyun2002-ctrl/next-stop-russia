class_name SchoolStudyService
extends RefCounted
signal changed
signal learning_event(event: Dictionary)

const INTERVALS := [1,3,7,14,30]
var content: SchoolContent
var store: SchoolProgressStore
var state: Dictionary
var error := ""
var now: Callable
var gap_words := 2
var round_delay_seconds := 5

func _init(repository: SchoolContent = null, storage: SchoolProgressStore = null, clock: Callable = Callable()) -> void:
	content = repository if repository != null else SchoolContent.new()
	store = storage
	now = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())
	state = store.read_save() if store != null else SchoolProgressStore.fresh()
	if store != null:
		error = store.error
	for id in state.records:
		if not content.words.has(id):
			_block_content()
	for id in state.availableDecks:
		if not content.decks.has(id):
			_block_content()
	for id in state.session.get("previewIds",[]):
		if not content.words.has(id):
			_block_content()
	for id in state.session.get("targetLexemeIds",[]):
		if not content.words.has(id):
			_block_content()
	if not content.errors.is_empty():
		_block_content()

func _block_content() -> void:
	error = "学校内容版本与存档引用不匹配，已停止写入；请恢复对应内容。"
	if store != null:
		store.blocked = true
		store.error = error

static func record() -> Dictionary:
	return {"discovered":false,"introduced":false,"firstLearned":false,"sourceOccurrences":[],"reviewState":{},"sessionHistory":[]}

func _record(next: Dictionary, id: String) -> Dictionary:
	if not next.records.has(id):
		next.records[id] = record()
	return next.records[id]

func _commit(next: Dictionary) -> bool:
	next.revision = state.revision+1
	if not SchoolProgressStore.valid(next):
		error = "学习状态校验失败，操作未提交。"
		return false
	if store != null and not store.write_save(next):
		error = store.error
		print("SCHOOL_TRACE ",JSON.stringify({"event":"persist_failed","error":error,"revision":state.revision}))
		return false
	var old_events: Dictionary = state.events
	state = next
	print("SCHOOL_TRACE ",JSON.stringify({"event":"persisted","revision":state.revision,"phase":state.session.get("phase","none"),"status":state.session.get("status","none")}))
	error = ""
	changed.emit()
	for key in state.events:
		if not old_events.has(key):
			learning_event.emit(state.events[key].duplicate(true))
	return true

func alphabet_complete() -> bool:
	for letter in content.letters:
		if not state.alphabet.get(letter.id,{}).get("passed",false):
			return false
	return content.letters.size() == 33

func alphabet_view(id: String) -> bool:
	var found := false
	for letter in content.letters:
		found = found or letter.id == id
	if not found:
		return false
	if state.alphabet.get(id,{}).get("viewed",false):
		return true
	var next := state.duplicate(true)
	if not next.alphabet.has(id):
		next.alphabet[id] = {"viewed":true,"passed":false}
	return _commit(next)

func alphabet_answer(id: String, lower: String) -> bool:
	for letter in content.letters:
		if letter.id == id and letter.lower == lower and state.alphabet.get(id,{}).get("viewed",false):
			var next := state.duplicate(true)
			next.alphabet[id].passed = true
			return _commit(next)
	return false

func available(deck_id: String, mode: String) -> Array:
	var result: Array = []
	if not content.decks.has(deck_id) or deck_id not in state.availableDecks:
		return result
	for id in content.decks[deck_id].recommendedOrder:
		var r: Dictionary = state.records.get(id,record())
		if mode == "new" and not r.firstLearned:
			result.append(id)
		elif mode in ["review","free_review"] and r.firstLearned:
			if mode == "free_review" or r.reviewState.get("nextReviewAt",0) <= now.call():
				result.append(id)
	return result

func start(deck_id: String, count: int, mode := "new", seed_value := 20261104) -> bool:
	print("SCHOOL_TRACE ",JSON.stringify({"event":"session_request","mode":mode,"count":count,"eligible":available(deck_id,mode).size(),"alphabetComplete":alphabet_complete()}))
	if not state.session.is_empty() and state.session.status != "completed":
		error = "已有学习进度，请先继续本轮。"
		return false
	# R2: alphabet remains independent guidance; the six-word demo must be playable
	# from a clean profile without falsifying alphabet progress.
	if mode not in ["new","review","free_review"]:
		error = "学习模式无效，请返回准备页重新选择。"
		return false
	var ids := available(deck_id,mode)
	if count < 1 or count > ids.size():
		error = "当前只有 %d 个可用词，无法创建 %d 个不同新词。" % [ids.size(),count]
		return false
	ids = ids.slice(0,count)
	var next := state.duplicate(true)
	var preview := ids.duplicate()
	# Small sessions explicitly preview supporting distractors, never count them as targets.
	for id in content.words:
		if preview.size() >= 4:
			break
		if id not in preview:
			preview.append(id)
	var s := {"sessionId":"school-"+str(now.call())+"-"+str(state.revision),"mode":mode,"deckId":deck_id,"targetLexemeIds":ids,"items":{},"pendingQueue":ids.duplicate(),"activeQuestion":{},"questionHistory":[],"seed":seed_value,"ordinal":0,"status":"active","phase":"preview","previewIds":preview,"previewIndex":0,"errors":0,"startedAt":now.call(),"updatedAt":now.call(),"readyAt":0}
	for id in ids:
		s.items[id] = {"remainingCorrect":1,"everWrong":false,"correctInStrengthening":0,"attempts":0,"lastOrdinal":-1,"lastType":"","lastSlot":-1}
	next.session = s
	return _commit(next)

func preview_next() -> bool:
	if state.session.is_empty() or state.session.phase != "preview" or state.session.status != "active":
		return false
	var next := state.duplicate(true)
	var s: Dictionary = next.session
	if s.previewIndex < s.previewIds.size():
		_record(next,s.previewIds[int(s.previewIndex)]).introduced = true
		s.previewIndex += 1
	if s.previewIndex >= s.previewIds.size():
		s.phase = "quiz"
		if not _upgrade_unanswered_question(next): return false
	return _commit(next)

func preview_view() -> bool:
	if state.session.is_empty() or state.session.phase != "preview" or state.session.status != "active":
		return false
	var id: String = state.session.previewIds[int(state.session.previewIndex)]
	if state.records.get(id,record()).introduced:
		return true
	var next := state.duplicate(true)
	_record(next,id).introduced = true
	return _commit(next)

func preview_previous() -> bool:
	if state.session.is_empty() or state.session.phase != "preview" or state.session.status != "active" or state.session.previewIndex <= 0:
		return false
	var next := state.duplicate(true)
	next.session.previewIndex -= 1
	return _commit(next)

func next_question() -> bool:
	if state.session.is_empty() or state.session.status == "paused":
		return false
	var next := state.duplicate(true)
	var s: Dictionary = next.session
	if s.status == "completed":
		s.phase = "summary"
		return _commit(next)
	if s.phase == "preview" or (not s.activeQuestion.is_empty() and not s.activeQuestion.submitted):
		return false
	if s.phase == "waiting" and now.call() < s.readyAt:
		error = "分轮强化：休息片刻后继续，避免刚看答案立即重测。"
		return false
	var chosen := ""
	for id in s.pendingQueue:
		var item: Dictionary = s.items[id]
		if item.remainingCorrect == 0:
			continue
		var intervening := {}
		for h in s.questionHistory:
			if h.ordinal > item.lastOrdinal and h.wordId != id:
				intervening[h.wordId] = true
		if item.lastOrdinal < 0 or intervening.size() >= gap_words or (s.phase == "waiting" and now.call() >= s.readyAt):
			chosen = id
			break
	if chosen.is_empty():
		s.phase = "waiting"
		s.readyAt = now.call()+round_delay_seconds
		s.activeQuestion = {}
		return _commit(next)
	var item: Dictionary = s.items[chosen]
	var kind := "RU_TO_ZH" if item.lastType == "ZH_TO_RU" else "ZH_TO_RU"
	if item.lastType.is_empty() and int(s.ordinal) % 2 == 1:
		kind = "RU_TO_ZH"
	if content.has_audio(chosen) and int(s.ordinal) % 3 == 2 and item.lastType != "AUDIO_TO_RU":
		kind = "AUDIO_TO_RU"
	var known: Array = []
	for id in next.records:
		if next.records[id].introduced or next.records[id].firstLearned:
			known.append(id)
	# Preserve already-submitted legacy three-choice feedback. On continuation,
	# introduce only the additional support cards needed for four-choice questions.
	if known.size() < 4:
		var support: Array = []
		for id in content.words:
			if id not in known and id not in s.previewIds:
				support.append(id)
			if known.size()+support.size() >= 4: break
		if known.size()+support.size() < 4:
			error = "四选题的可用辅助词不足，当前题目与学习进度已保留。"
			return false
		s.previewIndex = s.previewIds.size()
		s.previewIds.append_array(support)
		s.activeQuestion = {}
		s.phase = "preview"
		return _commit(next)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(s.seed)+int(s.ordinal)*7919
	var q := content.make_question(chosen,kind,known,rng,int(item.lastSlot))
	if q.has("error"):
		error = q.error
		return false
	s.ordinal += 1
	q.id = s.sessionId+"/"+str(s.ordinal)
	s.activeQuestion = q
	s.phase = "quiz"
	s.pendingQueue.erase(chosen)
	s.pendingQueue.append(chosen)
	s.updatedAt = now.call()
	return _commit(next)

func use_hint(question_id: String) -> bool:
	if state.session.is_empty() or state.session.status != "active":
		return false
	var q: Dictionary = state.session.activeQuestion
	if q.is_empty() or q.id != question_id or q.submitted:
		return false
	var next := state.duplicate(true)
	next.session.activeQuestion.assisted = true
	return _commit(next)

func submit(question_id: String, answer_id: String) -> bool:
	if state.session.is_empty() or state.session.status != "active":
		return false
	var q: Dictionary = state.session.activeQuestion
	if q.is_empty() or q.id != question_id or q.submitted:
		return false
	var allowed := false
	for option in q.options:
		allowed = allowed or option.id == answer_id
	if not allowed:
		return false
	var next := state.duplicate(true)
	var s: Dictionary = next.session
	var item: Dictionary = s.items[q.wordId]
	var correct: bool = answer_id == q.wordId
	var independent: bool = correct and not q.assisted
	item.attempts += 1
	if independent:
		item.remainingCorrect = maxi(0,int(item.remainingCorrect)-1)
		if item.everWrong:
			item.correctInStrengthening += 1
	else:
		if not item.everWrong:
			item.remainingCorrect = 2
		item.everWrong = true
		if not correct:
			s.errors += 1
	item.lastOrdinal = s.ordinal
	item.lastType = q.kind
	item.lastSlot = q.correctSlot
	s.activeQuestion.submitted = true
	s.activeQuestion.result = {"correct":correct,"assisted":q.assisted,"wordId":q.wordId,"selectedId":answer_id,"remainingCorrect":item.remainingCorrect,"wordPassed":item.remainingCorrect == 0,"strengthening":item.everWrong,"correctInStrengthening":item.correctInStrengthening}
	s.questionHistory.append({"questionId":q.id,"wordId":q.wordId,"ordinal":s.ordinal,"correct":correct,"assisted":q.assisted})
	s.phase = "feedback"
	s.updatedAt = now.call()
	var complete := true
	for value in s.items.values():
		complete = complete and value.remainingCorrect == 0
	if complete:
		s.status = "completed"
		_settle(next)
	return _commit(next)

func progress() -> Dictionary:
	var result := {"passed":0,"total":0,"strengthening":0,"remaining":0,"everStrengthened":0,"errors":0}
	if state.session.is_empty():
		return result
	result.total = state.session.targetLexemeIds.size()
	result.errors = state.session.errors
	for item in state.session.items.values():
		if item.remainingCorrect == 0:
			result.passed += 1
		if item.everWrong:
			result.everStrengthened += 1
			if item.remainingCorrect > 0:
				result.strengthening += 1
				result.remaining += item.remainingCorrect
	return result

func _settle(next: Dictionary) -> void:
	var s: Dictionary = next.session
	for id in s.targetLexemeIds:
		var r := _record(next,id)
		if s.sessionId in r.sessionHistory:
			continue
		var previous: Dictionary = r.reviewState
		var wrong: bool = s.items[id].everWrong
		var streak := 0 if wrong else int(previous.get("reviewStreak",0))+1
		var interval: int = INTERVALS[clampi(streak-1,0,INTERVALS.size()-1)]
		r.firstLearned = true
		r.sessionHistory.append(s.sessionId)
		r.reviewState = {"lastReviewedAt":now.call(),"nextReviewAt":now.call()+interval*86400,"intervalDays":interval,"reviewStreak":streak,"lapseCount":int(previous.get("lapseCount",0))+int(wrong),"lastOutcome":"strengthened" if wrong else "correct"}
	_event(next,"session/"+s.sessionId,"StudySessionCompleted",{"sessionId":s.sessionId})
	_update_unlocks(next)

func _event(next: Dictionary, key: String, type: String, payload: Dictionary) -> void:
	if not next.events.has(key):
		next.events[key] = {"eventId":key,"type":type,"payload":payload,"at":now.call()}

func _update_unlocks(next: Dictionary) -> void:
	for id in next.availableDecks:
		if not content.decks.has(id) or content.decks[id].level != "scenario":
			continue
		var all_learned := true
		for word in content.decks[id].lexemeIds:
			all_learned = all_learned and next.records.get(word,record()).firstLearned
		if all_learned:
			next.unlocks[id] = true
			_event(next,"deck/"+id,"ScenarioDeckFirstLearned",{"deckId":id})
			for game in content.decks[id].linkedMinigameIds:
				next.unlocks[game] = true
				_event(next,"game/"+game,"RelatedMinigameUnlocked",{"minigameId":game})

func story_event(id: String) -> bool:
	var next := state.duplicate(true)
	for deck in content.decks.values():
		for condition in deck.unlockConditions:
			if condition.type == "story_event" and condition.id == id and deck.deckId not in next.availableDecks:
				next.availableDecks.append(deck.deckId)
				_event(next,"available/"+deck.deckId,"ScenarioDeckAvailable",{"deckId":deck.deckId})
	_update_unlocks(next)
	return _commit(next)

func discover(word_id: String, occurrence: Dictionary) -> bool:
	if not content.words.has(word_id) or not occurrence.get("isVerified",false):
		return false
	for key in ["sourceId","exampleId","ruSentence","zhTranslation","sourceType","lexemeSpanBindings"]:
		if not occurrence.has(key):
			return false
	var next := state.duplicate(true)
	var r := _record(next,word_id)
	r.discovered = true
	for old in r.sourceOccurrences:
		if old.sourceId == occurrence.sourceId and old.exampleId == occurrence.exampleId:
			return true
	r.sourceOccurrences.append(occurrence.duplicate(true))
	return _commit(next)

func set_setting(key: String, value: Variant) -> bool:
	if not state.settings.has(key):
		return false
	if key in ["teacher","reducedMotion"] and not value is bool:
		return false
	if key == "newCount" and (not P1SaveStore.whole_number(value) or value < 1):
		return false
	if key == "voiceVolume" and (not (value is int or value is float) or not is_finite(value) or value < 0 or value > 1):
		return false
	if key == "themeId" and value not in ["classroom_blackboard_v1","classroom_blackboard_muted"]:
		return false
	var next := state.duplicate(true)
	next.settings[key] = value
	return _commit(next)

func pause() -> bool:
	if state.session.is_empty() or state.session.status == "completed":
		return true
	var next := state.duplicate(true)
	next.session.status = "paused"
	return _commit(next)

func resume() -> bool:
	if state.session.is_empty():
		return false
	var next := state.duplicate(true)
	if next.session.status == "paused": next.session.status = "active"
	if not _upgrade_unanswered_question(next): return false
	if next == state: return true
	return _commit(next)

func _upgrade_unanswered_question(next: Dictionary) -> bool:
	# Submitted R1 feedback is immutable. Only an unanswered old three-choice
	# question gains a fourth choice; counters, target, id and assisted flag survive.
	var s: Dictionary = next.session
	var q: Dictionary = s.activeQuestion
	if q.is_empty() or q.submitted or q.options.size() >= 4: return true
	var known: Array = []
	for id in next.records:
		if next.records[id].introduced or next.records[id].firstLearned: known.append(id)
	if known.size() < 4:
		var support: Array = []
		for id in content.words:
			if id not in known: support.append(id)
			if known.size()+support.size() >= 4: break
		if known.size()+support.size() < 4:
			error = "四选题的可用辅助词不足，当前题目与学习进度已保留。"
			return false
		# Existing preview ids may already include an unviewed support card.
		s.previewIndex = s.previewIds.size()
		s.previewIds.append_array(support)
		s.phase = "preview"
		return true
	var rng := RandomNumberGenerator.new()
	rng.seed = int(s.seed)+int(s.ordinal)*7919
	var upgraded := content.make_question(q.wordId,q.kind,known,rng,-1,4)
	if upgraded.has("error"):
		error = upgraded.error
		return false
	q.options = upgraded.options
	q.correctSlot = upgraded.correctSlot
	return true
