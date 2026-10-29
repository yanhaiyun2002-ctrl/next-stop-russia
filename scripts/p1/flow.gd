extends Control
## First Playable UI owner. Modal tasks cannot mutate progression by closing.
var app: Control
var session: P1Session
var modal: MarginContainer
var body: VBoxContainer
var modal_kind := ""
var primary_button: Button
var name_input: LineEdit
var name_error: Label
var org_status: Label
var undo_button: Button
var reset_button: Button
var item_summary: Label
var map_entry: VBoxContainer
var map_continue: Button
var map_instruction: Label
var resume_organization := false
var organization_board: Control
var stage: P1StoryStage
var russian_line: Label
var chinese_line: Label
var profile_button: Button
var new_profile_button: Button
var profile_buttons: Dictionary = {}
var dev_module_button: Button

func setup(main: Control, player: P1Session) -> void:
	app = main
	session = player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_modal)
	map_entry = VBoxContainer.new()
	map_instruction = Label.new()
	map_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_instruction.add_theme_font_size_override("font_size",14)
	map_entry.add_child(map_instruction)
	map_continue = Button.new()
	map_continue.custom_minimum_size.y = 48
	map_continue.clip_text = true
	map_continue.add_theme_font_size_override("font_size",16)
	map_continue.pressed.connect(start)
	var entry_actions := HBoxContainer.new()
	map_entry.add_child(entry_actions)
	map_continue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_actions.add_child(map_continue)
	if app.runtime_mode.mode != "RELEASE":
		profile_button = Button.new()
		profile_button.text = "试玩档" if app.runtime_mode.mode == "PLAYTEST" else "开发档"
		profile_button.custom_minimum_size = Vector2(76,48)
		profile_button.pressed.connect(show_profiles)
		entry_actions.add_child(profile_button)
	if app.runtime_mode.can_dev:
		dev_module_button = Button.new()
		dev_module_button.text = "模块"
		dev_module_button.custom_minimum_size = Vector2(60,48)
		dev_module_button.pressed.connect(func(): app.dev_tools.show_menu())
		entry_actions.add_child(dev_module_button)
	app.map_view.install_story_entry(map_entry)
	session.changed.connect(refresh_map_entry)
	refresh_map_entry()
	primary_button = map_continue
	app.map_view.mode_label.text = app.runtime_mode.mode+" · "+("独立模块预览" if app.preview_active else P1ProfileCatalog.label(app.active_profile))
	app.get_window().title = "下一站，俄罗斯！ · "+app.runtime_mode.mode+(" · 模块预览" if app.preview_active else "")

func dispose() -> void:
	_clear()
	if session.changed.is_connected(refresh_map_entry):
		session.changed.disconnect(refresh_map_entry)
	if is_instance_valid(map_entry):
		map_entry.get_parent().remove_child(map_entry)
		map_entry.queue_free()

func show_profiles() -> void:
	if app.runtime_mode.mode == "RELEASE":
		return
	_screen("profiles", app.runtime_mode.mode+" · 独立存档")
	_text("当前目录：\n"+session.store.directory,14)
	_text("切换或新建会保留其他档位；每个档位独立保存与恢复。",16)
	profile_buttons.clear()
	for id in app.profiles.slots():
		var slot_id: String = id
		profile_buttons[id] = _button("继续 · "+P1ProfileCatalog.label(id),func(): await app.choose_profile(slot_id))
	if app.runtime_mode.mode == "PLAYTEST":
		new_profile_button = _button("新建独立试玩档 · 从 Q00 开始",func(): await app.create_playtest_profile())
	if app.runtime_mode.can_dev and app.dev_tools != null:
		_button("DEV 模块预览",app.dev_tools.show_menu)
	_button("返回城市地图",_clear)

func refresh_map_entry() -> void:
	app.map_view.update_locks(not session.state.story.cityUnlocked)
	app.map_view.board.task_id = &"" if session.state.story.cityUnlocked else &"dormitory"
	app.map_view.task_button.disabled = session.state.story.cityUnlocked
	app.map_view.board.queue_redraw()
	if not is_instance_valid(map_instruction):
		return
	if session.store.blocked:
		map_instruction.text = session.store.error
		map_continue.disabled = true
	elif not session.state.story.homeEntered:
		map_instruction.text = "初到圣彼得堡 · 先与安娜和管理员见面，收好房间钥匙。"
		map_continue.text = "继续抵达引导" if session.state.revision > 0 else "开始抵达引导"
	elif session.state.cat.namePending:
		map_instruction.text = "猫咪还在等你确认名字。命名前，其他地点仍未解锁。"
		map_continue.text = "继续给猫命名 · 必做"
	elif session.state.quests.q01_cat != "completed":
		map_instruction.text = "进入小屋，与猫咪相识；之后整理行李，再查看安娜消息。"
		map_continue.text = "回小屋继续找猫"
	elif not session.state.organization.tutorialCompleted:
		map_instruction.text = "名字已记住 · 首次整理尚未完成，摆放进度会保留。"
		map_continue.text = "继续整理行李 · 必做"
	elif not session.state.story.cityUnlocked:
		map_instruction.text = "整理完成 · 回小屋阅读安娜的俄中消息。"
		map_continue.text = "继续查看安娜消息"
	else:
		map_instruction.text = "首段已完成 · 主动选择地点进入。选择地点或拖动浏览圣彼得堡。"
		map_continue.text = "回我的小屋"
	if not session.store.notice.is_empty():
		map_instruction.text += "\n" + session.store.notice

