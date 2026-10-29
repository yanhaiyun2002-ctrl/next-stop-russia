extends SceneTree
func _initialize() -> void:
	for mode in ["DEV","PLAYTEST","RELEASE"]:
		if not P1SaveStore.new(mode).write_save(P1SaveStore.fresh()):
			quit(1)
			return
	quit()
