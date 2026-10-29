extends Node
## Exported only with DEV; fixtures use the real domain events, never edit fields.
const MODULES := {"q00":"Q00 开场剧情", "q01":"Q01 首次找猫、抚摸与命名", "q02":"Q02 首次整理", "q03":"Q03 安娜消息与解锁", "home":"宿舍自由视觉预览"}
var app: Control
var entry: Button
var last_error := ""
var module_buttons: Dictionary = {}
var luggage_experiment: Control
var luggage_button: Button

func setup(main: Control) -> void:
	app = main
	if not app.runtime_mode.can_dev:
		queue_free()
		return
	entry = Button.new()
	entry.text = "DEV · 模块"
	entry.custom_minimum_size = Vector2(112,48)
	entry.size = entry.custom_minimum_size
	entry.pressed.connect(show_menu)
	app.add_child(entry)
	entry.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	entry.offset_left = -120
	entry.offset_right = -8
	entry.offset_top = 8
	entry.offset_bottom = 56
	_place_entry()
	app.resized.connect(_place_entry)
	_boot_arguments.call_deferred()

func _place_entry() -> void:
	entry.visible = app.preview_active

func raise_entry() -> void:
	if is_instance_valid(entry):
		_place_entry()
		app.move_child(entry,-1)

func show_menu() -> void:
	if not app.runtime_mode.can_dev:
		return
	app.story_flow._screen("dev_modules","DEV · 模块预览")
	app.story_flow._text("每次预览新建独立数据，通过原领域事件进入模块；不会覆盖完整流程档。",16)
	app.story_flow._text("当前："+app.session.store.directory,13)
	luggage_button = app.story_flow._button("行李整理 · 独立重玩",open_luggage_experiment)
	module_buttons.clear()
	for id in MODULES:
		var module: String = id
		module_buttons[id] = app.story_flow._button(MODULES[id],func(): await launch(module))
	app.story_flow._button("退出预览 · 返回 DEV 完整流程档",exit_preview)
	app.story_flow._button("关闭菜单 · 继续当前体验",app.story_flow._clear)

func open_luggage_experiment() -> bool:
	if not app.runtime_mode.can_dev or app.transitioning or is_instance_valid(luggage_experiment):
		return false
	# Does not create fixtures, switch sessions, advance quests or write profiles.
	luggage_experiment = load("res://scripts/p1/luggage_tidy/view.gd").new()
	app.add_child(luggage_experiment)
	luggage_experiment.setup(app)
	luggage_experiment.closed.connect(func(): luggage_experiment = null)
	return true

static func fixture(module: String, base: String) -> P1Session:
	if module not in MODULES and module != "name_pending":
		return null
	var parent := base.path_join("DEV/previews").path_join(module)
	if DirAccess.make_dir_recursive_absolute(parent) != OK:
		return null
	var id := "run_"+Time.get_datetime_string_from_system().replace(":","")+"_"+Crypto.new().generate_random_bytes(6).hex_encode()
	if DirAccess.make_dir_absolute(parent.path_join(id)) != OK:
		return null
	var player := P1Session.new("DEV/previews/"+module+"/"+id,base)
	if not player.store.write_save(player.state):
		return null
	if module == "q00":
		return player
	for i in range(5):
		if not player.advance_arrival():
			return null
	if not player.enter_home():
		return null
	if module == "q01":
		return player
	if not player.choose_spot("by_window") or not player.pet_reaction_completed():
		return null
	if module == "name_pending":
		return player
	if not player.confirm_name("Снег"):
		return null
	if module == "q02":
		return player
	var model = player.luggage_model()
	var positions := {"passport":Vector2(83,332.5),"washbag":Vector2(206.5,305),"textbook":Vector2(360,290),"scarf":Vector2(498.5,260)}
	for item_id in positions:
		if not model.place(item_id,{"position":positions[item_id],"turn":0}):
			return null
	if not player.save_luggage(model.snapshot()):
		return null
	if not player.complete_organization():
		return null
	if module == "home":
		if not player.advance_message() or not player.advance_message():
			return null
	return player

func launch(module: String) -> bool:
	if not app.runtime_mode.can_dev or app.transitioning:
		return false
	var player := fixture(module,app.profiles.base)
	if player == null or not P1SaveStore.valid(player.state):
		last_error = "预览状态建立失败，原存档保留。"
		app.story_flow._text(last_error,16)
		return false
	if not await app.activate_session(player,true):
		return false
	if module == "q00":
		app.story_flow.show_arrival()
	else:
		app.story_flow.start()
	return true

func exit_preview() -> void:
	if app.runtime_mode.can_dev:
		await app.activate_session(app.profiles.open_session(app.profiles.selected()))

func _boot_arguments() -> void:
	var arguments := OS.get_cmdline_user_args()
	if "--luggage-prototype" in arguments:
		open_luggage_experiment()
		return
	if "--technical-map" in arguments:
		app.technical_mode = true
		return
	if "--name-pending" in arguments:
		await launch("name_pending")
		return
	for argument in arguments:
		if argument.begins_with("--preview="):
			var module := argument.trim_prefix("--preview=")
			if module in MODULES:
				await launch(module)
			else:
				show_menu()
			return
		if argument.begins_with("--cat-spot="):
			var spot := argument.trim_prefix("--cat-spot=")
			if not P1Content.spot(spot).is_empty() and await launch("q01"):
				await app.room_entered
				app.active_room.p1_controller.encounter.begin_round(true,spot)
			return
