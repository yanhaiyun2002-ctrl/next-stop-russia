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
var item_buttons: Dictionary = {}
var bin_buttons: Dictionary = {}
var selected_item := ""
var item_summary: Label

func setup(main: Control, player: P1Session) -> void:
	app = main
	session = player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_modal)
	show_title()

func _clear() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
	body = null
	modal_kind = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	style.bg_color = Color("172b35")
	style.set_content_margin_all(18)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	modal.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	_text(title, 24)
	_layout_modal()
	if is_instance_valid(app.active_room) and app.active_room.p1_controller != null:
		app.active_room.p1_controller.encounter.set_process(false)

func _layout_modal() -> void:
	if not is_instance_valid(modal):
		return
	var portrait := size.y > size.x
	var side := 16 if portrait else maxi(28, int((size.x - 760) / 2))
	modal.add_theme_constant_override("margin_left", maxi(side, app.safe_layout.get_theme_constant("margin_left")))
	modal.add_theme_constant_override("margin_right", maxi(side, app.safe_layout.get_theme_constant("margin_right")))
	modal.add_theme_constant_override("margin_top", app.safe_layout.get_theme_constant("margin_top"))
	modal.add_theme_constant_override("margin_bottom", app.safe_layout.get_theme_constant("margin_bottom"))

func _text(value: String, font_size := 19) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	body.add_child(label)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	body.add_child(button)
	return button

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
		_clear()
		app.enter_building(&"dormitory")
	else:
		show_arrival()

func show_arrival() -> void:
	if session.state.story.arrivalIndex >= P1Content.data().arrival.size():
		_screen("arrival", "房间钥匙已收好")
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
	_text(line.ru, 24)
	_text(line.zhSubtitle, 20)
	_text("TEMP_TEXT · REVIEW_PENDING · 无配音", 14)
	primary_button = _button("收好钥匙，继续" if line.id == "q00.maria.01" else "继续", func():
		if session.advance_arrival():
			show_arrival()
		else:
			_save_error())

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
	_screen("organization", "整理 · 初来行李")
	_text("点选物品，再点击区域。\n厚教材→A；护照、围巾→B；洗漱包→C。每件物品必须放好，不能超容量。", 17)
	item_buttons.clear()
	bin_buttons.clear()
	for id in P1Content.data().itemNames:
		item_buttons[id] = _button(P1Content.data().itemNames[id], _select_item.bind(id))
	for id in P1Content.data().binNames:
		bin_buttons[id] = _button(P1Content.data().binNames[id], _place.bind(id))
	item_summary = _text("", 16)
	org_status = _text("请选择一件物品。", 16)
	_button("撤销上一步", func():
		if not session.undo_organization():
			org_status.text = session.last_error if not session.last_error.is_empty() else "没有可撤销的放置。"
		_refresh_organization())
	_button("重新摆放", func():
		session.undo_organization(true)
		_refresh_organization())
	primary_button = _button("确认整理", func():
		if session.complete_organization():
			_clear()
			show_message()
		else:
			org_status.text = session.last_error)
	_button("回房间 · 保留摆放", _clear)
	_refresh_organization()

func _select_item(id: String) -> void:
	selected_item = id
	org_status.text = "已选「%s」，请选择区域。" % P1Content.data().itemNames[id]

func _place(destination: String) -> void:
	if selected_item.is_empty():
		org_status.text = "先选一件物品。"
		return
	if not session.place_item(selected_item, destination):
		org_status.text = session.last_error
	else:
		org_status.text = "已保存摆放；可继续、撤销或确认。"
	_refresh_organization()

func _refresh_organization() -> void:
	var summary := ""
	var placements: Dictionary = session.state.organization.placements
	for id in item_buttons:
		item_buttons[id].text = P1Content.data().itemNames[id] + " → " + str(placements.get(id, "未放置"))
	for bin in session.puzzle.bins:
		var used := 0
		for item in session.puzzle.items:
			if placements.get(item.id) == bin.id:
				used += int(item.size)
		summary += "%s：%d/%d 格   " % [bin.id, used, bin.capacity]
	item_summary.text = summary

func show_message() -> void:
	if not session.state.organization.tutorialCompleted:
		return
	var index := mini(int(session.state.story.annaMessageIndex), 1)
	var line: Dictionary = P1Content.data().annaMessage[index]
	_screen("message", line.speaker)
	_text(line.ru, 23)
	_text(line.zhSubtitle, 20)
	_text("TEMP_TEXT · REVIEW_PENDING · 无配音", 14)
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
