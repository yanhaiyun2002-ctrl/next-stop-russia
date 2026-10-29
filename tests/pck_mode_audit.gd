extends SceneTree
## Runs in a separate empty audit project, never shipped in game packages.
func _initialize() -> void:
	var mode := OS.get_environment("NSR_AUDIT_MODE")
	var loaded := ProjectSettings.load_resource_pack(OS.get_environment("NSR_AUDIT_PACK"))
	var dev_present := FileAccess.file_exists("res://scripts/dev_tools/module_preview.gd.remap")
	var verifier_present := FileAccess.file_exists("res://scripts/p1/package_check.gd.remap")
	var luggage_present := FileAccess.file_exists("res://scripts/p1/luggage_tidy/view.gd.remap") and FileAccess.file_exists("res://scripts/p1/luggage_tidy/model.gd.remap")
	var player_data_absent := not DirAccess.dir_exists_absolute("res://builds") and not DirAccess.dir_exists_absolute("res://build") and not DirAccess.dir_exists_absolute("res://dist") and not DirAccess.dir_exists_absolute("res://.local-dev")
	var map_present := FileAccess.file_exists("res://data/city_map.json") and ResourceLoader.exists("res://assets/city_map/st_petersburg.png")
	var legacy_absent := not FileAccess.file_exists("res://scripts/p1/organization_board.gd.remap") and not FileAccess.file_exists("res://ui/organization_item.gd.remap") and not DirAccess.dir_exists_absolute("res://scripts/dev_tools/luggage_tidy")
	var result := {"loaded":loaded,"mode":mode,"devToolPresent":dev_present,"sharedLuggageRuntimePresent":luggage_present,"playerBuildDirectoriesAbsent":player_data_absent,"packageVerifierPresent":verifier_present,"corePresent":FileAccess.file_exists("res://scripts/main.gd.remap"),"failed":0}
	result["runtimeMapPresent"] = map_present
	result["legacyABCAndExperimentImplementationAbsent"] = legacy_absent
	if not loaded or dev_present != (mode == "DEV") or not luggage_present or not map_present or not legacy_absent or not player_data_absent or not result.corePresent or (mode == "RELEASE" and verifier_present):
		result.failed = 1
	var file := FileAccess.open(OS.get_environment("NSR_AUDIT_OUT"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("PACK_MODE_AUDIT ",JSON.stringify(result))
	quit(result.failed)
