class_name SchoolProgressStore
extends RefCounted
## Independent versioned sidecar in the existing mode/profile directory.
var path: String
var error := ""
var notice := ""
var blocked := false

func _init(directory: String) -> void:
	path = directory.path_join("school_v04.json")

static func fresh() -> Dictionary:
	return {"schemaVersion":1,"revision":0,"records":{},"alphabet":{},"session":{},"events":{},"unlocks":{},"availableDecks":["basic.demo"],"settings":{"newCount":5,"teacher":true,"reducedMotion":false,"voiceVolume":0.8,"themeId":"classroom_blackboard_v1"}}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("schemaVersion") != 1:
		return false
	for key in ["records","alphabet","session","events","unlocks","settings"]:
		if not value.get(key) is Dictionary:
			return false
	if not value.get("availableDecks") is Array or not P1SaveStore.whole_number(value.get("revision")):
		return false
	for key in ["newCount","teacher","reducedMotion","voiceVolume","themeId"]:
		if not value.settings.has(key):
			return false
	if not value.settings.teacher is bool or not value.settings.reducedMotion is bool or not value.settings.themeId is String:
		return false
	if not P1SaveStore.whole_number(value.settings.newCount) or value.settings.newCount < 1:
		return false
	if not (value.settings.voiceVolume is float or value.settings.voiceVolume is int) or not is_finite(value.settings.voiceVolume) or value.settings.voiceVolume < 0 or value.settings.voiceVolume > 1:
		return false
	for letter in value.alphabet.values():
		if not letter is Dictionary or not letter.get("viewed") is bool or not letter.get("passed") is bool or (letter.passed and not letter.viewed):
			return false
	for event in value.events.values():
		if not event is Dictionary or not event.get("eventId") is String or not event.get("type") is String or not event.get("payload") is Dictionary or not P1SaveStore.whole_number(event.get("at")):
			return false
	for record in value.records.values():
		if not record is Dictionary:
			return false
		for key in ["discovered","introduced","firstLearned"]:
			if not record.get(key) is bool:
				return false
		if not record.get("sourceOccurrences") is Array or not record.get("reviewState") is Dictionary or not record.get("sessionHistory") is Array:
			return false
		for source in record.sourceOccurrences:
			if not source is Dictionary:
				return false
			for key in ["sourceId","exampleId","ruSentence","zhTranslation","sourceType"]:
				if not source.get(key) is String:
					return false
		if not record.reviewState.is_empty():
			for key in ["lastReviewedAt","nextReviewAt","intervalDays","reviewStreak","lapseCount"]:
				if not P1SaveStore.whole_number(record.reviewState.get(key)):
					return false
			if not record.reviewState.get("lastOutcome") is String:
				return false
	if value.session.is_empty():
		return true
	var s: Dictionary = value.session
	for key in ["sessionId","mode","deckId","status","phase"]:
		if not s.get(key) is String:
			return false
	for key in ["items","activeQuestion"]:
		if not s.get(key) is Dictionary:
			return false
	for key in ["targetLexemeIds","pendingQueue","questionHistory","previewIds"]:
		if not s.get(key) is Array:
			return false
	for key in ["seed","ordinal","previewIndex","errors","startedAt","updatedAt","readyAt"]:
		if not P1SaveStore.whole_number(s.get(key)):
			return false
	if s.status not in ["active","paused","completed"] or s.phase not in ["preview","quiz","feedback","waiting","summary"]:
		return false
	var distinct := {}
	for id in s.targetLexemeIds:
		if not id is String or distinct.has(id) or not s.items.get(id) is Dictionary:
			return false
		distinct[id] = true
		var item: Dictionary = s.items[id]
		if not P1SaveStore.whole_number(item.get("remainingCorrect")) or item.remainingCorrect > 2 or not item.get("everWrong") is bool:
			return false
		for key in ["attempts","correctInStrengthening"]:
			if not P1SaveStore.whole_number(item.get(key)):
				return false
		if not item.get("lastOrdinal") is int and not item.get("lastOrdinal") is float:
			return false
		if not item.get("lastType") is String or not item.has("lastSlot"):
			return false
		if item.correctInStrengthening > 2 or (not item.everWrong and item.remainingCorrect > 1):
			return false
		if (item.everWrong and item.remainingCorrect != 2-item.correctInStrengthening) or (not item.everWrong and item.correctInStrengthening != 0):
			return false
	var queued := {}
	for id in s.pendingQueue:
		if not distinct.has(id) or queued.has(id):
			return false
		queued[id] = true
	if queued.size() != distinct.size():
		return false
	for history in s.questionHistory:
		if not history is Dictionary or not distinct.has(history.get("wordId")) or not P1SaveStore.whole_number(history.get("ordinal")):
			return false
		if not history.get("questionId") is String or not history.get("correct") is bool or not history.get("assisted") is bool:
			return false
	if distinct.is_empty() or s.items.size() != distinct.size() or s.previewIndex > s.previewIds.size():
		return false
	if s.status == "completed":
		for item in s.items.values():
			if item.remainingCorrect != 0:
				return false
	var q: Dictionary = s.activeQuestion
	if not q.is_empty():
		if not distinct.has(q.get("wordId")) or not q.get("options") is Array or q.options.size() < 2 or not q.get("result") is Dictionary:
			return false
		if not q.get("submitted") is bool or not q.get("assisted") is bool or not q.get("id") is String:
			return false
		if q.get("kind") not in ["ZH_TO_RU","RU_TO_ZH","AUDIO_TO_RU"] or not q.get("prompt") is String:
			return false
		var ids := {}
		var texts := {}
		for option in q.options:
			if not option is Dictionary or not option.get("id") is String or not option.get("text") is String or ids.has(option.id) or texts.has(option.text):
				return false
			ids[option.id] = true
			texts[option.text] = true
		if not ids.has(q.wordId) or not P1SaveStore.whole_number(q.get("correctSlot")) or q.correctSlot >= q.options.size() or q.options[int(q.correctSlot)].id != q.wordId:
			return false
		if q.submitted:
			for key in ["correct","assisted","wordPassed","strengthening"]:
				if not q.result.get(key) is bool:
					return false
			for key in ["wordId","selectedId"]:
				if not q.result.get(key) is String:
					return false
			if not ids.has(q.result.selectedId) or q.result.wordId != q.wordId:
				return false
			for key in ["remainingCorrect","correctInStrengthening"]:
				if not P1SaveStore.whole_number(q.result.get(key)) or q.result[key] > 2:
					return false
	return true

