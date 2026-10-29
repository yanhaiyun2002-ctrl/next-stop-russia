extends SceneTree
const PREVIEWS = preload("res://scripts/dev_tools/module_preview.gd")
var checks: Array[Dictionary] = []
var evidence := ""
var app: Control

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, name: String) -> void:
	checks.append({"passed":ok,"name":name})
	if not ok:
		push_error(name)

func _frames(count := 8) -> void:
	for i in range(count):
		await process_frame

func _settle() -> void:
	await _frames()
	var deadline := Time.get_ticks_msec()+5000
	while app.transitioning or not app.safe_layout.is_layout_settled():
		if Time.get_ticks_msec() > deadline:
			check(false,"模式测试布局稳定超时")
			return
		await process_frame
	await _frames()

func _click(control: Control) -> void:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
		parent = parent.get_parent()
	await _settle()
	var point := control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event,true)
		await _frames(2)
	await _settle()

func _picture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(evidence.path_join(name+".png")) == OK,"真实截图 "+name)

func _unit() -> void:
	var bad_args := ["--dev","--mode=DEV","--technical-map","--preview=q02","--name-pending","--cat-spot=under_bed","--verify-p1-package"]
	for features in [[],["nsr_release"],["nsr_release","nsr_dev"],["nsr_dev","p1_playtest"]]:
		check(P1RuntimeMode.resolve(features,bad_args) == "RELEASE","RELEASE/未知/冲突构建失败闭合 "+str(features))
	check(P1RuntimeMode.resolve(["p1_playtest"],bad_args) == "PLAYTEST","PLAYTEST不接受DEV提权参数")
	check(P1RuntimeMode.resolve(["nsr_dev"],[]) == "DEV","DEV构建明确允许开发能力")
	check(P1RuntimeMode.resolve(["editor"],["--dev"]) == "DEV","源工程显式DEV")
	check(P1RuntimeMode.resolve(["editor"],["--dev","--mode=RELEASE"]) == "RELEASE","源工程RELEASE更严格模式优先")
	var base := evidence.path_join("unit-data")
	for mode in ["DEV","PLAYTEST","RELEASE"]:
		var session := P1Session.new(mode,base)
		check(session.advance_arrival(),"模式独立合法保存 "+mode)
		check(session.store.directory == base.path_join(mode),"模式独立目录 "+mode)
	var complete := PREVIEWS.fixture("home",base)
	check(complete != null and P1SaveStore.valid(complete.state),"通过真实领域事件构造完成档")
	var legacy := P1Session.new("PLAYTEST",base)
	check(legacy.store.write_save(complete.state),"仅在隔离证据目录模拟原已完成试玩档")
	var old_hash := FileAccess.get_sha256(legacy.store.directory.path_join("save.json"))
	var catalog := P1ProfileCatalog.new("PLAYTEST",base)
	var first := catalog.create_playtest()
	var second := catalog.create_playtest()
	check(first != second and not first.is_empty() and not second.is_empty(),"新档唯一且不替换已有档")
	check(catalog.select(first) and P1ProfileCatalog.new("PLAYTEST",base).selected() == first,"独立档选择跨启动持久化")
	var player := catalog.open_session(first)
	check(player.state.revision == 0 and player.state.quests.q00_arrival == "active","新PLAYTEST档从Q00正常开始")
	check(FileAccess.get_sha256(legacy.store.directory.path_join("save.json")) == old_hash,"创建和切换新档后原档字节不变")
	check(catalog.select("legacy") and catalog.open_session("legacy").state.story.cityUnlocked,"原已完成档继续可读")
	check(not catalog.select("../../RELEASE") and P1ProfileCatalog.new("RELEASE",base).create_playtest().is_empty(),"拒绝越界ID和RELEASE新测试档")
	var invalid := P1SaveStore.new("PLAYTEST",base,"../../RELEASE")
	check(invalid.blocked and not invalid.write_save(P1SaveStore.fresh()),"底层profile ID路径穿越被拒绝")
	check(FileAccess.get_sha256(legacy.store.directory.path_join("save.json")) == old_hash,"恶意profile ID不覆盖原存档")
	check(player.advance_arrival(),"新档正常事件写入并生成备份")
	var path := player.store.directory.path_join("save.json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{corrupt")
	file.close()
	var recovered := catalog.open_session(first)
	check(not recovered.store.blocked and not recovered.store.notice.is_empty() and P1SaveStore.valid(recovered.state),"独立档保留原损坏恢复机制")
	check(FileAccess.file_exists(path+".bak"),"独立档备份保留")
	for module in PREVIEWS.MODULES:
		var prior := ""
		for repeat in range(2):
			var fixture := PREVIEWS.fixture(module,base)
			check(fixture != null and P1SaveStore.valid(fixture.state),"模块合法状态 "+module+str(repeat))
			check(fixture.store.directory.begins_with(base.path_join("DEV/previews")+"/") and fixture.store.directory != prior,"模块重复预览新目录 "+module+str(repeat))
			prior = fixture.store.directory
			var reward_count: int = fixture.state.rewards.size()
			if module in ["q02","q03","home"]:
				check(fixture.pet_reaction_completed() and fixture.state.rewards.size() == reward_count,"模块不重复首遇奖励 "+module+str(repeat))
	check(PREVIEWS.fixture("../../PLAYTEST",base) == null,"预览ID白名单不拼接任意路径")
	check(FileAccess.get_sha256(legacy.store.directory.path_join("save.json")) == old_hash,"所有DEV预览后PLAYTEST完成档不变")
	check(P1Session.new("DEV",base).state.story.arrivalIndex == 1 and P1Session.new("RELEASE",base).state.story.arrivalIndex == 1,"预览不污染常规DEV与RELEASE")

