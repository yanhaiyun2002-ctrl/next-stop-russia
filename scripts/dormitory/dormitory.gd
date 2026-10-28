extends BuildingRoom
## P0-04 local hunt on the R room; older spatial fixtures remain available.
var world: DormitoryWorld
var room_view: DormitoryView
var controls: GridContainer
var mode_label: Label
var swap_button: Button
var depth_button: Button
var debug_panel: VBoxContainer
var debug_button: Button
var overview_button: Button
var focus_button: Button
var selection_bar: HBoxContainer
var composition_option: OptionButton
var scheme_option: OptionButton
var phone_scheme := "B"
var selected_furniture: StringName = &"bed"
var hunt_panel: HBoxContainer
var hunt_prompt: Label
var hunt_action: Button

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	world = DormitoryWorld.new()
	world.name = "RoomWorld"
	add_child(world)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "宿舍 · 找猫"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	back_button = _make_button("← 返回地图")
	back_button.size_flags_horizontal = Control.SIZE_FILL
	back_button.custom_minimum_size.x = 112
	back_button.pressed.connect(func(): return_requested.emit())
	header.add_child(back_button)
	add_child(header)
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 14)
	mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(mode_label)
	hunt_panel = HBoxContainer.new()
	hunt_prompt = Label.new()
	hunt_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hunt_prompt.add_theme_font_size_override("font_size", 16)
	hunt_prompt.custom_minimum_size.y = 72
	hunt_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hunt_panel.add_child(hunt_prompt)
	hunt_action = _make_button("给个提示")
	hunt_action.custom_minimum_size.x = 88
	hunt_action.size_flags_horizontal = Control.SIZE_FILL
	hunt_action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hunt_action.pressed.connect(func():
		if world.is_hunt_active():
			if world.hunt.found:
				world.hunt.next_search()
				feedback.text = "猫换了个地方，慢慢找吧。"
			else:
				world.hunt.show_hint())
	hunt_panel.add_child(hunt_action)
	add_child(hunt_panel)
	room_view = DormitoryView.new()
	room_view.name = "RoomView"
	room_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_view.custom_minimum_size = Vector2(260, 220)
	add_child(room_view)
	room_view.configure(world)
	room_view.object_selected.connect(_selected)
	room_view.empty_tapped.connect(_missed)
	room_view.framing_changed.connect(_framing_text)
	world.changed.connect(_refresh_hunt)
	selection_bar = HBoxContainer.new()
	for entry in [["床", &"bed"], ["书桌", &"desk"], ["衣柜", &"wardrobe"]]:
		var button := _make_button(entry[0])
		button.pressed.connect(_browse_to_furniture.bind(entry[1]))
		selection_bar.add_child(button)
	add_child(selection_bar)
	selection_bar.add_theme_constant_override("separation", 4)
	overview_button = _make_button("全景")
	overview_button.pressed.connect(_reset_view)
	selection_bar.add_child(overview_button)
	focus_button = _make_button("聚焦")
	focus_button.pressed.connect(func(): room_view.frame_object(String(selected_furniture)))
	selection_bar.add_child(focus_button)
	debug_button = _make_button("测试")
	debug_button.pressed.connect(func(): set_debug_visible(not debug_panel.visible))
	selection_bar.add_child(debug_button)
	debug_panel = VBoxContainer.new()
	debug_panel.visible = false
	add_child(debug_panel)
	controls = GridContainer.new()
	controls.add_theme_constant_override("h_separation", 6)
	controls.add_theme_constant_override("v_separation", 6)
	debug_panel.add_child(controls)
	var left := _button("← 横移")
	left.pressed.connect(room_view.pan.bind(-1.0))
	var right := _button("横移 →")
	right.pressed.connect(room_view.pan.bind(1.0))
	action_button = _button("标记换点")
	action_button.pressed.connect(interact)
	depth_button = _button("标记前后")
	depth_button.pressed.connect(func():
		world.step_marker()
		feedback.text = "标记深度 %.2f m" % world.marker_position.y)
	swap_button = _button("书桌换位")
	swap_button.pressed.connect(func():
		if world.toggle_desk():
			feedback.text = "书桌已切换至%s槽位。" % ("前部" if world.desk_slot else "后部"))
	var ceiling := _button("天花强弱")
	ceiling.pressed.connect(func(): room_view.set_ceiling_emphasis(not room_view.ceiling_emphasis))
	var options := HBoxContainer.new()
	composition_option = OptionButton.new()
	for text_value in ["比例：原版", "比例：适中", "比例：紧凑", "空间：横向"]:
		composition_option.add_item(text_value)
	composition_option.select(3)
	composition_option.item_selected.connect(func(index): room_view.set_composition(["original", "balanced", "compact", "ribbon"][index]))
	scheme_option = OptionButton.new()
	scheme_option.add_item("手机 A：全景")
	scheme_option.add_item("手机 B：点选聚焦")
	scheme_option.select(1)
	scheme_option.item_selected.connect(func(index):
		if room_view.composition == "ribbon":
			set_play_enabled(index == 0)
		else:
			set_phone_scheme("A" if index == 0 else "B"))
	for option in [composition_option, scheme_option]:
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.custom_minimum_size.y = 48
		option.add_theme_font_size_override("font_size", 13)
		options.add_child(option)
	debug_panel.add_child(options)
	feedback = Label.new()
	feedback.add_theme_font_size_override("font_size", 14)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 36
	feedback.text = "左右拖动浏览；点击查看，复位返回默认取景。"
	add_child(feedback)
	resized.connect(_layout_room)
	get_viewport().size_changed.connect(_layout_room)
	_layout_room()
	_refresh_hunt()