static func migrate(value: Variant) -> Variant:
	# Additive migration for early school schema; unrelated main save is never read.
	if value is Dictionary and value.get("schemaVersion") == 0 and value.get("records") is Dictionary and value.get("session",{}).is_empty():
		var result := fresh()
		result.records = value.records.duplicate(true)
		result.alphabet = value.get("alphabet",{}).duplicate(true)
		return result
	return value

func _parse(file: String) -> Variant:
	if not FileAccess.file_exists(file):
		return null
	var parser := JSON.new()
	return migrate(parser.data) if parser.parse(FileAccess.get_file_as_string(file)) == OK else null

func read_save() -> Dictionary:
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".bak"):
		return fresh()
	var value = _parse(path)
	if value is Dictionary and P1SaveStore.whole_number(value.get("schemaVersion")) and value.schemaVersion > 1:
		blocked = true
		error = "学校存档版本较新，已保留原文件；请使用对应版本。"
		return fresh()
	if valid(value):
		return value
	value = _parse(path+".bak")
	if valid(value):
		if FileAccess.file_exists(path) and DirAccess.rename_absolute(path,path+".corrupt-"+str(Time.get_ticks_usec())) != OK:
			blocked = true
			error = "无法保留异常学校存档，未覆盖文件。"
			return fresh()
		notice = "已保留异常学校存档并恢复有效备份。"
		return value
	blocked = true
	error = "学校存档损坏且无有效备份。原文件已保留，未清空进度。"
	return fresh()

func write_save(value: Dictionary) -> bool:
	if blocked or not valid(value):
		error = error if blocked else "学校存档校验失败，操作未提交。"
		return false
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		error = "无法创建学校存档目录。"
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		error = "无法写入学校存档。"
		return false
	file.store_string(JSON.stringify(value,"\t"))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if not ok or not valid(_parse(path+".tmp")):
		error = "学校存档写入未完成。"
		return false
	if FileAccess.file_exists(path) and valid(_parse(path)) and DirAccess.copy_absolute(path,path+".bak") != OK:
		error = "无法保留学校存档备份。"
		return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK:
		error = "无法提交学校存档。"
		return false
	error = ""
	return true
