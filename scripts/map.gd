extends VBoxContainer
## UI emits navigation intent; it does not load destination scenes.
signal building_requested(id: StringName)

const Board = preload("res://ui/map_board.gd")
var board: Control
var status_label: Label
var orientation_label: Label
var selected_id: StringName = &""
var buttons: Dictionary = {}
var definitions: Array[BuildingDefinition] = []

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var heading := Label.new()
	heading.text = "下一站，俄罗斯！"
	heading.add_theme_font_size_override("font_size", 28)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "P0-01 · 第一层级地图 · 技术样例"
	subtitle.add_theme_font_size_override("font_size", 16)
	add_child(subtitle)
	orientation_label = Label.new()
	orientation_label.add_theme_font_size_override("font_size", 16)
	add_child(orientation_label)
	board = Board.new()
	board.name = "MapBoard"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(260, 360)
	add_child(board)
	status_label = Label.new()
	status_label.name = "Feedback"
	status_label.text = "选择建筑进入；商店暂未开放。"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 56
	add_child(status_label)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	visibility_changed.connect(_layout)

func configure(buildings: Array[BuildingDefinition]) -> void:
	definitions = buildings
	for building in buildings:
		var button := Button.new()
		button.name = String(building.id)
		button.text = "%s\n%s" % [building.display_name, "进入 →" if building.is_open else "未开放 · 锁定"]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_request.bind(building.id))
		board.add_child(button)
		buttons[building.id] = button
	board.buildings = buildings
	board.buttons = buttons
	_layout.call_deferred()

func _request(id: StringName) -> void:
	selected_id = id
	building_requested.emit(id)

func show_feedback(message: String) -> void:
	status_label.text = message

func restore_focus() -> void:
	if buttons.has(selected_id):
		buttons[selected_id].grab_focus()

func _layout() -> void:
	if not is_instance_valid(board):
		return
	var portrait := get_viewport_rect().size.y > get_viewport_rect().size.x
	orientation_label.text = "竖屏 · 纵向街区" if portrait else "横屏 · 横向街区"
	board.custom_minimum_size.y = 360 if portrait else 230
	board.arrange.call_deferred()
