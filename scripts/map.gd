extends Control
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
var header: PanelContainer
var footer: PanelContainer
var footer_body: VBoxContainer
var tools: HBoxContainer
var technical := false
var safety: MarginContainer

func _ready() -> void:
	board = Board.new()
	board.name = "MapBoard"
	add_child(board)
	board.location_requested.connect(_request)
	header = PanelContainer.new()
	header.add_theme_stylebox_override("panel",GameUI.flat())
	add_child(header)
	var heading_box := VBoxContainer.new()
	heading_box.add_theme_constant_override("separation",2)
	header.add_child(heading_box)
	var heading := Label.new()
	heading.text = "Санкт-Петербург"
	heading.add_theme_font_size_override("font_size",22)
	heading_box.add_child(heading)
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size",12)
	heading_box.add_child(mode_label)
	orientation_label = Label.new()
	orientation_label.hide()
	add_child(orientation_label)
	footer = PanelContainer.new()
	footer.add_theme_stylebox_override("panel",GameUI.flat())
	add_child(footer)
	footer_body = VBoxContainer.new()
	footer_body.add_theme_constant_override("separation",5)
	footer.add_child(footer_body)
	footer.minimum_size_changed.connect(func(): _layout.call_deferred())
	status_label = Label.new()
	status_label.text = ""
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",13)
	status_label.hide()
	footer_body.add_child(status_label)
	location_row = HBoxContainer.new()
	location_row.hide()
	footer_body.add_child(location_row)
	tools = HBoxContainer.new()
	add_child(tools)
	for caption in ["−","＋","任务定位","地点"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(48,48)
		button.add_theme_font_size_override("font_size",14)
		tools.add_child(button)
		match caption:
			"−": button.pressed.connect(func(): board.set_zoom(board.zoom/1.25))
			"＋": button.pressed.connect(func(): board.set_zoom(board.zoom*1.25))
			"任务定位":
				task_button = button
				button.pressed.connect(func(): board.locate(board.task_id))
			"地点": button.pressed.connect(func():
				location_row.visible = not location_row.visible
				_layout.call_deferred())
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	visibility_changed.connect(_visibility)
	if safety: safety.safe_area_changed.connect(func(): _layout.call_deferred())
	_layout.call_deferred()

func install_story_entry(entry: Control) -> void:
	footer_body.add_child(entry)
	footer_body.move_child(entry,0)
	entry.resized.connect(_layout)
	_layout.call_deferred()

func set_technical(value: bool) -> void:
	technical = value
	location_row.visible = value
	mode_label.text = "圣彼得堡 · 技术预览" if value else mode_label.text
	_layout.call_deferred()

func configure(buildings: Array[BuildingDefinition]) -> void:
	definitions = buildings
	for building in buildings:
		var button := Button.new()
		button.name = String(building.id)
		button.text = building.display_name+(" · 锁" if not building.is_open else "")
		button.custom_minimum_size = Vector2(75,48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",14)
		button.pressed.connect(_request.bind(building.id))
		location_row.add_child(button)
		buttons[building.id] = button
	board.buildings = buildings
	board.buttons = buttons
	update_locks(false if technical else true)

func update_locks(story_locked: bool) -> void:
	var locks := {}
	for building in definitions:
		locks[String(building.id)] = not building.is_open or (story_locked and building.id != &"dormitory")
	board.set_locks(locks)

func _request(id: StringName) -> void:
	selected_id = id
	board.select_location(id)
	building_requested.emit(id)

func show_feedback(message: String) -> void:
	status_label.text = message
	status_label.visible = not message.is_empty()
	_layout.call_deferred()

func restore_focus() -> void:
	if location_row.visible and buttons.has(selected_id): buttons[selected_id].grab_focus()
	elif board.plaques.has(String(selected_id)): board.plaques[String(selected_id)].grab_focus()

func _visibility() -> void:
	board.visible = is_visible_in_tree()
	if not board.visible: board.clear_selection()
	else: _layout.call_deferred()

func _layout() -> void:
	if not is_instance_valid(board): return
	var left := safety.get_theme_constant("margin_left") if safety else 0
	var top := safety.get_theme_constant("margin_top") if safety else 0
	var right := safety.get_theme_constant("margin_right") if safety else 0
	var bottom := safety.get_theme_constant("margin_bottom") if safety else 0
	var safe := Rect2(left,top,size.x-left-right,size.y-top-bottom)
	board.global_position = Vector2.ZERO
	board.size = get_viewport_rect().size
	header.position = safe.position+Vector2(12,12)
	header.size = Vector2(minf(safe.size.x-24,340),64)
	var width := minf(safe.size.x-24,440)
	footer.custom_minimum_size.x = width
	footer.size = Vector2(width,footer.get_combined_minimum_size().y)
	footer.position = Vector2(safe.end.x-width-12,safe.end.y-footer.size.y-12)
	tools.position = Vector2(safe.position.x+12,footer.position.y-58) if size.y > size.x else Vector2(safe.position.x+12,safe.end.y-60)
	tools.size = tools.get_combined_minimum_size()
	board.label_avoid_rects = [header.get_global_rect().grow(8),footer.get_global_rect().grow(8),tools.get_global_rect().grow(6)]
	board.label_safe_rect = safe.grow(-12)
	board.arrange()
