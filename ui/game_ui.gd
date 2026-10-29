class_name GameUI
extends RefCounted
## Small shared visual vocabulary, no navigation or domain state.
const INK := Color("344953")
const PAPER := Color("fff4df")
const GOLD := Color("b79151")
const SAGE := Color("c8d7ba")

static func flat(color: Color = PAPER, radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("bd9e70")
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.29,0.22,0.14,0.16)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0,2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func paper() -> StyleBox:
	# The generated candidate's decorative corners distort in tall mobile cards.
	# Keep the source for review; production uses the same quiet native frame.
	var style := flat(PAPER)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func make_theme() -> Theme:
	var result := Theme.new()
	result.default_font = load("res://ui/theme.tres").default_font
	result.default_font_size = 18
	result.set_color("font_color","Label",INK)
	result.set_color("font_color","Button",INK)
	result.set_color("font_hover_color","Button",INK)
	result.set_color("font_pressed_color","Button",INK)
	result.set_color("font_disabled_color","Button",Color("7d8178"))
	result.set_stylebox("panel","PanelContainer",paper())
	result.set_stylebox("panel","TooltipPanel",flat())
	result.set_color("font_color","TooltipLabel",INK)
	result.set_stylebox("panel","PopupMenu",flat())
	result.set_stylebox("hover","PopupMenu",flat(Color("f5dfb6")))
	result.set_color("font_color","PopupMenu",INK)
	for state in ["normal","hover","pressed","disabled","focus"]:
		result.set_stylebox(state,"Button",button_style(state))
	result.set_stylebox("normal","LineEdit",flat(Color("fffaf0")))
	result.set_stylebox("focus","LineEdit",button_style("focus"))
	result.set_color("font_color","LineEdit",INK)
	result.set_color("caret_color","LineEdit",INK)
	result.set_color("font_placeholder_color","LineEdit",Color("7a827e"))
	result.set_constant("separation","VBoxContainer",8)
	result.set_constant("separation","HBoxContainer",6)
	return result

static func button_style(state: String) -> StyleBoxFlat:
	var colors := {"normal":PAPER,"hover":Color("f5dfb6"),"pressed":SAGE,"disabled":Color("e4e1d5"),"focus":Color(0,0,0,0)}
	var style := flat(colors.get(state,PAPER))
	if state == "pressed": style.shadow_size = 0
	if state == "focus":
		style.border_color = GOLD
		style.set_border_width_all(2)
		style.shadow_size = 0
	return style

static func button(control: Button) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		control.add_theme_stylebox_override(state,button_style(state))
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		control.add_theme_color_override(key,INK)
	control.add_theme_color_override("font_disabled_color",Color("7d8178"))
	control.custom_minimum_size.y = maxf(48,control.custom_minimum_size.y)

static func legible(label: Label) -> void:
	label.add_theme_color_override("font_color",INK)
	label.add_theme_color_override("font_outline_color",PAPER)
	label.add_theme_constant_override("outline_size",4)

static func draw_lock(canvas: CanvasItem, point: Vector2, color: Color) -> void:
	canvas.draw_arc(point+Vector2(0,-4),4,PI,TAU,16,color,2,true)
	canvas.draw_style_box(flat(color.lightened(0.6),2),Rect2(point+Vector2(-6,-3),Vector2(12,10)))
	canvas.draw_circle(point+Vector2(0,1),1.2,color)

static func cover_region(texture_size: Vector2, target_size: Vector2) -> Rect2:
	var factor := maxf(target_size.x/texture_size.x,target_size.y/texture_size.y)
	var source := target_size/factor
	return Rect2((texture_size-source)/2,source)

static func draw_cover(canvas: CanvasItem, texture: Texture2D, target: Rect2) -> void:
	if target.has_area(): canvas.draw_texture_rect_region(texture,target,cover_region(texture.get_size(),target.size))