func home_entered() -> void:
	if resume_organization and not session.state.cat.namePending:
		resume_organization = false
		show_organization()

func _clear() -> void:
	if is_instance_valid(organization_board):
		organization_board._restore_host()
		remove_child(organization_board)
		organization_board.queue_free()
	organization_board = null
	if is_instance_valid(stage) and stage.get_parent() == self:
		remove_child(stage)
		stage.queue_free()
	stage = null
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
	body = null
	modal_kind = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary_button = map_continue
	if is_instance_valid(app.active_room) and app.active_room.p1_controller != null:
		app.active_room.p1_controller.encounter.set_process(true)

func _screen(kind: String, title: String) -> void:
	_clear()
	modal_kind = kind
	mouse_filter = Control.MOUSE_FILTER_STOP
	modal = MarginContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var panel := PanelContainer.new()
	var style: StyleBox = StyleBoxEmpty.new() if kind in ["arrival","message"] else GameUI.paper()
	if kind not in ["arrival","message"]:
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		panel.custom_minimum_size.y = minf(600,size.y-24)
	panel.add_theme_stylebox_override("panel", style)
	modal.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_END if kind in ["arrival","message"] else BoxContainer.ALIGNMENT_BEGIN
	body.add_theme_constant_override("separation", 7 if kind == "arrival" else 10)
	scroll.add_child(body)
	var title_label := _text(title, 19 if kind == "arrival" else 24)
	if kind in ["arrival","message"]:
		GameUI.legible(title_label)
	_layout_modal()
	if is_instance_valid(app.active_room) and app.active_room.p1_controller != null:
		app.active_room.p1_controller.encounter.set_process(false)

func _layout_modal() -> void:
	if not is_instance_valid(modal):
		return
	var portrait := size.y > size.x
	var side := (12 if portrait else 24) if modal_kind in ["arrival","organization"] else (16 if portrait else maxi(28, int((size.x - 760) / 2)))
	modal.add_theme_constant_override("margin_left", maxi(side, app.safe_layout.get_theme_constant("margin_left")))
	modal.add_theme_constant_override("margin_right", maxi(side, app.safe_layout.get_theme_constant("margin_right")))
	modal.add_theme_constant_override("margin_top", maxi(12,app.safe_layout.get_theme_constant("margin_top")))
	modal.add_theme_constant_override("margin_bottom", maxi(12,app.safe_layout.get_theme_constant("margin_bottom")))

func _text(value: String, font_size := 19) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color",GameUI.INK)
	body.add_child(label)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.clip_text = true
	button.tooltip_text = value
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	style_button(button)
	button.pressed.connect(callback)
	body.add_child(button)
	return button

func style_button(button: Button) -> void:
	GameUI.button(button)

func _save_error() -> void:
	_text(session.last_error if not session.last_error.is_empty() else "操作尚未完成，请重试。", 16)

func show_title() -> void:
	_screen("title", "下一站，俄罗斯！")
	_text("圣彼得堡，新的生活从一间小屋开始。")
	_text("P1-01 受控试玩 · Q00～Q03\nTEMP_REPLACE_REQUIRED\n几何占位不代表最终宿舍视觉。对白 TEMP_TEXT / REVIEW_PENDING。", 16)
	if not session.store.notice.is_empty():
		_text(session.store.notice, 16)
	if session.store.blocked:
		_text(session.store.error)
		return
	primary_button = _button("继续旅程" if session.state.revision > 0 else "开始旅程", start)
	_text("自动保存。关闭窗口后可继续；暂无配音，俄语和中文字幕同步显示。", 16)

func start() -> void:
	if session.store.blocked:
		return
	if session.state.story.homeEntered:
		resume_organization = session.state.quests.q01_cat == "completed" and not session.state.organization.tutorialCompleted
		_clear()
		app.enter_building(&"dormitory")
	else:
		show_arrival()

