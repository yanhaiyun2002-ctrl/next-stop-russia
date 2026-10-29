extends Control
## World-space label. One emulated-mouse path, drag forwards to room browser.
signal attempted(id: String)
var object_id := ""
var view: DormitoryView
var caption: Label
var start := Vector2.ZERO
var dragging := false
var down := false
var revision := -1
var plaque: StyleBoxFlat

func _init() -> void:
	set_meta("owner_managed_geometry",true)
	custom_minimum_size = Vector2(88, 48)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plaque = GameUI.flat(Color("fff1d8"),8)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color",GameUI.INK)
	caption.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var height := 48.0 if caption.text.contains("\n") else 34.0
	draw_style_box(plaque,Rect2(0,(size.y-height)/2,size.x,height))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus()
			start = get_global_transform_with_canvas()*event.position
			dragging = false
			down = true
			revision = view.view_revision
			_forward(event)
		else:
			var valid := down and not dragging and revision == view.view_revision and Rect2(Vector2.ZERO, size).has_point(event.position)
			down = false
			if dragging:
				_forward(event)
			else:
				view._cancel_pointer()
			if valid:
				attempted.emit(object_id)
		accept_event()
	elif event is InputEventMouseMotion and down:
		if (get_global_transform_with_canvas()*event.position).distance_to(start) >= view.DRAG_THRESHOLD:
			dragging = true
		_forward(event)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		attempted.emit(object_id)
		accept_event()

func _forward(event: InputEvent) -> void:
	var copy: InputEvent = event.duplicate()
	# GUI-local coordinates remain valid even for synthetic press events whose
	# global_position metadata is unset. Also handles future canvas transforms.
	copy.position = view.get_global_transform_with_canvas().affine_inverse()*(get_global_transform_with_canvas()*event.position)
	view._gui_input(copy)

func cancel_gesture() -> void:
	down = false
	dragging = false
	view._cancel_pointer()
