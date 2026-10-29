class_name P1OrganizationBoard
extends Control
## Visual organization surface. Drag ghosts are Node2D, not moving Controls.
signal feedback(message: String)
const TILE = preload("res://ui/organization_item.gd")
const SHORT_NAMES := {"textbook":"厚教材", "passport":"护照", "scarf":"围巾", "washbag":"洗漱包"}
const BIN_NAMES := {"A":"书籍区", "B":"随身区", "C":"洗漱区"}
const ITEM_ORDER := ["textbook","passport","scarf","washbag"]
const DRAG_THRESHOLD := 9.0
var player: P1Session
var item_controls: Dictionary = {}
var bin_controls: Dictionary = {}
var selected_item := ""
var last_feedback := "请选择物品，拖入区域；也可以点物品再点区域。"
var last_drop_valid := false
var pointer_active := false
var dragging := false
var pointer_item := ""
var press_position := Vector2.ZERO
var pointer_position := Vector2.ZERO
var hovered_bin := ""
var preview_error := ""
var item_sources: Dictionary = {}
var unit_rects: Dictionary = {}
var bin_regions: Dictionary = {}
var tray_region := Rect2()
var ghost: Node2D
var _configured := false
var _geometry_revision := 0
var _press_revision := -1
var _press_geometry: Array = []
var _body_bin := ""
var _body_start := Vector2.ZERO
var _body_cancelled := false
var _body_geometry: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(260, 496)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_layout_board)
	ghost = Node2D.new()
	ghost.z_index = 100
	add_child(ghost)
	ghost.draw.connect(_draw_ghost)
	_layout_board()

func configure(session: P1Session) -> void:
	player = session
	if _configured:
		refresh()
		return
	_configured = true
	for bin in player.puzzle.bins:
		var target = TILE.new()
		target.board = self
		target.bin_id = bin.id
		add_child(target)
		bin_controls[bin.id] = target
	for item in player.puzzle.items:
		var tile = TILE.new()
		tile.board = self
		tile.item_id = item.id
		tile.short_name = SHORT_NAMES.get(item.id,item.id)
		tile.units = int(item.size)
		tile.icon = P1Art.texture("org."+item.id)
		add_child(tile)
		item_controls[item.id] = tile
	player.changed.connect(refresh)
	_layout_board()

func _layout_board() -> void:
	_geometry_revision += 1
	if pointer_active or not _body_bin.is_empty():
		cancel_drag("画面尺寸变化，本次拖动已取消，物品保留原位。")
	if not _configured or size.x <= 0:
		return
	var portrait := get_viewport_rect().size.y > get_viewport_rect().size.x
	custom_minimum_size.y = 496 if portrait else 420
	var width := size.x
	var height := maxf(size.y,custom_minimum_size.y)
	unit_rects.clear()
	item_sources.clear()
	if portrait:
		var gap := 8.0
		# A/B remain horizontal two-unit cases, stacked above the one-unit pouch.
		_set_bin("A",Rect2(Vector2(0,8),Vector2(width,100)),false)
		_set_bin("B",Rect2(Vector2(0,116),Vector2(width,100)),false)
		_set_bin("C",Rect2(Vector2(width*0.14,224),Vector2(width*0.72,100)),false)
		tray_region = Rect2(Vector2(0,332),Vector2(width,height-332))
		var card_width := (width-24-gap)/2
		for index in range(4):
			item_sources[ITEM_ORDER[index]] = Rect2(Vector2(12+(index%2)*(card_width+gap),356+floori(index/2.0)*72),Vector2(card_width,64))
	else:
		var tray_width := clampf(width*0.24,136,250)
		var gap := 14.0
		tray_region = Rect2(Vector2.ZERO,Vector2(tray_width,height))
		var card_height := (height-42-3*8)/4
		for index in range(4):
			item_sources[ITEM_ORDER[index]] = Rect2(Vector2(12,30+index*(card_height+8)),Vector2(tray_width-24,card_height))
		var bins_left := tray_width+18
		var cases_width := width-bins_left
		var case_height := (height-gap)/2
		var bottom_b_width := (cases_width-gap)*0.69
		_set_bin("A",Rect2(Vector2(bins_left,8),Vector2(cases_width,case_height-8)),false)
		_set_bin("B",Rect2(Vector2(bins_left,case_height+gap),Vector2(bottom_b_width,case_height)),false)
		_set_bin("C",Rect2(Vector2(bins_left+bottom_b_width+gap,case_height+gap),Vector2(cases_width-bottom_b_width-gap,case_height)),false)
	_position_items()
	queue_redraw()

