extends Control
## Artwork and texture-space regions share one transform. Navigation lives outside.
signal location_requested(id: StringName)
var texture: Texture2D
var texture_size := Vector2(1952,1087)
var locations: Dictionary = {}
var buildings: Array[BuildingDefinition] = []
var buttons: Dictionary = {}
var zoom := 1.0
var map_scale := 1.0
var map_offset := Vector2.ZERO
var pressed := false
var dragging := false
var press_point := Vector2.ZERO
var last_point := Vector2.ZERO
var pressed_id: StringName = &""
var selected_id: StringName = &""
var task_id: StringName = &"dormitory"
var last_size := Vector2.ZERO
var portrait := false
const PLAQUE = preload("res://ui/map_plaque.gd")
var plaques: Dictionary = {}
var label_rects: Dictionary = {}
var locked: Dictionary = {}
var label_avoid_rects: Array = []
var label_safe_rect := Rect2()

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture = P1Art.texture("city.map")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/city_map.json"))
	texture_size = Vector2(config.textureSize[0],config.textureSize[1])
	locations = config.locations
	for id in locations:
		var plaque = PLAQUE.new()
		plaque.title_ru = locations[id].label.ru
		plaque.title_zh = locations[id].label.zh
		add_child(plaque)
		plaque.activated.connect(_label_activated.bind(StringName(id)))
		plaques[id] = plaque
	resized.connect(arrange)
	arrange()

func base_scale() -> float:
	return maxf(size.x/texture_size.x,size.y/texture_size.y)

func arrange() -> void:
	portrait = get_viewport_rect().size.y > get_viewport_rect().size.x
	pressed = false
	dragging = false
	if size != last_size:
		map_scale = base_scale()*zoom
		map_offset = (size-texture_size*map_scale)/2
		last_size = size
	_clamp_offset()
	_place_plaques()
	queue_redraw()

func _clamp_offset() -> void:
	for axis in range(2):
		var extent := texture_size[axis]*map_scale
		map_offset[axis] = (size[axis]-extent)/2 if extent <= size[axis] else clampf(map_offset[axis],size[axis]-extent,0)

func texture_to_local(point: Vector2) -> Vector2:
	return map_offset+point*map_scale

func local_to_texture(point: Vector2) -> Vector2:
	return (point-map_offset)/map_scale

func set_zoom(value: float, pivot: Vector2 = Vector2.INF) -> void:
	pressed = false
	dragging = false
	if not pivot.is_finite(): pivot = size/2
	var anchor := local_to_texture(pivot)
	zoom = clampf(value,1,3)
	map_scale = base_scale()*zoom
	map_offset = pivot-anchor*map_scale
	_clamp_offset()
	_place_plaques()
	queue_redraw()

func locate(id: StringName) -> void:
	if not locations.has(String(id)): return
	selected_id = id
	var point: Array = locations[String(id)].anchor
	map_offset = size/2-Vector2(point[0],point[1])*map_scale
	_clamp_offset()
	_place_plaques()
	queue_redraw()

func set_locks(value: Dictionary) -> void:
	locked = value
	_place_plaques()

func select_location(id: StringName) -> void:
	selected_id = id
	_place_plaques()
	queue_redraw()

func clear_selection() -> void:
	pressed = false
	dragging = false
	select_location(&"")
	if get_viewport().gui_get_focus_owner() in plaques.values(): get_viewport().gui_release_focus()

func _label_activated(id: StringName) -> void:
	select_location(id)
	location_requested.emit(id)

