extends Control
signal activated
## Passive visual; the map Board owns click-versus-drag for both label and art.
var caption: Label
var locked := false
var selected := false
var direction := ""
var title_ru := ""
var title_zh := ""

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_ALL
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	set_meta("visual_only_geometry",true)
	caption = Label.new()
	caption.mouse_filter = MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",14)
	caption.add_theme_color_override("font_color",GameUI.INK)
	add_child(caption)
	caption.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	caption.offset_left = 5
	caption.offset_right = -5

func refresh() -> void:
	if caption:
		caption.text = direction+title_ru+"\n"+title_zh+(" · 未开放" if locked else "")
	queue_redraw()

func _draw() -> void:
	var style := GameUI.flat(Color("fff2d9"),10)
	if has_focus(): style.border_color = GameUI.INK
	if selected:
		style.border_color = GameUI.GOLD
		style.set_border_width_all(2)
		style.shadow_color = Color(0.82,0.65,0.32,0.32)
		style.shadow_size = 7
	draw_style_box(style,Rect2(Vector2.ZERO,size))
	if locked: GameUI.draw_lock(self,Vector2(size.x-10,7),Color("817153"))

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		activated.emit()
		accept_event()
