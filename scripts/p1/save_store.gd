class_name P1SaveStore
extends RefCounted
## E-drive by default here. Atomic replacement, retained backup, no silent reset.
const SCHEMA := 1
var directory: String
var error := ""
var notice := ""
var blocked := false

func _init(channel := "PLAYTEST", base := "") -> void:
	var storage_root := base
	if storage_root.is_empty():
		storage_root = OS.get_environment("NSR_DATA_ROOT")
	if storage_root.is_empty():
		storage_root = ProjectSettings.globalize_path("res://.local-dev/player-data") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("player-data")
	directory = storage_root.path_join(channel)

static func fresh() -> Dictionary:
	return {"schemaVersion": SCHEMA, "revision": 0,
		"quests": {"q00_arrival":"active", "q01_cat":"locked", "q02_organize":"locked", "q03_anna_message":"locked"},
		"story": {"arrivalIndex":0, "annaMessageIndex":0, "hasHomeKey":false, "homeEntered":false, "cityUnlocked":false},
		"cat": {"breedId":"siberian_forest", "firstPetCompleted":false, "namePending":false, "displayName":"", "spotId":"", "rounds":0, "roundId":0, "petRoundId":0},
		"organization": {"tutorialCompleted":false, "placements":{}, "history":[], "journalDate":""}, "rewards":{}}

static func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if not whole_number(value.get("schemaVersion")) or value.schemaVersion != SCHEMA:
		return false
	var baseline := fresh()
	for section in ["quests", "story", "cat", "organization", "rewards"]:
		if not value.get(section) is Dictionary:
			return false
	for section in ["quests", "story", "cat", "organization"]:
		for key in baseline[section]:
			if not value[section].has(key):
				return false
			var expected := typeof(baseline[section][key])
			var actual := typeof(value[section][key])
			if expected != actual and not (expected == TYPE_INT and actual == TYPE_FLOAT):
				return false
	if not value.get("revision") is float and not value.get("revision") is int:
		return false
	var story: Dictionary = value.story
	var cat: Dictionary = value.cat
	var org: Dictionary = value.organization
	for number in [value.revision, story.arrivalIndex, story.annaMessageIndex, cat.rounds, cat.roundId, cat.petRoundId]:
		if not whole_number(number):
			return false
	if cat.petRoundId > cat.roundId or cat.rounds > cat.petRoundId or cat.breedId != "siberian_forest":
		return false
	if story.arrivalIndex < 0 or story.arrivalIndex > 5 or story.annaMessageIndex < 0 or story.annaMessageIndex > 2:
		return false
	if not cat.spotId.is_empty() and P1Content.spot(cat.spotId).is_empty():
		return false
	if cat.rounds < 0 or cat.displayName.length() > 20:
		return false
	if not cat.firstPetCompleted and (not cat.displayName.is_empty() or cat.rounds != 0):
		return false
	if story.hasHomeKey != (story.arrivalIndex >= 3) or (story.annaMessageIndex > 0 and not org.tutorialCompleted):
		return false
	for key in value.rewards:
		if key not in ["cat_first_meeting_v1", "organization_tutorial_v1"] or not value.rewards[key] is bool or value.rewards[key] != true:
			return false
	if bool(value.rewards.get("organization_tutorial_v1", false)) != org.tutorialCompleted:
		return false
	for placements in [org.placements] + org.history:
		if not placements is Dictionary:
			return false
		for id in placements:
			if not P1Content.data().itemNames.has(id) or not placements[id] is String or not P1Content.data().binNames.has(placements[id]):
				return false
	var named: bool = cat.firstPetCompleted and not cat.displayName.strip_edges().is_empty() and not cat.namePending
	if cat.namePending != (cat.firstPetCompleted and cat.displayName.is_empty()):
		return false
	if bool(value.rewards.get("cat_first_meeting_v1", false)) != cat.firstPetCompleted:
		return false
	if cat.firstPetCompleted and not story.homeEntered:
		return false
	if org.tutorialCompleted and not named:
		return false
	if story.homeEntered and (not story.hasHomeKey or story.arrivalIndex != 5):
		return false
	if story.cityUnlocked and (not named or not org.tutorialCompleted or story.annaMessageIndex != 2):
		return false
	if (story.annaMessageIndex == 2) != story.cityUnlocked or cat.displayName != cat.displayName.strip_edges():
		return false
	var expected_quests := ["completed" if story.homeEntered else "active", "completed" if named else ("active" if story.homeEntered else "locked"), "completed" if org.tutorialCompleted else ("active" if named else "locked"), "completed" if story.cityUnlocked else ("active" if org.tutorialCompleted else "locked")]
	for index in range(baseline.quests.size()):
		if value.quests[baseline.quests.keys()[index]] != expected_quests[index]:
			return false
	return true

static func whole_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and floorf(float(value)) == value

static func _parse_file(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data

func read_save() -> Dictionary:
	var path := directory.path_join("save.json")
	if not FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			return _recover(path)
		return fresh()
	var parsed = _parse_file(path)
	# Future schema must be handled by a future build, never overwritten.
	if parsed is Dictionary and whole_number(parsed.get("schemaVersion")) and parsed.schemaVersion > SCHEMA:
		blocked = true
		error = "存档版本高于当前版本；原文件已保留，请使用对应版本。"
		return fresh()
	if valid(parsed):
		return parsed
	return _recover(path)

func _recover(path: String) -> Dictionary:
	var parsed = _parse_file(path + ".bak") if FileAccess.file_exists(path + ".bak") else null
	if valid(parsed):
		if FileAccess.file_exists(path):
			var quarantine := path + ".corrupt-" + str(Time.get_ticks_usec())
			if DirAccess.rename_absolute(path, quarantine) != OK:
				blocked = true
				error = "无法保留损坏存档；请检查目录权限。"
				return fresh()
		notice = "检测到异常存档，已保留原文件并恢复上一份有效备份。"
		return parsed
	blocked = true
	error = "存档损坏且没有有效备份。文件已保留；请反馈或使用新的独立试玩数据目录。"
	return fresh()

func write_save(value: Dictionary) -> bool:
	if blocked or not valid(value):
		if error.is_empty():
			error = "存档状态校验失败；本次操作尚未保存。"
		return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		error = "无法创建存档目录：" + directory
		return false
	var path := directory.path_join("save.json")
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		error = "无法写入存档，请检查目录权限。"
		return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var written_ok := file.get_error() == OK
	file.close()
	if not written_ok or not valid(_parse_file(temp)):
		error = "写入未完成，进度仍保留在原存档。"
		return false
	if FileAccess.file_exists(path):
		# Copy only a known-valid current save; preserve a recovered backup.
		if valid(_parse_file(path)):
			if DirAccess.copy_absolute(path, path + ".bak") != OK:
				error = "无法保留备份，本次操作尚未保存。"
				return false
	if DirAccess.rename_absolute(temp, path) != OK:
		error = "无法替换存档，本次操作尚未保存。"
		return false
	error = ""
	return true