func _place_plaques() -> void:
	var bounds := label_safe_rect if label_safe_rect.has_area() else Rect2(Vector2(12,12),size-Vector2(24,24))
	var placed: Array[Rect2] = []
	for id in plaques:
		var anchor: Array = locations[id].anchor
		var point := texture_to_local(Vector2(anchor[0],anchor[1]))
		var extent := Vector2(132,56)
		var position := point-Vector2(extent.x/2,76)
		position.x = clampf(position.x,bounds.position.x,bounds.end.x-extent.x)
		position.y = clampf(position.y,bounds.position.y,bounds.end.y-extent.y)
		for obstacle in label_avoid_rects+placed:
			if Rect2(position,extent).grow(4).intersects(obstacle):
				position.y = obstacle.position.y-extent.y-10
				if position.y < bounds.position.y:
					position.y = obstacle.end.y+10
		position.y = clampf(position.y,bounds.position.y,bounds.end.y-extent.y)
		var plaque: Control = plaques[id]
		plaque.position = position
		plaque.size = extent
		plaque.locked = locked.get(id,false)
		plaque.selected = selected_id == StringName(id)
		plaque.direction = ("← " if point.x < bounds.position.x else "→ ") if point.x < bounds.position.x or point.x > bounds.end.x else ""
		plaque.refresh()
		label_rects[id] = Rect2(position,extent)
		placed.append(Rect2(position,extent))

func _polygon(id: String) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in locations[id].get("points",[]):
		points.append(Vector2(point[0],point[1]))
	return points

func hit_test(point: Vector2) -> StringName:
	if not Rect2(Vector2.ZERO,size).has_point(point): return &""
	for id in label_rects:
		if label_rects[id].has_point(point): return StringName(id)
	var texel := local_to_texture(point)
	for id in locations:
		var region: Dictionary = locations[id]
		match region.get("shape","polygon"):
			"polygon":
				if Geometry2D.is_point_in_polygon(texel,_polygon(id)): return StringName(id)
			"circle":
				if texel.distance_to(Vector2(region.anchor[0],region.anchor[1])) <= region.radius: return StringName(id)
			"rect":
				var rect: Array = region.rect
				if Rect2(rect[0],rect[1],rect[2],rect[3]).has_point(texel): return StringName(id)
	var nearest: StringName = &""
	var distance := 24.0
	for id in locations:
		var anchor: Array = locations[id].anchor
		var gap := point.distance_to(texture_to_local(Vector2(anchor[0],anchor[1])))
		if gap < distance:
			distance = gap
			nearest = StringName(id)
	return nearest

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom(zoom*(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1/1.15),event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed = true
			dragging = false
			press_point = event.position
			last_point = event.position
			pressed_id = hit_test(event.position)
			select_location(pressed_id)
			if plaques.has(String(pressed_id)): plaques[String(pressed_id)].grab_focus()
			elif get_viewport().gui_get_focus_owner() in plaques.values(): get_viewport().gui_release_focus()
			accept_event()

func _input(event: InputEvent) -> void:
	if not pressed: return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		dragging = dragging or point.distance_to(press_point) >= 10
		if dragging:
			selected_id = &""
			map_offset += point-last_point
			_clamp_offset()
			_place_plaques()
			queue_redraw()
		last_point = point
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		var activate: bool = not dragging and point.distance_to(press_point) < 10 and hit_test(point) == pressed_id and not pressed_id.is_empty()
		pressed = false
		dragging = false
		if activate:
			selected_id = pressed_id
			location_requested.emit(pressed_id)
		elif not dragging:
			selected_id = &""
		_place_plaques()
		queue_redraw()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("cce7ee"))
	if texture:
		draw_texture_rect(texture,Rect2(map_offset,texture_size*map_scale),false)
	for id in plaques:
		var anchor: Array = locations[id].anchor
		var point := texture_to_local(Vector2(anchor[0],anchor[1]))
		var edge: Vector2 = point.clamp(Vector2(6,6),size-Vector2(6,6))
		var rect: Rect2 = label_rects[id]
		var end := Vector2(clampf(edge.x,rect.position.x+12,rect.end.x-12),rect.end.y)
		draw_line(end,edge,Color(0.98,0.91,0.7,0.85),2,true)
		draw_circle(edge,4,Color("fff3cd"))
		if selected_id == StringName(id):
			for radius in [22,18,14]:
				draw_circle(edge,radius,Color(0.96,0.76,0.32,0.09))
			draw_arc(edge,12,0,TAU,32,GameUI.GOLD,2,true)
	if locations.has(String(task_id)):
		var anchor: Array = locations[String(task_id)].anchor
		var point := texture_to_local(Vector2(anchor[0],anchor[1]))
		draw_circle(point,8,Color("fff1b8"))
		draw_arc(point,11,0,TAU,24,Color("614a38"),2,true)