func _set_bin(id: String, rect: Rect2, vertical: bool) -> void:
	var target: Control = bin_controls[id]
	if id == "C" and get_viewport_rect().size.x >= get_viewport_rect().size.y:
		var case_texture := P1Art.texture("org.caseC")
		var aspect := float(case_texture.get_width())/case_texture.get_height() if case_texture else 2.0
		var fitted_height := minf(rect.size.y,rect.size.x/aspect)
		rect = Rect2(Vector2(rect.position.x,rect.end.y-fitted_height),Vector2(rect.size.x,fitted_height))
	bin_regions[id] = rect
	target.position = rect.position
	target.size = Vector2(rect.size.x,48)
	var capacity := 1 if id == "C" else 2
	# Registered open-case illustrations reserve this inner mouth for UI slots.
	# Keep a real 48px minimum drop/placed-item height on the narrow phone canvas.
	var inner := Rect2(rect.position+rect.size*Vector2(0.08,0.15),Vector2(rect.size.x*0.84,maxf(48,rect.size.y*0.47)))
	var units: Array[Rect2] = []
	for index in range(capacity):
		if vertical:
			var h := minf(68,(inner.size.y-6*(capacity-1))/capacity)
			units.append(Rect2(Vector2(inner.position.x,inner.position.y+index*(h+6)),Vector2(inner.size.x,h)))
		else:
			var w := (inner.size.x-6*(capacity-1))/capacity
			units.append(Rect2(Vector2(inner.position.x+index*(w+6),inner.position.y),Vector2(w,inner.size.y)))
	unit_rects[id] = units

func _position_items() -> void:
	var used: Dictionary = {"A":0,"B":0,"C":0}
	for id in ITEM_ORDER:
		var control: Control = item_controls[id]
		var rect: Rect2 = item_sources[id]
		var is_placed := false
		var destination: String = player.state.organization.placements.get(id,"")
		if unit_rects.has(destination):
			var capacity: int = unit_rects[destination].size()
			var start: int = used[destination]
			var count: int = control.units
			if start+count <= capacity:
				rect = unit_rects[destination][start]
				if count > 1:
					rect = rect.merge(unit_rects[destination][start+count-1])
				used[destination] += count
				is_placed = true
		control.position = rect.position
		control.size = rect.size
		control.selected = selected_item == id
		control.being_dragged = dragging and pointer_item == id
		control.in_bin = is_placed
		control.queue_redraw()

func refresh() -> void:
	if not _configured:
		return
	if pointer_active:
		cancel_drag("摆放已更新，本次拖动取消。")
	_position_items()
	queue_redraw()

func item_rect(id: String) -> Rect2:
	return item_controls[id].get_global_rect()

func bin_rect(id: String) -> Rect2:
	return Rect2(global_position+bin_regions[id].position,bin_regions[id].size)

func select_item(id: String) -> void:
	if not item_controls.has(id):
		return
	selected_item = id
	_position_items()
	_report("已选「%s」；点收纳区，或直接拖动。" % SHORT_NAMES[id])
	queue_redraw()

func select_bin(id: String) -> bool:
	if selected_item.is_empty():
		_report("先选择一件物品，再点收纳区。")
		return false
	return try_place(selected_item,id)

func try_place(id: String, destination: String) -> bool:
	var reason := P1Organization.validate_placement(player.puzzle,player.state.organization.placements,id,destination)
	if not reason.is_empty():
		last_drop_valid = false
		_report(reason+" 物品保留原位。")
		queue_redraw()
		return false
	if player.state.organization.placements.get(id) == destination:
		last_drop_valid = true
		_report("已在 %s 区，摆放没有改变。" % destination)
		return true
	last_drop_valid = player.place_item(id,destination)
	if last_drop_valid:
		selected_item = ""
		_position_items()
		_report("「%s」已放入 %s 区并保存。" % [SHORT_NAMES[id],destination])
	else:
		_report(player.last_error if not player.last_error.is_empty() else "尚未保存，物品保留原位。")
	queue_redraw()
	return last_drop_valid

func begin_pointer(id: String, global_point: Vector2) -> void:
	if not item_controls.has(id):
		return
	pointer_active = true
	dragging = false
	pointer_item = id
	selected_item = id
	press_position = global_point
	pointer_position = global_point-global_position
	_press_revision = _geometry_revision
	_press_geometry = gesture_geometry()
	hovered_bin = ""
	preview_error = ""

