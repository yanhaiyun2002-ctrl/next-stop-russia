class_name SchoolBuildInfo
extends RefCounted
const VERSION := "V0.4-R2.3-Portrait"
const BUILD_DATE := "2026-11-04"
static func log_entry(entry: String, scene: String, save_path: String) -> void:
	print("SCHOOL_BUILD ",JSON.stringify({"version":VERSION,"buildDate":BUILD_DATE,"entry":entry,"binary":OS.get_executable_path(),"scene":scene,"saveNamespace":save_path,"mode":P1RuntimeMode.new().mode}))