func _run() -> void:
	create_timer(150).timeout.connect(func(): quit(124))
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(evidence)
	_unit()
	root.size = Vector2i(360,780) if OS.get_environment("P1_FULL_PORTRAIT") == "1" else Vector2i(1280,720)
	if not P1RuntimeMode.new().can_dev:
		var seed := PREVIEWS.fixture("home",evidence.path_join("seed"))
		P1SaveStore.new("PLAYTEST").write_save(seed.state)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _settle()
	if app.runtime_mode.can_dev:
		var original_path: String = app.session.store.directory
		await _click(app.story_flow.dev_module_button)
		check(app.story_flow.modal_kind == "dev_modules","DEV入口通过真实点击打开菜单")
		if app.story_flow.modal_kind != "dev_modules":
			print("DEV_BUTTON_DIAGNOSTIC rect=",app.dev_tools.entry.get_global_rect()," viewport=",root.get_visible_rect()," mouse=",root.get_mouse_position()," hover=",root.gui_get_hovered_control())
			quit(1)
			return
		await _picture("dev_modules")
		for module in PREVIEWS.MODULES:
			var prior := ""
			for repeat in range(2):
				if app.story_flow.modal_kind != "dev_modules":
					await _click(app.dev_tools.entry)
				await _click(app.dev_tools.module_buttons[module])
				check(app.preview_active and P1SaveStore.valid(app.session.state) and app.session.store.directory != prior,"实际DEV菜单重复启动 "+module+str(repeat))
				prior = app.session.store.directory
				check(app.session.store.directory != original_path,"实际预览不使用常规DEV档")
				if module == "q02":
					check(app.story_flow.modal_kind == "organization","模块直达真实整理UI")
					await _picture("dev_q02_"+str(repeat))
				elif module == "q03":
					check(app.story_flow.modal_kind == "message","模块直达原安娜消息UI")
					await _click(app.story_flow.primary_button)
					await _click(app.story_flow.primary_button)
					check(app.session.state.story.cityUnlocked and app.session.state.rewards.size() == 2,"DEV Q03通过原消息UI解锁且奖励不重复")
				elif module == "q00":
					check(app.story_flow.modal_kind == "arrival","模块直达原开场UI")
		await app.dev_tools.exit_preview()
		await _settle()
		check(not app.preview_active and app.session.store.directory == original_path and app.map_view.visible,"退出预览回原DEV流程档")
	else:
		var path: String = app.session.store.directory.path_join("save.json")
		var before := FileAccess.get_sha256(path)
		check(app.session.state.story.cityUnlocked and app.dev_tools == null,"PLAYTEST旧完成档可读且无DEV工具")
		await _click(app.story_flow.profile_button)
		await _picture("playtest_profiles")
		await _click(app.story_flow.new_profile_button)
		check(app.active_profile != "legacy" and app.session.state.revision == 0 and app.map_view.visible,"真实新建档按钮回地图且Q00未跳过")
		await _click(app.story_flow.primary_button)
		check(app.story_flow.modal_kind == "arrival" and app.session.state.story.arrivalIndex == 0,"新档通过正常入口重看开场")
		app.story_flow._clear()
		app.story_flow.show_profiles()
		await _click(app.story_flow.profile_buttons.legacy)
		check(app.session.state.story.cityUnlocked and FileAccess.get_sha256(path) == before,"实际UI切回原完成档且字节未改")
		check(not await app.activate_session(PREVIEWS.fixture("q02",app.profiles.base),true),"PLAYTEST在能力层拒绝开发预览会话")
	var failed := checks.filter(func(row):return not row.passed).size()
	var file := FileAccess.open(evidence.path_join("modes_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"mode":app.runtime_mode.mode,"display":DisplayServer.get_name(),"note":"synthetic input; not human or physical phone acceptance"},"\t"))
	file.close()
	print("P1_MODES passed=%d failed=%d" % [checks.size()-failed,failed])
	quit(0 if failed == 0 else 1)