func _make_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 15)
	button.custom_minimum_size = Vector2(48, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _button(value: String) -> Button:
	var button := _make_button(value)
	controls.add_child(button)
	return button

func set_debug_visible(value: bool) -> void:
	debug_panel.visible = value
	world.set_hunt_paused(value)
	debug_button.text = "收起" if value else "测试"
	_framing_text()
	_refresh_hunt()

func set_play_enabled(value: bool) -> void:
	world.set_hunt_enabled(value)
	_refresh_hunt()
	_framing_text()

func _refresh_hunt() -> void:
	if p1_controller != null:
		return
	if not hunt_panel or not world.hunt:
		return
	hunt_panel.visible = world.is_hunt_active()
	hunt_prompt.text = world.hunt.prompt()
	hunt_action.text = "再找一次" if world.hunt.found else "给个提示"

func _browse_to_furniture(id: StringName) -> void:
	if world.is_hunt_active():
		selected_furniture = id
		feedback.text = "看看%s附近，试着点点猫咪。" % world.furniture[id].display_name
		room_view.frame_object(String(id))
	else:
		_selected(id)
		if room_view.composition == "ribbon" or not room_view.is_portrait():
			room_view.frame_object(String(id))

func _missed() -> void:
	if world.is_hunt_active() and world.hunt.miss():
		feedback.text = "还没点到猫，换个角度看看。"

func _reset_view() -> void:
	room_view.frame_object("overview")
	if room_view.composition == "ribbon":
		feedback.text = "默认取景；左右拖动浏览，点击查看。"

func set_phone_scheme(value: String) -> void:
	if value not in ["A", "B"]:
		return
	phone_scheme = value
	scheme_option.select(0 if value == "A" else 1)
	room_view.frame_object("overview")
	feedback.text = "A：点选查看，按聚焦放大。" if value == "A" else "B：点选聚焦，按全景返回。"

func _layout_room() -> void:
	if controls:
		controls.columns = 3 if get_viewport_rect().size.y > get_viewport_rect().size.x else 6
	if room_view:
		room_view.rebuild.call_deferred()
	_framing_text()

func _framing_text() -> void:
	if not mode_label or not room_view:
		return
	if p1_controller != null:
		mode_label.text = "小屋 · 左右拖动探索"
		return
	var mode := room_view.effective_framing()
	var portrait := room_view.is_portrait()
	var ribbon := room_view.composition == "ribbon"
	if ribbon:
		mode_label.text = ("找猫" if world.hunt_enabled else "空间测试") + " · 左右拖动浏览"
	else:
		mode_label.text = ("手机 %s · " % phone_scheme if portrait else "正视广角 · ") + ("全景" if mode == "overview" else "局部聚焦")
	if overview_button:
		overview_button.text = "复位" if ribbon else "全景"
	if focus_button:
		focus_button.visible = not ribbon
	if scheme_option:
		var first := "找猫玩法" if ribbon else "手机 A：全景"
		if scheme_option.get_item_text(0) != first:
			scheme_option.clear()
			scheme_option.add_item(first)
			scheme_option.add_item("空间测试" if ribbon else "手机 B：点选聚焦")
		scheme_option.select((0 if world.hunt_enabled else 1) if ribbon else (0 if phone_scheme == "A" else 1))
	if composition_option:
		composition_option.select(["original", "balanced", "compact", "ribbon"].find(room_view.composition))

func _selected(id: StringName) -> void:
	if p1_controller != null:
		p1_controller.selected(id)
		return
	if world.is_hunt_active():
		if id == &"cat":
			if world.hunt.find_cat():
				feedback.text = "找到啦！准备好后可以再找一次。"
		elif world.hunt.miss():
			feedback.text = "点到%s了；看看露出的猫咪。" % world.furniture[id].display_name
		return
	if id == &"marker":
		feedback.text = "测试标记 · 深度 %.2f m" % world.marker_position.y
	else:
		selected_furniture = id
		feedback.text = "%s · 深度 %.2f m" % [world.furniture[id].display_name, world.furniture[id].floor_position.y]
		if room_view.composition != "ribbon" and room_view.is_portrait() and phone_scheme == "B":
			room_view.frame_object(String(id))

func interact() -> void:
	interaction_count += 1
	world.cycle_marker()
	feedback.text = "标记点：%s（交互 %d 次）" % [world.MARKER_NAMES[world.marker_index], interaction_count]
