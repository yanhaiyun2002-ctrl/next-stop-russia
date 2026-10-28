extends MarginContainer
## Changes design base and converts device safe-area insets to logical UI units.
## Override is for deterministic viewport tests, never a fake device claim.

var safe_override_pixels := Rect2(-1, -1, 0, 0)
var portrait := false
var layout_ready := false
var _last_geometry: Array = []
var _stable_frames := 0
var _press_geometry: Dictionary = {}

func _ready() -> void:
	get_tree().root.size_changed.connect(refresh)
	refresh()

func refresh() -> void:
	layout_ready = false
	_stable_frames = 0
	_last_geometry = []
	var window := get_tree().root
	var pixels := Vector2(window.size)
	if pixels.x <= 0 or pixels.y <= 0:
		return
	portrait = pixels.y > pixels.x
	var base := Vector2i(360, 780) if portrait else Vector2i(1280, 720)
	if window.content_scale_size != base:
		window.content_scale_size = base
	var logical_scale := minf(pixels.x / base.x, pixels.y / base.y)
	var safe := Rect2(Vector2.ZERO, pixels)
	if safe_override_pixels.position.x >= 0:
		safe = safe_override_pixels.intersection(safe)
	elif OS.has_feature("mobile"):
		var device_safe := DisplayServer.get_display_safe_area()
		if device_safe.has_area():
			safe = Rect2(device_safe).intersection(safe)
	var inset := Vector4(safe.position.x, safe.position.y,
		pixels.x - safe.end.x, pixels.y - safe.end.y) / logical_scale
	var padding := 16 if portrait else 28
	add_theme_constant_override("margin_left", padding + ceili(inset.x))
	add_theme_constant_override("margin_top", padding + ceili(inset.y))
	add_theme_constant_override("margin_right", padding + ceili(inset.z))
	add_theme_constant_override("margin_bottom", padding + ceili(inset.w))

func geometry_signature() -> Array:
	var window := get_tree().root
	var signature: Array = [window.size, window.content_scale_size, window.get_visible_rect().size]
	_append_geometry(self, signature)
	return signature

func _append_geometry(node: Node, signature: Array) -> void:
	if node is Control:
		if not node.is_visible_in_tree():
			return
		signature.append(node.get_instance_id())
		signature.append(node.get_global_rect())
	for child in node.get_children():
		_append_geometry(child, signature)

func _process(_delta: float) -> void:
	var current := geometry_signature()
	if current != _last_geometry:
		_last_geometry = current
		_stable_frames = 0
		layout_ready = false
	else:
		_stable_frames += 1
		layout_ready = _stable_frames >= 2

func is_layout_settled() -> bool:
	# Check again at input time: native resize can arrive between process frames.
	return layout_ready and geometry_signature() == _last_geometry

func _input(event: InputEvent) -> void:
	var pointer := ""
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer = "mouse"
		pressed = event.pressed
	elif event is InputEventScreenTouch:
		pointer = "touch_%d" % event.index
		pressed = event.pressed
	if not pointer.is_empty():
		var current := geometry_signature()
		var valid := is_layout_settled()
		if pressed:
			_press_geometry[pointer] = current if valid else []
		else:
			valid = valid and _press_geometry.get(pointer, []) == current
			_press_geometry.erase(pointer)
		if not valid:
			_cancel_pointer_press(self)
			get_viewport().set_input_as_handled()
	elif event.is_action("ui_accept") and not is_layout_settled():
		get_viewport().set_input_as_handled()

func _cancel_pointer_press(node: Node) -> void:
	# BaseButton clears its press-attempt/capture state when disabled. Restore the
	# enabled state synchronously; no navigation signal or fabricated click occurs.
	if node is BaseButton and node.is_pressed() and not node.disabled:
		node.disabled = true
		node.disabled = false
	for child in node.get_children():
		_cancel_pointer_press(child)
