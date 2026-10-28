extends Control
## Map composition only. Shared normalized coordinates are projected per orientation.

var buildings: Array[BuildingDefinition] = []
var buttons: Dictionary = {}
var portrait := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(arrange)

func arrange() -> void:
	portrait = get_viewport_rect().size.y > get_viewport_rect().size.x
	var hotspot := Vector2(156, 92) if portrait else Vector2(200, 110)
	var inset := hotspot / 2.0 + Vector2(12, 12)
	var usable := (size - inset * 2.0).max(Vector2.ZERO)
	for building in buildings:
		var point := building.map_position
		if portrait:
			point = Vector2(point.y, point.x)
		var button: Button = buttons[building.id]
		button.size = hotspot
		button.position = inset + usable * point.clamp(Vector2.ZERO, Vector2.ONE) - hotspot / 2.0
	queue_redraw()

func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var previous := Vector2.ZERO
	for i in range(buildings.size()):
		var button: Button = buttons[buildings[i].id]
		var center := button.position + button.size / 2.0
		if i > 0:
			draw_line(previous, center, Color("497170"), 12.0, true)
			draw_line(previous, center, Color("9bc5b3"), 2.0, true)
		previous = center

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142d36")
	style.set_corner_radius_all(18)
	return style