func _input(event: InputEvent) -> void:
	# ScreenTouch is intentionally not handled here: project emulates one mouse path.
	if not pointer_active:
		return
	if _press_geometry != gesture_geometry():
		cancel_drag("页面滚动或位置变化，本次拖动已取消，物品保留原位。")
		return
	if event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return
		pointer_position = event.position-global_position
		if not dragging and event.position.distance_to(press_position) >= DRAG_THRESHOLD:
			dragging = true
		if dragging:
			hovered_bin = _bin_at(pointer_position)
			preview_error = P1Organization.validate_placement(player.puzzle,player.state.organization.placements,pointer_item,hovered_bin) if not hovered_bin.is_empty() else "移到收纳区内再松开"
			ghost.position = pointer_position
			ghost.queue_redraw()
			_position_items()
			queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var id := pointer_item
		var was_dragging := dragging
		var valid_geometry := _press_revision == _geometry_revision
		var destination := _bin_at(event.position-global_position)
		_cancel_pointer()
		if valid_geometry:
			if was_dragging:
				if destination.is_empty():
					last_drop_valid = false
					_report("未放入收纳区，物品保留原位。")
				else:
					try_place(id,destination)
			else:
				select_item(id)
		_position_items()
		queue_redraw()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# ScrollContainer changes ancestors' transforms without emitting this Control's
	# resized signal. Detect it even if AdaptiveLayout consumes the release first.
	if pointer_active and _press_geometry != gesture_geometry():
		cancel_drag("页面滚动或位置变化，本次拖动已取消，物品保留原位。")
	elif not _body_bin.is_empty() and _body_geometry != gesture_geometry():
		_cancel_body_click()

func gesture_geometry() -> Array:
	var signature: Array = [get_global_rect(),get_global_transform_with_canvas(),get_viewport_rect(),_geometry_revision]
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			signature.append([ancestor.scroll_horizontal,ancestor.scroll_vertical,ancestor.get_global_rect()])
		ancestor = ancestor.get_parent()
	return signature

func _gui_input(event: InputEvent) -> void:
	# Child item Controls receive presses first, preserving placed-item dragging.
	# Empty grid cells and the remaining bin body reach this board surface.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_body_bin = _bin_at(event.position)
			_body_start = event.global_position
			_body_cancelled = false
			_body_geometry = gesture_geometry()
		else:
			var destination := _body_bin
			var activate: bool = not destination.is_empty() and not _body_cancelled and _body_geometry == gesture_geometry() and _bin_at(event.position) == destination and event.global_position.distance_to(_body_start) < DRAG_THRESHOLD
			_cancel_body_click()
			if activate:
				select_bin(destination)
		accept_event()
	elif event is InputEventMouseMotion and not _body_bin.is_empty():
		if event.global_position.distance_to(_body_start) >= DRAG_THRESHOLD:
			_body_cancelled = true
		accept_event()

func _cancel_body_click() -> void:
	_body_bin = ""
	_body_cancelled = false
	_body_geometry = []

func _bin_at(local_point: Vector2) -> String:
	for id in bin_controls:
		if bin_regions[id].has_point(local_point):
			return id
	return ""

func cancel_drag(message := "拖动已取消，物品保留原位。") -> void:
	_cancel_pointer()
	_cancel_body_click()
	if _configured:
		_position_items()
		_report(message)
	queue_redraw()

func _cancel_pointer() -> void:
	pointer_active = false
	dragging = false
	pointer_item = ""
	_press_geometry = []
	hovered_bin = ""
	preview_error = ""
	if is_instance_valid(ghost):
		ghost.queue_redraw()

func _report(message: String) -> void:
	last_feedback = message
	feedback.emit(message)

