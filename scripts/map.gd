extends VBoxContainer
signal building_requested(id: StringName)
const Board = preload("res://ui/map_board.gd")
var board: Control
var status_label: Label
var orientation_label: Label
var selected_id: StringName = &""
var buttons: Dictionary = {}
var definitions: Array[BuildingDefinition] = []
var location_row: HBoxContainer
var task_button: Button
var mode_label: Label

func _ready() -> void:
	add_theme_constant_override("separation",6)
	var heading := Label.new()
	heading.text = "圣彼得堡 · Санкт-Петербург"
	heading.add_theme_font_size_override("font_size",24)
	add_child(heading)
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size",14)
	add_child(mode_label)
	orientation_label = Label.new()
	orientation_label.text = "点击建筑进入 · 拖动浏览"
	orientation_label.add_theme_font_size_override("font_size",14)
	add_child(orientation_label)
	var tools := HBoxContainer.new()
	add_child(tools)
	for caption in ["−","＋","全景","任务定位"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(48,44)
		tools.add_child(button)
		match caption:
			"−": button.pressed.connect(func(): board.set_zoom(board.zoom/1.25))
			"＋": button.pressed.connect(func(): board.set_zoom(board.zoom*1.25))
			"全景": button.pressed.connect(func(): board.set_zoom(1))
			"任务定位":
				task_button = button
				button.pressed.connect(func(): board.locate(board.task_id))
	board = Board.new()
	board.name = "MapBoard"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(260,230)
	add_child(board)
	board.location_requested.connect(_request)
	location_row = HBoxContainer.new()
	add_child(location_row)
	status_label = Label.new()
	status_label.text = "地图仅作艺术化导航；商店暂未开放。"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",14)
	status_label.custom_minimum_size.y = 38
	add_child(status_label)

func configure(buildings: Array[BuildingDefinition]) -> void:
	definitions = buildings
	for building in buildings:
		var button := Button.new()
		button.name = String(building.id)
		button.text = building.display_name+(" · 锁" if not building.is_open else "")
		button.custom_minimum_size = Vector2(75,48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",16)
		button.pressed.connect(_request.bind(building.id))
		location_row.add_child(button)
		buttons[building.id] = button
	board.buildings = buildings
	board.buttons = buttons

func _request(id: StringName) -> void:
	selected_id = id
	board.locate(id)
	building_requested.emit(id)

func show_feedback(message: String) -> void:
	status_label.text = message

func restore_focus() -> void:
	if buttons.has(selected_id): buttons[selected_id].grab_focus()