class_name SchoolContent
extends RefCounted
## No generated vocabulary, audio or story examples. IDs are the shared identity.
var words: Dictionary = {}
var decks: Dictionary = {}
var letters: Array = []
var errors: Array[String] = []

func _init() -> void:
	var vocabulary = _json("vocabulary").get("lexemes", [])
	for word in vocabulary:
		if not word is Dictionary or not word.get("id") is String or words.has(word.id):
			errors.append("词条 ID 无效或重复")
			continue
		if not word.get("displayRu") is String or word.displayRu.is_empty() or not word.get("zhMeanings") is Array or word.zhMeanings.is_empty():
			errors.append("词条缺少俄语或中文")
			continue
		words[word.id] = word
	for deck in _json("decks").get("decks", []):
		if decks.has(deck.deckId):
			errors.append("重复词书")
		decks[deck.deckId] = deck
		for id in deck.lexemeIds:
			if not words.has(id):
				errors.append("词书引用不存在："+id)
	letters = _json("alphabet").get("letters", [])
	var unique := {}
	for letter in letters:
		if unique.has(letter.lower):
			errors.append("重复字母")
		unique[letter.lower] = true
		if letter.lower in ["ь", "ъ"] and letter.category != "sign":
			errors.append("软硬音符分类错误")
	if unique.size() != 33:
		errors.append("需要完整 33 字母")

func _json(file: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/school/"+file+".json"))
	return parsed if parsed is Dictionary else {}

func has_audio(id: String) -> bool:
	var path = words.get(id, {}).get("audioRef")
	return path is String and not path.is_empty() and ResourceLoader.exists(path, "AudioStream")

func make_question(id: String, kind: String, known: Array, rng: RandomNumberGenerator, previous_slot := -1, option_count := 4) -> Dictionary:
	if not words.has(id) or kind not in ["ZH_TO_RU", "RU_TO_ZH", "AUDIO_TO_RU"]:
		return {"error":"词条或题型无效"}
	if kind == "AUDIO_TO_RU" and not has_audio(id):
		return {"error":"未提供真实音频，听音题不可用"}
	var word: Dictionary = words[id]
	var options: Array = [{"id":id, "text":_option(word, kind)}]
	var pool := known.duplicate()
	_shuffle(pool, rng)
	# Exclude overlapping meanings even in the opposite direction: no synonym traps.
	for other in pool:
		if other == id or not words.has(other):
			continue
		var candidate: Dictionary = words[other]
		var ambiguous: bool = candidate.displayRu == word.displayRu
		for meaning in candidate.zhMeanings:
			if meaning in word.zhMeanings:
				ambiguous = true
		var text := _option(candidate, kind)
		for option in options:
			if option.text == text:
				ambiguous = true
		if not ambiguous:
			options.append({"id":other,"text":text})
		if options.size() >= clampi(option_count, 2, 4):
			break
	if options.size() < clampi(option_count,2,4):
		return {"error":"有效干扰项不足，请先预习辨认辅助词；本题需要 %d 个互异选项。" % clampi(option_count,2,4)}
	_shuffle(options, rng)
	var slot := 0
	for i in options.size():
		if options[i].id == id:
			slot = i
	if slot == previous_slot:
		var swap := (slot + 1) % options.size()
		var value = options[swap]
		options[swap] = options[slot]
		options[slot] = value
		slot = swap
	return {"wordId":id,"kind":kind,"prompt":word.zhMeanings[0] if kind == "ZH_TO_RU" else (word.displayRu if kind == "RU_TO_ZH" else "听发音，选俄语"),"options":options,"correctSlot":slot,"assisted":false,"submitted":false,"result":{}}

func _option(word: Dictionary, kind: String) -> String:
	return word.zhMeanings[0] if kind == "RU_TO_ZH" else word.displayRu

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size()-1, 0, -1):
		var j := rng.randi_range(0, i)
		var value = values[j]
		values[j] = values[i]
		values[i] = value