func show_arrival() -> void:
	if session.state.story.arrivalIndex >= P1Content.data().arrival.size():
		_screen("arrival", "房间钥匙已收好")
		_add_stage("home.background", "")
		_text("安娜和管理员的引导结束了。进去看看新房间吧。")
		primary_button = _button("用钥匙进入宿舍", func():
			if session.enter_home():
				_clear()
				app.enter_building(&"dormitory")
			else:
				_save_error())
		return
	var line: Dictionary = P1Content.data().arrival[int(session.state.story.arrivalIndex)]
	_screen("arrival", line.speaker)
	_add_stage("story.arrival" if session.state.story.arrivalIndex < 2 else "story.reception", "story."+("anna" if line.speakerId == "anna" else "admin"))
	russian_line = _dialogue_text(line.ru, Color("fff0d9"), 23)
	chinese_line = _dialogue_text(line.zhSubtitle, Color("dcecf5"), 19)
	primary_button = _button("收好钥匙，继续" if line.id == "q00.maria.01" else "继续", func():
		if session.advance_arrival():
			show_arrival()
		else:
			_save_error())
	primary_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	primary_button.custom_minimum_size.x = 160

func _dialogue_text(value: String, color: Color, font_size: int) -> Label:
	var panel := PanelContainer.new()
	# The generated ornate corners belong on larger cards. Compact subtitles use
	# the same palette with a native thin frame to preserve readable small sizes.
	var style: StyleBox = GameUI.flat(GameUI.PAPER if color.r > color.b else Color("eaf2ed"))
	panel.add_theme_stylebox_override("panel",style)
	body.add_child(panel)
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",GameUI.INK)
	panel.add_child(label)
	return label

func _add_stage(background_id: String, character_id: String) -> void:
	stage = P1StoryStage.new()
	stage.background_id = background_id
	stage.character_id = character_id
	add_child(stage)
	move_child(stage,0)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func show_naming() -> void:
	if not session.state.cat.namePending:
		return
	_screen("naming", "给猫咪起个名字吧")
	_text("摸猫反馈完成，首遇贴纸与徽章已记录一次。确认名字后，才能开始整理。", 18)
	name_input = LineEdit.new()
	name_input.placeholder_text = "输入 1～20 个字符"
	name_input.custom_minimum_size.y = 52
	name_input.max_length = 20
	body.add_child(name_input)
	for suggestion in P1Content.data().suggestedNames:
		_button(suggestion, func(): name_input.text = suggestion)
	name_error = _text("", 16)
	primary_button = _button("确认名字", func():
		if session.confirm_name(name_input.text):
			_clear()
			if is_instance_valid(app.active_room):
				app.active_room.p1_controller.encounter.phase = "complete"
				app.active_room.p1_controller._refresh()
		else:
			name_error.text = session.last_error)
	_text("可直接退出游戏；下次会继续命名，纪念不会重复发放。昵称规则为本轮临时方案。", 14)

func show_organization() -> void:
	if session.state.quests.q01_cat != "completed":
		return
	_clear()
	modal_kind = "organization"
	organization_board = load("res://scripts/p1/luggage_tidy/view.gd").new()
	add_child(organization_board)
	organization_board.setup(app,session)
	organization_board.closed.connect(_clear)
	organization_board.continued.connect(func():
		_clear()
		show_message())
	primary_button = organization_board.continue_button

func show_message() -> void:
	if not session.state.organization.tutorialCompleted:
		return
	var index := mini(int(session.state.story.annaMessageIndex), 1)
	var line: Dictionary = P1Content.data().annaMessage[index]
	_screen("message", line.speaker)
	_add_stage("home.background", "")
	russian_line = _dialogue_text(line.ru, Color("fff0d9"), 23)
	chinese_line = _dialogue_text(line.zhSubtitle, Color("dcecf5"), 20)
	primary_button = _button("回房间" if session.state.story.cityUnlocked else ("读下一条" if index == 0 else "收好消息 · 解锁城市"), func():
		if session.state.story.cityUnlocked:
			_clear()
		elif session.advance_message():
			if session.state.story.cityUnlocked:
				_screen("complete", "第一段旅程完成")
				_text("猫咪有了名字，行李整理好了，安娜的消息也收到了。现在可以出门，或留在房间继续找猫。")
				_text("城市地图已开放；本轮止于 Q03，大学领资料尚未开放。", 16)
				primary_button = _button("留在房间", _clear)
				_button("看看城市地图", func():
					_clear()
					app.return_to_map())
			else:
				show_message()
		else:
			_save_error())

func block_return() -> bool:
	if modal_kind == "organization":
		_clear()
		return true
	if not modal_kind.is_empty():
		return true
	if not session.state.story.cityUnlocked:
		if is_instance_valid(app.active_room):
			app.active_room.feedback.text = "先与猫咪相识并完成整理，再查看安娜的消息。"
		return true
	return false
