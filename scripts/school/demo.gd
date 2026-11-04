extends Control
## Dedicated shortcut into the same school scene, no story/save mutation.
func _ready() -> void:
	# The dedicated school starts in portrait; the shared main game keeps its layout.
	if get_tree().get_script() == null and OS.get_environment("SCHOOL_WIDTH").is_empty() and "--landscape" not in OS.get_cmdline_user_args():
		get_window().size = Vector2i(450,800)
	elif "--landscape" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1280,720)
	theme = GameUI.make_theme()
	get_window().title = "下一站，俄罗斯！ · 学校 V0.4 黑板课堂试玩"
	var school := preload("res://scenes/buildings/school.tscn").instantiate()
	school.standalone = true
	$SafeLayout.add_child(school)
	school.back_button.text = "退出课堂试玩"
	school.return_requested.connect(func(): get_tree().quit())
	print("SCHOOL_V04_SAVE=",school.study.store.path)
	if OS.has_feature("school_v04") and OS.has_feature("p1_playtest") and "--verify-school-package" in OS.get_cmdline_user_args():
		var verifier := preload("res://scripts/school/package_check.gd").new()
		verifier.view = school
		add_child(verifier)
	if OS.has_feature("school_v04") and OS.has_feature("p1_playtest") and "--verify-school-r2" in OS.get_cmdline_user_args():
		var probe := preload("res://scripts/school/playthrough_probe.gd").new()
		probe.app = self
		probe.view = school
		add_child(probe)
