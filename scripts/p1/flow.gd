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
var item_buttons: Dictionary = {}
var bin_buttons: Dictionary = {}
var selected_item := ""
var item_summary: Label
var map_entry: VBoxContainer
var map_continue: Button
var map_instruction: Label
var resume_organization := false
var organization_board: P1OrganizationBoard
var stage: P1StoryStage
var russian_line: Label
var chinese_line: Label

func setup(main: Control, player: P1Session) -> void:
	app = main
	session = player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_modal)
	map_entry = VBoxContainer.new()
	map_instruction = Label.new()
	map_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_instruction.add_theme_font_size_override("font_size",16)
	map_entry.add_child(map_instruction)
	map_continue = Button.new()
	map_continue.custom_minimum_size.y = 48
	map_continue.pressed.connect(start)
	map_entry.add_child(map_continue)
	app.map_view.add_child(map_entry)
	app.map_view.move_child(map_entry,3)
	session.changed.connect(refresh_map_entry)
	refresh_map_entry()
	primary_button = map_continue

func refresh_map_entry() -> void:
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
		map_instruction.text = "首段已完成 · 主动选择地点进入。此处仍为技术地图。"
		map_continue.text = "回我的小屋"
	if not session.store.notice.is_empty():
		map_instruction.text += "\n" + session.store.notice

func home_entered() -> void:
	if resume_organization and not session.state.cat.namePending:
		resume_organization = false
		show_organization()

func _clear() -> void:
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0,0,0,0) if kind == "arrival" else Color("f2e4cb")
	style.set_content_margin_all(10 if kind == "arrival" else 14)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	modal.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_END if kind == "arrival" else BoxContainer.ALIGNMENT_BEGIN
	body.add_theme_constant_override("separation", 7 if kind == "arrival" else 10)
	scroll.add_child(body)
	var title_label := _text(title, 19 if kind == "arrival" else 24)
	if kind == "arrival":
		title_label.add_theme_color_override("font_color",Color("fff0d9"))
		title_label.add_theme_color_override("font_outline_color",Color("66513c"))
		title_label.add_theme_constant_override("outline_size",5)
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
	modal.add_theme_constant_override("margin_top", app.safe_layout.get_theme_constant("margin_top"))
	modal.add_theme_constant_override("margin_bottom", app.safe_layout.get_theme_constant("margin_bottom"))

func _text(value: String, font_size := 19) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color",Color("293b41"))
	body.add_child(label)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	style_button(button)
	button.pressed.connect(callback)
	body.add_child(button)
	return button

func style_button(button: Button) -> void:
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ead0a8") if state == "normal" else Color("d9bb8e")
		style.border_color = Color("95734e")
		style.set_border_width_all(2)
		style.set_corner_radius_all(18)
		style.set_content_margin_all(8)
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",Color("32434a"))
	button.add_theme_color_override("font_hover_color",Color("24373c"))
	button.add_theme_color_override("font_pressed_color",Color("24373c"))

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
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.bg_color.a = 0.96
	style.border_color = Color("80664f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	body.add_child(panel)
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("293b41"))
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
	selected_item = ""
	_screen("organization", "整理行李")
	body.add_theme_constant_override("separation",6)
	_text("拖放或点选；教材 A、随身物品 B、洗漱包 C。", 15)
	organization_board = P1OrganizationBoard.new()
	organization_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(organization_board)
	organization_board.configure(session)
	item_buttons = organization_board.item_controls
	bin_buttons = organization_board.bin_controls
	org_status = _text("选好物品，放进行李箱。", 14)
	organization_board.feedback.connect(func(message): org_status.text=message)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	undo_button = _button("撤销", func(): session.undo_organization())
	body.remove_child(undo_button)
	actions.add_child(undo_button)
	undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button = _button("重置", func(): session.undo_organization(true))
	body.remove_child(reset_button)
	actions.add_child(reset_button)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button = _button("确认", func():
		if session.complete_organization():
			_clear()
			show_message()
		else:
			org_status.text = session.last_error)
	body.remove_child(primary_button)
	actions.add_child(primary_button)
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal","hover","pressed"]:
		var confirm_style := primary_button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		confirm_style.bg_color = Color("9bb78f") if state == "normal" else Color("87a67b")
		primary_button.add_theme_stylebox_override(state,confirm_style)
	_button("回房间 · 保留摆放", _clear)

func show_message() -> void:
	if not session.state.organization.tutorialCompleted:
		return
	var index := mini(int(session.state.story.annaMessageIndex), 1)
	var line: Dictionary = P1Content.data().annaMessage[index]
	_screen("message", line.speaker)
	russian_line = _dialogue_text(line.ru, Color("fff0d9"), 23)
	chinese_line = _dialogue_text(line.zhSubtitle, Color("dcecf5"), 20)
	primary_button = _button("回房间" if session.state.story.cityUnlocked else ("读下一条" if index == 0 else "收好消息 · 解锁城市"), func():
		if session.state.story.cityUnlocked:
			_clear()
		elif session.advance_message():
			if session.state.story.cityUnlocked:
				_screen("complete", "第一段旅程完成")
				_text("猫咪有了名字，行李整理好了，安娜的消息也收到了。现在可以出门，或留在房间继续找猫。")
				_text("城市目前沿用技术地图；本轮止于 Q03，大学领资料尚未开放。", 16)
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
