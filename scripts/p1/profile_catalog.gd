class_name P1ProfileCatalog
extends RefCounted
## Slot index lives outside the unchanged gameplay save schema.
var mode: String
var base: String
var directory: String
var error := ""

static func label(id: String) -> String:
	return "原默认档" if id == "legacy" else id.trim_prefix("slot_").substr(0,15)+" · "+id.right(4)

func _init(channel: String, storage := "") -> void:
	mode = channel if channel in ["DEV","PLAYTEST","RELEASE"] else "RELEASE"
	base = P1SaveStore.storage_root(storage)
	directory = base.path_join(mode)

func slots() -> Array[String]:
	var result: Array[String] = ["legacy"]
	var path := directory.path_join("profiles")
	if DirAccess.dir_exists_absolute(path):
		for id in DirAccess.get_directories_at(path):
			if P1SaveStore.valid_profile_id(id) and (FileAccess.file_exists(path.path_join(id).path_join("save.json")) or FileAccess.file_exists(path.path_join(id).path_join("save.json.bak"))):
				result.append(id)
	result.sort()
	return result

func selected() -> String:
	var path := directory.path_join("selected_profile.json")
	if FileAccess.file_exists(path):
		var value = JSON.parse_string(FileAccess.get_file_as_string(path))
		if value is Dictionary and value.get("profile") in slots():
			return value.profile
	return "legacy"

func select(id: String) -> bool:
	if id not in slots():
		error = "没有找到该独立存档。"
		return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		error = "无法保存当前档选择；原进度未修改。"
		return false
	var path := directory.path_join("selected_profile.json")
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		error = "无法写入档位选择；原进度未修改。"
		return false
	file.store_string(JSON.stringify({"profile":id}))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if not ok or DirAccess.rename_absolute(path+".tmp",path) != OK:
		error = "无法保存档位选择；原进度未修改。"
		return false
	error = ""
	return true

func create_playtest() -> String:
	if mode != "PLAYTEST":
		error = "独立试玩档仅在 PLAYTEST 创建。"
		return ""
	var parent := directory.path_join("profiles")
	if DirAccess.make_dir_recursive_absolute(parent) != OK:
		error = "无法建立试玩档目录。"
		return ""
	for attempt in range(10):
		var id := "slot_"+Time.get_datetime_string_from_system().replace("-","").replace(":","").replace("T","_")+"_"+Crypto.new().generate_random_bytes(6).hex_encode()
		if DirAccess.make_dir_absolute(parent.path_join(id)) != OK:
			continue
		var store := P1SaveStore.new(mode,base,id)
		if not store.write_save(P1SaveStore.fresh()):
			error = store.error
			return ""
		return id
	error = "未能建立唯一档位；没有覆盖已有存档。"
	return ""

func open_session(id: String) -> P1Session:
	return P1Session.new(mode,base,id)

func owns(path: String) -> bool:
	if path == directory:
		return true
	for id in slots():
		if id != "legacy" and path == directory.path_join("profiles").path_join(id):
			return true
	return false
