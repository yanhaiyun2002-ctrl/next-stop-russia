extends "res://scripts/p1/package_check.gd"
## Reuse the existing real Q00-Q03 mouse walkthrough, then enter school via UI.
func _ready() -> void:
	var directory := OS.get_environment("SCHOOL_EVIDENCE_DIR")
	if directory.is_empty() or not OS.get_environment("NSR_DATA_ROOT").begins_with(directory):
		get_tree().quit(2); return
	OS.set_environment("P1_PACKAGE_EVIDENCE",directory)
	super._ready()
func _finish() -> void:
	var failed: int = checks.filter(func(row): return not row.passed).size()
	var out := FileAccess.open(evidence.path_join("p1_package_results.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"binary":OS.get_executable_path()},"\t")); out.close()
	if failed > 0:
		get_tree().quit(1); return
	var probe := preload("res://scripts/school/playthrough_probe.gd").new()
	probe.app = app
	probe.integrated = true
	app.add_child(probe)