func _draw() -> void:
	if not _configured:
		return
	var font := get_theme_font("font")
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f0ddbd")
	paper.border_color = Color("ba9870")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(14)
	draw_style_box(paper,tray_region)
	draw_string(font,tray_region.position+Vector2(13,20),"行李托盘",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("624f3c"))
	for id in bin_controls:
		var rect: Rect2 = bin_regions[id]
		var case_texture := P1Art.texture("org.case"+id)
		if case_texture:
			draw_texture_rect(case_texture,rect,false)
		else:
			_draw_case_fallback(id,rect)
		var used := 0
		for item in player.puzzle.items:
			if player.state.organization.placements.get(item.id) == id:
				used += int(item.size)
		var capacity: int = unit_rects[id].size()
		var caption: String = "%s · %s  %d/%d格" % [id,BIN_NAMES[id],used,capacity]
		var text_width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		var plaque := Rect2(rect.position+Vector2((rect.size.x-minf(text_width+16,rect.size.x-8))/2,-6),Vector2(minf(text_width+16,rect.size.x-8),21))
		var plaque_style := StyleBoxFlat.new()
		plaque_style.bg_color = Color("f5e6c9")
		plaque_style.border_color = Color("987344")
		plaque_style.set_border_width_all(1)
		plaque_style.set_corner_radius_all(7)
		draw_style_box(plaque_style,plaque)
		draw_string(font,plaque.position+Vector2(7,15),caption,HORIZONTAL_ALIGNMENT_LEFT,plaque.size.x-10,13,Color("55412f"))
		var slot_color := Color("f5dfb4")
		if not selected_item.is_empty():
			slot_color = Color("d2a14b") if P1Organization.validate_placement(player.puzzle,player.state.organization.placements,selected_item,id).is_empty() else Color("9b7971")
		if hovered_bin == id:
			slot_color = Color("ffd27a") if preview_error.is_empty() else Color("c46e5d")
		for unit in unit_rects[id]:
			draw_rect(unit,Color(1,0.93,0.78,0.12))
			_dashed_rect(unit,slot_color,2)
	for id in item_sources:
		var source: Rect2 = item_sources[id]
		if player.state.organization.placements.has(id):
			_dashed_rect(source.grow(-3),Color(0.58,0.44,0.3,0.35),1)
			var note: String = "已入 "+player.state.organization.placements[id]
			var note_width := font.get_string_size(note,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(font,Vector2(source.get_center().x-note_width/2,source.get_center().y+4),note,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("9b805f"))
	if dragging and not preview_error.is_empty():
		draw_string(font,Vector2(4,maxf(18,size.y-4)),preview_error,HORIZONTAL_ALIGNMENT_LEFT,size.x-8,13,Color("8f4538"))

func _dashed_rect(rect: Rect2,color: Color,width := 1.0) -> void:
	var a := rect.position
	var b := Vector2(rect.end.x,rect.position.y)
	var c := rect.end
	var d := Vector2(rect.position.x,rect.end.y)
	for edge in [[a,b],[b,c],[c,d],[d,a]]:
		draw_dashed_line(edge[0],edge[1],color,width,6)

func _draw_case_fallback(id: String,rect: Rect2) -> void:
	# Source-independent luggage fallback, never the previous flat green form.
	var colors := {"A":Color("bb8b57"),"B":Color("4c6275"),"C":Color("617d68")}
	var shell := StyleBoxFlat.new()
	shell.bg_color = colors[id]
	shell.border_color = Color("76593e")
	shell.set_border_width_all(3)
	shell.set_corner_radius_all(16)
	draw_style_box(shell,rect.grow(-5))
	var interior := Rect2(rect.position+rect.size*Vector2(0.09,0.15),rect.size*Vector2(0.82,0.69))
	var lining := StyleBoxFlat.new()
	lining.bg_color = colors[id].lightened(0.18)
	lining.border_color = Color("d5b58a")
	lining.set_border_width_all(2)
	lining.set_corner_radius_all(12)
	draw_style_box(lining,interior)
	draw_rect(Rect2(rect.position+Vector2(rect.size.x*0.37,rect.size.y-7),Vector2(rect.size.x*0.26,5)),Color("6d5239"))

func _draw_ghost() -> void:
	if not dragging or pointer_item.is_empty():
		return
	var texture: Texture2D = item_controls[pointer_item].icon
	if texture:
		var region: Rect2 = item_controls[pointer_item].icon_region
		if not region.has_area():
			region = Rect2(Vector2.ZERO,texture.get_size())
		var scale_factor := minf(100.0/region.size.x,92.0/region.size.y)
		var fitted := region.size*scale_factor
		ghost.draw_texture_rect_region(texture,Rect2(-fitted/2,fitted),region,Color(1,1,1,0.78))
	else:
		ghost.draw_string(get_theme_font("font"),Vector2(-33,5),SHORT_NAMES[pointer_item],HORIZONTAL_ALIGNMENT_LEFT,72,15,Color("333e3c"))
