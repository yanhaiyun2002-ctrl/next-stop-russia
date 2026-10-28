extends Control
## A visual tile and hit target; all placement decisions stay in the board/session.
var board: Control
var item_id := ""
var bin_id := ""
var short_name := ""
var units := 1
var selected := false
var being_dragged := false
var icon: Texture2D
var icon_region := Rect2()
var in_bin := false
var _bin_down := false
var _bin_start := Vector2.ZERO
var _bin_cancelled := false
var _bin_geometry: Array = []

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus()
			if not item_id.is_empty():
				board.begin_pointer(item_id, event.global_position)
			else:
				_bin_down = true
				_bin_start = event.global_position
				_bin_cancelled = false
				_bin_geometry = board.gesture_geometry()
		elif not bin_id.is_empty():
			var activate: bool = _bin_down and not _bin_cancelled and _bin_geometry == board.gesture_geometry() and Rect2(Vector2.ZERO,size).has_point(event.position)
			_bin_down = false
			if activate:
				board.select_bin(bin_id)
		accept_event()
	elif event is InputEventMouseMotion and _bin_down:
		if event.global_position.distance_to(_bin_start) >= 9:
			_bin_cancelled = true
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		if not item_id.is_empty():
			board.select_item(item_id)
		else:
			board.select_bin(bin_id)
		accept_event()

func _draw() -> void:
	if item_id.is_empty():
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1,0.94,0.82,0.82) if not in_bin else Color(1,0.94,0.82,0.03)
	if selected:
		style.bg_color = Color(1,0.9,0.67,0.38 if in_bin else 0.92)
	if being_dragged:
		style.bg_color.a *= 0.3
	style.border_color = Color("d4a24e") if selected or has_focus() else Color(0.7,0.55,0.37,0.32 if not in_bin else 0)
	style.set_border_width_all(2 if selected or has_focus() else (1 if not in_bin else 0))
	style.set_corner_radius_all(12)
	draw_style_box(style, Rect2(Vector2.ZERO,size))
	var art_rect := Rect2(Vector2(6, 2), Vector2(size.x-12,maxf(24,size.y-(11 if in_bin else 25))))
	if icon:
		if not icon_region.has_area():
			var image := icon.get_image()
			icon_region = Rect2(image.get_used_rect()) if image else Rect2(Vector2.ZERO,icon.get_size())
			if not icon_region.has_area():
				icon_region = Rect2(Vector2.ZERO,icon.get_size())
		var image_size := icon_region.size
		var scale_factor := minf(art_rect.size.x / image_size.x, art_rect.size.y / image_size.y)
		var fitted := image_size * scale_factor
		draw_texture_rect_region(icon, Rect2(art_rect.get_center()-fitted/2,fitted),icon_region,Color(1,1,1,0.45 if being_dragged else 1.0))
	else:
		_draw_fallback(art_rect)
	if not in_bin:
		var font := get_theme_font("font")
		var text_width := font.get_string_size(short_name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(font,Vector2(maxf(3,(size.x-text_width)/2),size.y-9),short_name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("5c4835"))
	for unit in range(units):
		draw_rect(Rect2(Vector2(5+unit*8,size.y-5),Vector2(6,3)),Color("8d6b3c"))

func _draw_fallback(rect: Rect2) -> void:
	# Original procedural fallback remains recognizable before/if PNGs are unavailable.
	var center := rect.get_center()
	match item_id:
		"textbook":
			draw_rect(Rect2(center-Vector2(23,16),Vector2(46,32)),Color("496b8a"))
			draw_line(center+Vector2(-19,11),center+Vector2(19,11),Color("fff1d4"),5)
		"passport":
			draw_rect(Rect2(center-Vector2(15,20),Vector2(30,40)),Color("8a4b51"))
			draw_circle(center+Vector2(0,-3),6,Color("e8c981"))
		"scarf":
			draw_rect(Rect2(center-Vector2(24,10),Vector2(48,20)),Color("bf7458"))
			for x in [-18,-6,6,18]:
				draw_line(center+Vector2(x,-10),center+Vector2(x,15),Color("eacba1"),3)
		"washbag":
			draw_rect(Rect2(center-Vector2(25,15),Vector2(50,30)),Color("4d817c"))
			draw_line(center+Vector2(-20,-9),center+Vector2(20,-9),Color("d9e7d8"),2)
