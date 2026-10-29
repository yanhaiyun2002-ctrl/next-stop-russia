class_name P1RuntimeMode
extends RefCounted
## Product mode is a build capability, never an environment-variable permission.
var mode: String
var can_dev: bool

func _init() -> void:
	var features: Array[String] = []
	for feature in ["editor","nsr_dev","p1_playtest","nsr_release","p0_test"]:
		if OS.has_feature(feature):
			features.append(feature)
	mode = resolve(features,OS.get_cmdline_user_args())
	can_dev = mode == "DEV"

static func resolve(features: Array, arguments: Array) -> String:
	if "nsr_release" in features:
		return "RELEASE"
	var build_modes := int("nsr_dev" in features)+int("p1_playtest" in features)+int("p0_test" in features)
	if build_modes > 1:
		return "RELEASE"
	if "nsr_dev" in features or "p0_test" in features:
		return "DEV"
	if "p1_playtest" in features:
		return "PLAYTEST"
	if "editor" in features:
		if "--mode=RELEASE" in arguments:
			return "RELEASE"
		return "DEV" if "--dev" in arguments else "PLAYTEST"
	return "RELEASE"
