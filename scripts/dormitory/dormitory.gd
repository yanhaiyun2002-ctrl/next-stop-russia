extends BuildingRoom
## Retains the BuildingRoom navigation/interaction contract, with a real room.
var world: DormitoryWorld
var room_view: DormitoryView
var controls: GridContainer
var mode_label: Label
var swap_button: Button
var depth_button: Button

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	world = DormitoryWorld.new()
	world.name = "RoomWorld"
	add_child(world)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "宿舍灰盒"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	back_button = Button.new()
	back_button.text = "← 返回地图"
	back_button.add_theme_font_size_override("font_size", 16)
	back_button.custom_minimum_size = Vector2(112, 48)
	back_button.pressed.connect(func(): return_requested.emit())
	header.add_child(back_button)
	add_child(header)
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 14)
	add_child(mode_label)
	room_view = DormitoryView.new()
	room_view.name = "RoomView"
	room_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_view.custom_minimum_size = Vector2(260, 280)
	add_child(room_view)
	room_view.configure(world)
	room_view.object_selected.connect(_selected)
	room_view.framing_changed.connect(_framing_text)
	controls = GridContainer.new()
	controls.add_theme_constant_override("h_separation", 6)
	controls.add_theme_constant_override("v_separation", 6)
	add_child(controls)
	for entry in [["全景", "overview"], ["床", "bed"], ["书桌", "desk"], ["衣柜", "wardrobe"]]:
		var button := _button(entry[0])
		button.pressed.connect(room_view.frame_object.bind(entry[1]))
	var left := _button("← 横移")
	left.pressed.connect(room_view.pan.bind(-1.0))
	var right := _button("横移 →")
	right.pressed.connect(room_view.pan.bind(1.0))
	action_button = _button("标记换点")
	action_button.pressed.connect(interact)
	depth_button = _button("标记前后")
	depth_button.pressed.connect(func():
		world.step_marker()
		feedback.text = "标记深度 %.2f m；可再次前后移动。" % world.marker_position.y)
	swap_button = _button("书桌换位")
	swap_button.pressed.connect(func():
		if world.toggle_desk():
			feedback.text = "书桌已切换至%s，遮挡与热点同步更新。" % ("前部" if world.desk_slot else "后部"))
	feedback = Label.new()
	feedback.add_theme_font_size_override("font_size", 16)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 48
	feedback.text = "点击几何家具查看名称；橙色标记仅用于遮挡实验。"
	add_child(feedback)
	resized.connect(_layout_room)
	get_viewport().size_changed.connect(_layout_room)
	_layout_room()

func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(button)
	return button

func _layout_room() -> void:
	if controls:
		controls.columns = 3 if get_viewport_rect().size.y > get_viewport_rect().size.x else 9
	if room_view:
		room_view.rebuild.call_deferred()
	_framing_text()

func _framing_text() -> void:
	if mode_label and room_view:
		var mode := room_view.effective_framing()
		mode_label.text = "正视广角 · 全景" if mode == "overview" else "正视广角 · 聚焦 / 可横移或返回全景"

func _selected(id: StringName) -> void:
	if id == &"marker":
		feedback.text = "测试标记物 · 深度 %.2f m" % world.marker_position.y
	else:
		var item: GrayboxFurniture = world.furniture[id]
		feedback.text = "%s · 地面深度 %.2f m；点击只命中当前可见表面。" % [item.display_name, item.floor_position.y]

func interact() -> void:
	interaction_count += 1
	world.cycle_marker()
	feedback.text = "标记点：%s（本次交互 %d 次）" % [world.MARKER_NAMES[world.marker_index], interaction_count]
