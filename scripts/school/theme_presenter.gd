class_name SchoolThemePresenter
extends Control
## ThemePresenter boundary: consumes view events, never judges or persists answers.
const ASSET_ROOT := "res://assets/school/"
var theme_id := "classroom_blackboard_v1"
var tutor_pose := "idle"
var reduced_motion := false
var last_event := ""
var theme_config: Dictionary = {}

func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/school/theme.json"))
	if data is Dictionary:
		theme_config = data

func feedback_seconds() -> float:
	for item in theme_config.get("themes",[]):
		if item.id == theme_config.get("activeThemeId"):
			return float(item.get("animations",{}).get("correctMs",350))/1000.0
	return 0.35

func configure(settings: Dictionary) -> void:
	theme_id = settings.get("themeId","classroom_blackboard_v1")
	reduced_motion = settings.get("reducedMotion",false)
	modulate = Color("e5eee9") if theme_id == "classroom_blackboard_muted" else Color.WHITE
	queue_redraw()

func on_session_start(_snapshot: Dictionary) -> void:
	tutor_pose = "idle"
	last_event = "session_start"

func on_question_shown(_question: Dictionary) -> void:
	tutor_pose = "idle"
	last_event = "question_shown"

func on_answer_evaluated(result: Dictionary) -> void:
	tutor_pose = "hint" if result.assisted else ("correct" if result.correct else "explain")
	last_event = "answer_evaluated"

func on_word_passed(_word: String, _progress: Dictionary) -> void:
	last_event = "word_passed"

func on_session_completed(_summary: Dictionary) -> void:
	tutor_pose = "correct"
	last_event = "session_completed"

func on_session_paused(_snapshot: Dictionary) -> void:
	last_event = "session_paused"

func teacher_texture() -> Texture2D:
	var path := ASSET_ROOT+"teacher_"+tutor_pose+".png"
	if not ResourceLoader.exists(path):
		return null
	var source: Texture2D = load(path)
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = Rect2(Vector2.ZERO,source.get_size())
	# Common transparent canvas keeps the head scale stable across wide gestures.
	texture.margin = Rect2(Vector2((657-source.get_width())/2.0,0),Vector2(657-source.get_width(),433-source.get_height()))
	return texture

static func answer_style(state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color({"idle":"26493e","hover":"3d6048","correct":"386146","wrong":"70423c","disabled":"29443b"}.get(state,"26493e"))
	style.border_color = Color({"correct":"cee78e","wrong":"efaaa0","hover":"f5df9b"}.get(state,"cfceab"))
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style

static func decorated_style(kind := "pill_cream") -> StyleBox:
	var path := ASSET_ROOT+"r2/"+kind+".svg"
	if not ResourceLoader.exists(path):
		return GameUI.paper()
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	for side in [SIDE_LEFT,SIDE_RIGHT]:
		style.set_texture_margin(side,0)
		style.set_content_margin(side,22)
	for side in [SIDE_TOP,SIDE_BOTTOM]:
		style.set_texture_margin(side,0)
		style.set_content_margin(side,8)
	return style

static func chalk_style(kind := "idle") -> StyleBox:
	var path := ASSET_ROOT+"r2/answer_"+kind+".svg"
	if not ResourceLoader.exists(path): return answer_style(kind)
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	for side in [SIDE_LEFT,SIDE_RIGHT]:
		style.set_texture_margin(side,0)
		style.set_content_margin(side,12)
	for side in [SIDE_TOP,SIDE_BOTTOM]:
		style.set_texture_margin(side,0)
		style.set_content_margin(side,10)
	return style

func _draw() -> void:
	if ResourceLoader.exists(ASSET_ROOT+"r2/classroom_environment_v2.png"):
		return # Full independent painted environment replaces geometric props.
	# Original quiet classroom props complement the supplied no-text backplate.
	var w := size.x
	var h := size.y
	if w < 600:
		return
	var desktop := h-75
	draw_style_box(GameUI.flat(Color("65442e"),0),Rect2(0,desktop,w,75))
	for i in 5:
		draw_line(Vector2(0,desktop+12+i*13),Vector2(w,desktop+10+i*13),Color("795138"),1)
	# A little open exercise book and pencil on the desk, no baked words.
	var book := Vector2(w*0.45,desktop+28)
	draw_set_transform(book,-0.06)
	draw_style_box(GameUI.flat(Color("ad6350"),3),Rect2(-106,-18,216,55))
	draw_style_box(GameUI.flat(Color("f7e2b8"),3),Rect2(-100,-24,100,55))
	draw_style_box(GameUI.flat(Color("f7e2b8"),3),Rect2(0,-24,100,55))
	for i in 4:
		draw_line(Vector2(-85,-11+i*9),Vector2(-13,-11+i*9),Color("c9b18b"),1)
		draw_line(Vector2(13,-11+i*9),Vector2(85,-11+i*9),Color("c9b18b"),1)
	draw_line(Vector2(0,-25),Vector2(0,32),Color("b18a59"),2)
	draw_set_transform(Vector2.ZERO)
	var cup := Vector2(w*0.72,desktop+28)
	_paint_ellipse(cup+Vector2(0,20),Vector2(38,10),Color("ead4a8"))
	draw_arc(cup+Vector2(24,-2),12,-PI/2,PI/2,24,Color("f1ddb6"),5,true)
	draw_style_box(GameUI.flat(Color("f6e4bd"),8),Rect2(cup-Vector2(25,18),Vector2(50,37)))
	_paint_ellipse(cup-Vector2(0,14),Vector2(23,7),Color("744425"))
	for i in 3:
		draw_circle(cup+Vector2(-14+i*14,5),3,Color("698c98"))
	# Window plant, stable decorative layer outside the main board.
	var pot := Vector2(w*0.035,h*0.64)
	draw_style_box(GameUI.flat(Color("ad6e43"),4),Rect2(pot.x-15,pot.y,34,40))
	for i in 5:
		var tip := pot+Vector2(-28+i*14,-20-abs(2-i)*8)
		draw_line(pot+Vector2(2,10),tip,Color("52724a"),3,true)
		_paint_ellipse(tip,Vector2(12,6),Color("6d8d54"))

func _paint_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU*i/32.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)
