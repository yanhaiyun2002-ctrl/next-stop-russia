extends SceneTree
## Runs in a separate empty audit project, never shipped in game packages.
func _initialize() -> void:
	var mode := OS.get_environment("NSR_AUDIT_MODE")
	var loaded := ProjectSettings.load_resource_pack(OS.get_environment("NSR_AUDIT_PACK"))
	var dev_present := FileAccess.file_exists("res://scripts/dev_tools/module_preview.gd.remap")
	var verifier_present := FileAccess.file_exists("res://scripts/p1/package_check.gd.remap")
	var result := {"loaded":loaded,"mode":mode,"devToolPresent":dev_present,"packageVerifierPresent":verifier_present,"corePresent":FileAccess.file_exists("res://scripts/main.gd.remap"),"failed":0}
	if not loaded or dev_present != (mode == "DEV") or not result.corePresent or (mode == "RELEASE" and verifier_present):
		result.failed = 1
	var file := FileAccess.open(OS.get_environment("NSR_AUDIT_OUT"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("PACK_MODE_AUDIT ",JSON.stringify(result))
	quit(result.failed)
