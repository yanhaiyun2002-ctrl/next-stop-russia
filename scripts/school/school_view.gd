extends BuildingRoom
## Existing navigation contract, independent StudyView and pure ThemePresenter.
const SERVICE = preload("res://scripts/school/study_service.gd")
const PRESENTER = preload("res://scripts/school/theme_presenter.gd")
const PORTRAIT = preload("res://scripts/school/portrait_pages.gd")
var study: SchoolStudyService
var storage_directory := ""
var canvas: Control
var presenter: SchoolThemePresenter
var board: TextureRect
var board_scroll: ScrollContainer
var body: VBoxContainer
var top_panel: PanelContainer
var top_text: Label
var progress_bar: HBoxContainer
var tutor: Control
var teacher: TextureRect
var speech: Label
var tutor_actions: BoxContainer
var hint_button: Button
var audio_button: Button
var notebook_button: Button
var pause_button: Button
var teacher_button: Button
var footer: HBoxContainer
var audio: AudioStreamPlayer
var option_buttons: Array[Button] = []
var next_button: Button
var screen := "home"
var return_screen := "home"
var deck_id := "basic.demo"
var requested_count := 5
var alphabet_index := 0
var alphabet_test := false
var portrait := false
var locked_input := false
var feedback_tween: Tween
var notice := ""
var layout_frames := 4
const PAGE_IDS := {"home":"STUDY_PREPARATION","preview":"WORD_PREVIEW","quiz":"QUIZ_BLACKBOARD","waiting":"QUIZ_BLACKBOARD","summary":"RESULTS"}
var pages: Dictionary = {}
var page_id := "STUDY_PREPARATION"
var paper_panel: Panel
var selected_mode := ""
var mode_buttons: Dictionary = {}
var count_buttons: Dictionary = {}
var start_button: Button
var build_label: Label
var title_badge: Button
var strengthen_label: Label
var standalone := false
var previous_window_title := ""
var background: TextureRect
var landscape_board_texture: Texture2D
var landscape_paper_style: StyleBox
var portrait_paper_style: StyleBox
var teacher_clip: Control
var teacher_lower_clip: Control
var teacher_lower: TextureRect
var portrait_nav: Control
var portrait_back: Button
var portrait_pause: Button
var portrait_settings: Button
var landscape_back: Button
var landscape_pause: Button

func _ready() -> void:
	portrait = get_window().size.y > get_window().size.x
	theme = GameUI.make_theme()
	var school_font := SystemFont.new()
	school_font.font_names = PackedStringArray(["KaiTi","楷体","Georgia","Microsoft YaHei"])
	school_font.allow_system_fallback = true
	var handwritten := FontVariation.new()
	handwritten.base_font = school_font
	handwritten.variation_embolden = .45
	var latin := SystemFont.new()
	# Windows Georgia gives U+0301 an extra advance; Times New Roman keeps the
	# Russian stress mark attached without inserting a gap into the word.
	latin.font_names = PackedStringArray(["Times New Roman"])
	latin.fallbacks = [handwritten]
	theme.default_font = latin
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if study == null:
		if storage_directory.is_empty():
			storage_directory = P1SaveStore.storage_root().path_join(P1RuntimeMode.new().mode).path_join("school-demo")
		study = SERVICE.new(null,SchoolProgressStore.new(storage_directory))
	requested_count = mini(10,maxi(1,study.available(deck_id,"new").size()))
	previous_window_title = get_window().title
	get_window().title = "下一站，俄罗斯！ · 学校 "+preload("res://scripts/school/build_info.gd").VERSION
	preload("res://scripts/school/build_info.gd").log_entry("standalone" if standalone else "integrated",scene_file_path,study.store.path if study.store != null else "memory")
	_build_shell()
	resized.connect(_layout)
	_layout.call_deferred()
	show_home()

func _build_shell() -> void:
	canvas = Control.new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(canvas)
	canvas.resized.connect(func(): layout_frames = 4)
	background = _texture("res://assets/school/r2/classroom_environment_v2.png",canvas)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	presenter = PRESENTER.new()
	presenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(presenter)
	presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board = _texture("res://assets/school/blackboard_empty_scalable.svg",canvas)
	# Standard atlas region skips the contaminated transparent crest above the frame.
	# The source PNG remains unchanged; every question/button is a live Control.
	if ResourceLoader.exists("res://assets/school/blackboard_empty_from_sheet.png"):
		var region := AtlasTexture.new()
		region.atlas = load("res://assets/school/blackboard_empty_from_sheet.png")
		region.region = Rect2(18,75,990,570)
		board.texture = region
	if ResourceLoader.exists("res://assets/school/r2/blackboard_clean_v2.png"):
		board.texture = load("res://assets/school/r2/blackboard_clean_v2.png")
	landscape_board_texture = board.texture
	paper_panel = Panel.new()
	paper_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_panel.add_theme_stylebox_override("panel",GameUI.paper())
	if ResourceLoader.exists("res://assets/school/r2/preparation_parchment_v2.png"):
		var frame := StyleBoxTexture.new()
		frame.texture = load("res://assets/school/r2/preparation_parchment_v2.png")
		paper_panel.add_theme_stylebox_override("panel",frame)
	landscape_paper_style = paper_panel.get_theme_stylebox("panel")
	var portrait_frame := StyleBoxTexture.new()
	portrait_frame.texture = load("res://assets/school/portrait/parchment.png")
	portrait_paper_style = portrait_frame
	canvas.add_child(paper_panel)
	for id in ["STUDY_PREPARATION","WORD_PREVIEW","QUIZ_BLACKBOARD","RESULTS","AUXILIARY"]:
		var scroll := ScrollContainer.new()
		scroll.name = id
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.hide()
		canvas.add_child(scroll)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",13)
		scroll.add_child(column)
		var mobile := Control.new()
		mobile.name = "Portrait_"+id
		mobile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(mobile)
		mobile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mobile.hide()
		pages[id] = {"scroll":scroll,"body":column,"portrait":mobile}
	board_scroll = pages.STUDY_PREPARATION.scroll
	body = pages.STUDY_PREPARATION.body
	top_panel = PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel",PRESENTER.decorated_style("hud_frame"))
	canvas.add_child(top_panel)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",5)
	top_panel.add_child(top)
	top_text = Label.new()
	top_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_text.add_theme_font_size_override("font_size",20)
	top.add_child(top_text)
	progress_bar = HBoxContainer.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_bar.add_theme_constant_override("separation",4)
	top.add_child(progress_bar)
	strengthen_label = Label.new()
	strengthen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strengthen_label.add_theme_color_override("font_color",Color("6c3d25"))
	top.add_child(strengthen_label)
	title_badge = _button(canvas,"学习准备",_back_to_preparation)
	title_badge.add_theme_stylebox_override("normal",PRESENTER.decorated_style("primary_green"))
	title_badge.add_theme_color_override("font_color",Color("f7df9d"))
	tutor = Control.new()
	tutor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tutor)
	speech = Label.new()
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var bubble := StyleBoxTexture.new()
	bubble.texture = load("res://assets/school/r2/speech_bubble.svg") if ResourceLoader.exists("res://assets/school/r2/speech_bubble.svg") else null
	bubble.content_margin_left = 20
	bubble.content_margin_right = 22
	bubble.content_margin_top = 14
	bubble.content_margin_bottom = 25
	speech.add_theme_stylebox_override("normal",bubble)
	speech.add_theme_font_size_override("font_size",18)
	tutor.add_child(speech)
	teacher = TextureRect.new()
	teacher.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	teacher.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	teacher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teacher_clip = Control.new()
	teacher_clip.clip_contents = true
	teacher_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutor.add_child(teacher_clip)
	teacher_clip.add_child(teacher)
	# A second clipped span reveals the natural lower silhouette below the choices.
	# The upper span remains outside every answer hitbox in portrait.
	teacher_lower_clip = Control.new()
	teacher_lower_clip.clip_contents = true
	teacher_lower_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutor.add_child(teacher_lower_clip)
	teacher_lower = TextureRect.new()
	teacher_lower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	teacher_lower.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	teacher_lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teacher_lower_clip.add_child(teacher_lower)
	tutor_actions = BoxContainer.new()
	tutor.add_child(tutor_actions)
	audio_button = _button(tutor_actions,"发音 · 未提供录音",_play_audio)
	hint_button = _button(tutor_actions,"提示 · 辅助作答",_hint)
	notebook_button = _button(tutor_actions,"俄语记事本",show_notebook)
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	canvas.add_child(footer)
	back_button = _button(footer,"← 返回校园",_leave)
	pause_button = _button(footer,"暂停 / 保存",_pause)
	landscape_back = back_button
	landscape_pause = pause_button
	teacher_button = _button(footer,"收起老师",_toggle_teacher)
	_button(footer,"设置",show_settings)
	portrait_nav = Control.new()
	portrait_nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(portrait_nav)
	portrait_nav.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_back = _button(portrait_nav,"← 返回",_leave)
	portrait_pause = _button(portrait_nav,"Ⅱ",_pause)
	portrait_pause.tooltip_text = "暂停并保存"
	portrait_settings = _button(portrait_nav,"⚙",show_settings)
	for control in [portrait_pause,portrait_settings]:
		control.custom_minimum_size = Vector2(36,36)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style := GameUI.flat(Color("fff0d1"),22)
			style.set_content_margin_all(5)
			control.add_theme_stylebox_override(state,style)
	build_label = Label.new()
	build_label.text = preload("res://scripts/school/build_info.gd").VERSION+" · 6 词示例"
	build_label.add_theme_font_size_override("font_size",12)
	build_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(build_label)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	feedback = Label.new()
	feedback.hide()
	add_child(feedback)

func _texture(path: String, parent: Node) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(path) if ResourceLoader.exists(path) else null
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size

func _layout() -> void:
	if canvas == null:
		return
	var w := canvas.size.x
	var h := canvas.size.y
	var was_portrait := portrait
	portrait = h > w
	_sync_page_visibility()
	if portrait:
		_layout_portrait(w,h)
		if was_portrait != portrait: _redraw_screen.call_deferred()
		return
	background.texture = load("res://assets/school/r2/classroom_environment_v2.png")
	top_panel.add_theme_stylebox_override("panel",PRESENTER.decorated_style("hud_frame"))
	top_panel.get_child(0).move_child(strengthen_label,2)
	board.texture = landscape_board_texture
	paper_panel.add_theme_stylebox_override("panel",landscape_paper_style)
	footer.show()
	portrait_nav.hide()
	teacher_lower_clip.hide()
	strengthen_label.show()
	title_badge.add_theme_font_size_override("font_size",17)
	title_badge.add_theme_stylebox_override("normal",PRESENTER.decorated_style("primary_green"))
	title_badge.add_theme_color_override("font_color",Color("f7df9d"))
	back_button = landscape_back
	pause_button = landscape_pause
	tutor_actions.show()
	hint_button.text = "提示 · 辅助作答"
	notebook_button.text = "俄语记事本"
	_rect(top_panel,Rect2(8,10,w-16,68) if portrait else Rect2(w*0.25,h*0.02,w*0.57,h*0.075))
	_rect(title_badge,Rect2(10,82,125,34) if portrait else Rect2(w*0.065,h*0.018,w*0.18,h*0.08))
	title_badge.hide() if portrait else title_badge.show()
	var r := Rect2(7,95,w-14,h-275) if portrait else (Rect2(w*0.105,h*0.105,w*0.695,h*0.72) if page_id == "QUIZ_BLACKBOARD" else Rect2(w*0.215,h*0.10,w*0.56,h*0.795))
	_rect(board,r)
	_rect(paper_panel,r)
	var inset := Vector2(25,70) if portrait else (Vector2(r.size.x*0.10,r.size.y*0.23) if page_id == "QUIZ_BLACKBOARD" else Vector2(r.size.x*0.075,r.size.y*0.18))
	for page in pages.values():
		_rect(page.scroll,Rect2(r.position+inset,Vector2(r.size.x-inset.x*2,r.size.y-inset.y-r.size.y*(0.065 if page_id == "QUIZ_BLACKBOARD" else 0.045))))
	_rect(tutor,Rect2(12,h-174,w-24,112) if portrait else Rect2(w*0.79,h*0.125,w*0.205,h*0.76))
	if portrait:
		_rect(teacher,Rect2(0,0,78,72))
		_rect(speech,Rect2(82,0,tutor.size.x-82,56))
		_rect(tutor_actions,Rect2(0,64,tutor.size.x,46))
		tutor_actions.vertical = false
	else:
		_rect(speech,Rect2(-10,0,tutor.size.x+10,h*0.19))
		var teacher_height := h*0.43
		var teacher_width := teacher_height*657.0/433.0
		_rect(teacher_clip,Rect2(-w*.12,h*.18,tutor.size.x+w*.24,teacher_height))
		_rect(teacher,Rect2(teacher_clip.size.x*.5-teacher_width*.5,0,teacher_width,teacher_height))
		_rect(tutor_actions,Rect2(0,h*0.535,tutor.size.x,h*0.21))
		tutor_actions.vertical = true
	_rect(footer,Rect2(12,h-54,w-24,44) if portrait else Rect2(w*0.015,h*0.938,w*0.36,h*0.048))
	_rect(build_label,Rect2(14,h-76,200,18) if portrait else Rect2(w*0.78,h*0.954,w*0.21,18))
	for button in footer.get_children():
		button.custom_minimum_size.y = 44 if portrait else 32
		button.add_theme_font_size_override("font_size",12)
	back_button.text = "退出" if standalone else "返回"
	pause_button.text = "暂停"
	teacher_button.text = "老师"
	for button in tutor_actions.get_children():
		button.custom_minimum_size.y = 44 if portrait else h*0.061
		button.add_theme_font_size_override("font_size",12 if portrait else 19)
		for state in ["normal","hover","pressed","focus","disabled"]:
			button.add_theme_stylebox_override(state,PRESENTER.decorated_style("pill_cream"))
	top_text.add_theme_font_size_override("font_size",12 if portrait else 18)
	strengthen_label.add_theme_font_size_override("font_size",12 if portrait else 18)
	speech.add_theme_font_size_override("font_size",14 if portrait else 20)
	if was_portrait != portrait:
		_redraw_screen.call_deferred()

func _layout_portrait(w: float, h: float) -> void:
	background.texture = load("res://assets/school/portrait/environment.png")
	board.texture = load("res://assets/school/portrait/blackboard.png")
	paper_panel.add_theme_stylebox_override("panel",portrait_paper_style)
	var is_quiz := page_id == "QUIZ_BLACKBOARD"
	var hud := PRESENTER.decorated_style("portrait_pill")
	hud.set_content_margin_all(7)
	top_panel.add_theme_stylebox_override("panel",hud)
	top_panel.get_child(0).move_child(strengthen_label,1)
	_rect(board,Rect2(w*.035,h*.165,w*.93,h*.56))
	_rect(paper_panel,Rect2(w*.075,h*.070,w*.85,h*.825))
	for page in pages.values():
		_rect(page.scroll,Rect2(w*.16,h*.225,w*.60,h*.57))
	_rect(title_badge,Rect2(w*.035,h*.116,w*.22,h*.047) if is_quiz else Rect2(w*.025,h*.012,w*.31,h*.047))
	title_badge.show()
	title_badge.add_theme_font_size_override("font_size",15)
	var badge_style := PRESENTER.decorated_style("portrait_pill" if is_quiz else "primary_green")
	badge_style.set_content_margin_all(5)
	title_badge.add_theme_stylebox_override("normal",badge_style)
	title_badge.add_theme_color_override("font_color",Color("59361d") if is_quiz else Color("f7df9d"))
	_rect(top_panel,Rect2(w*.36,h*.014,w*.61,h*.043) if not is_quiz else Rect2(w*.24,h*.117,w*.725,h*.045))
	top_text.add_theme_font_size_override("font_size",13)
	strengthen_label.visible = is_quiz
	strengthen_label.add_theme_font_size_override("font_size",13)
	_rect(tutor,Rect2(0,0,w,h))
	var teacher_y := .49 if is_quiz else .65
	var teacher_height := h*(.34 if is_quiz else .25)
	var teacher_left := .70 if screen in ["home","quiz","waiting"] else .78
	_rect(teacher_clip,Rect2(w*teacher_left,h*teacher_y,w*(1.0-teacher_left),teacher_height))
	var teacher_width := teacher_height*657.0/433.0
	_rect(teacher,Rect2(w*(.22 if is_quiz else .16)-teacher_width*.5,0,teacher_width,teacher_height))
	teacher_lower_clip.visible = is_quiz and teacher.visible
	if is_quiz:
		var split := h*.64
		for answer in option_buttons:
			if is_instance_valid(answer): split = maxf(split,answer.get_global_rect().end.y-tutor.global_position.y+3)
		teacher_clip.size.y = maxf(0,split-h*teacher_y)
		_rect(teacher_lower_clip,Rect2(w*.60,split,w*.40,maxf(0,h*(teacher_y+.34)-split)))
		_rect(teacher_lower,Rect2(teacher_clip.position+teacher.position-teacher_lower_clip.position,teacher.size))
	_rect(speech,Rect2(w*.71,h*.335,w*.28,h*.132) if is_quiz else Rect2(w*.24,h*.733,w*.43,h*.080))
	var bubble: StyleBox = speech.get_theme_stylebox("normal").duplicate()
	bubble.content_margin_left = 12
	bubble.content_margin_right = 12
	bubble.content_margin_top = 8
	bubble.content_margin_bottom = 14
	speech.add_theme_stylebox_override("normal",bubble)
	speech.add_theme_font_size_override("font_size",13 if is_quiz else 16)
	tutor_actions.visible = is_quiz
	tutor_actions.vertical = false
	_rect(tutor_actions,Rect2(w*.30,h*.912,w*.68,h*.052))
	for button in tutor_actions.get_children():
		button.custom_minimum_size = Vector2(0,44)
		button.add_theme_font_size_override("font_size",14)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style := PRESENTER.decorated_style("portrait_pill")
			style.set_content_margin_all(5)
			button.add_theme_stylebox_override(state,style)
	if audio_button.disabled:
		audio_button.text = "发音(缺)" if not audio_button.text.contains("作答后") else "发音(锁)"
	hint_button.text = "提示"
	notebook_button.text = "记事本"
	portrait_nav.show()
	_rect(portrait_back,Rect2(w*.025,h*(.025 if is_quiz else .065),w*.23,36))
	portrait_back.custom_minimum_size.y = 36
	portrait_back.add_theme_font_size_override("font_size",14)
	_rect(portrait_pause,Rect2(w-96,h*(.025 if is_quiz else .065),38,38))
	_rect(portrait_settings,Rect2(w-48,h*(.025 if is_quiz else .065),38,38))
	back_button = portrait_back
	pause_button = portrait_pause
	pause_button.disabled = study.state.session.is_empty() or study.state.session.status == "completed"
	footer.hide()
	_rect(build_label,Rect2(w*.54,h*.974,w*.43,16))
	build_label.add_theme_font_size_override("font_size",10)
	PORTRAIT.layout(self)

func _sync_page_visibility() -> void:
	for id in pages:
		var blocked: bool = study.store != null and study.store.blocked
		var mobile: bool = portrait and id == page_id and screen in ["home","quiz"] and not blocked
		pages[id].portrait.visible = mobile
		pages[id].scroll.visible = id == page_id and not mobile

func active_page_root() -> Control:
	return pages[page_id].portrait if pages[page_id].portrait.visible else body

func _clear(kind: String) -> void:
	layout_frames = 4
	if is_instance_valid(feedback_tween):
		feedback_tween.kill()
	teacher.modulate = Color.WHITE
	var old_screen := screen
	screen = kind
	page_id = PAGE_IDS.get(kind,"AUXILIARY")
	for id in pages:
		pages[id].scroll.visible = id == page_id
	board_scroll = pages[page_id].scroll
	body = pages[page_id].body
	board.visible = page_id == "QUIZ_BLACKBOARD"
	paper_panel.visible = not board.visible
	print("SCHOOL_TRACE ",JSON.stringify({"event":"page","from":old_screen,"screen":kind,"page":page_id}))
	option_buttons.clear()
	next_button = null
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in pages[page_id].portrait.get_children():
		pages[page_id].portrait.remove_child(child)
		child.queue_free()
	_sync_page_visibility()
	board_scroll.scroll_vertical = 0
	locked_input = false
	body.add_theme_constant_override("separation",5 if kind == "home" else (16 if kind == "quiz" else 10))
	presenter.configure(study.state.settings)
	_refresh_header()

func _text(value: String, font_size := 20, color := Color("f2e6c6")) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",mini(font_size,28) if portrait else font_size)
	label.add_theme_color_override("font_color",color if page_id == "QUIZ_BLACKBOARD" or color != Color("f2e6c6") else Color("513c29"))
	body.add_child(label)
	return label

func _button(parent: Node, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size",17)
	for state_name in ["normal","hover","pressed","disabled","focus"]:
		button.add_theme_stylebox_override(state_name,PRESENTER.decorated_style("pill_cream"))
	button.add_theme_color_override("font_disabled_color",Color("85735b"))
	button.pressed.connect(func():
		print("SCHOOL_TRACE ",JSON.stringify({"event":"pressed","control":button.name,"text":button.get_meta("caption",button.text),"page":page_id}))
		callback.call())
	parent.add_child(button)
	return button

func _chalk_button(value: String, callback: Callable) -> Button:
	var button := _button(body,value,callback)
	if page_id == "QUIZ_BLACKBOARD":
		_style_answer(button,"idle")
	return button

func _decorate_primary(button: Button) -> void:
	for state_name in ["normal","hover","pressed","focus"]:
		button.add_theme_stylebox_override(state_name,PRESENTER.decorated_style("primary_green"))
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(key,Color("fff0b8"))
	button.add_theme_font_size_override("font_size",22 if not portrait else 17)

func _decorate_mode_card(button: Button, mode: String, caption: String, selected: bool) -> void:
	button.text = ""
	button.set_meta("caption",caption)
	button.tooltip_text = caption
	var stack := VBoxContainer.new()
	button.add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_left = 10
	stack.offset_right = -10
	stack.offset_top = 6
	stack.offset_bottom = -6
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation",0)
	var icon := _texture("res://assets/school/r2/mode_"+{"new":"book","review":"review","notebook":"dictionary"}[mode]+".svg",stack)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size.y = 44 if portrait else 57
	var label := Label.new()
	label.text = ("✓ " if selected else "")+caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",15 if portrait else 19)
	label.add_theme_color_override("font_color",Color("fff1ba") if selected else Color("583a24"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(label)

func _style_answer(button: Button, kind: String) -> void:
	for state_name in ["normal","pressed","disabled","focus"]:
		button.add_theme_stylebox_override(state_name,PRESENTER.chalk_style(kind))
	button.add_theme_stylebox_override("hover",PRESENTER.chalk_style("hover"))
	for key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:
		button.add_theme_color_override(key,Color("f6edcf"))

func _refresh_header() -> void:
	var p := study.progress()
	var display_total: int = p.total
	var display_passed: int = p.passed
	top_text.text = "已通过 %d/%d" % [p.passed,p.total] if p.total > 0 else "俄语学习"
	strengthen_label.text = "待强化 %d 词" % p.strengthening
	title_badge.text = {"STUDY_PREPARATION":"学习准备","WORD_PREVIEW":"单词预习","QUIZ_BLACKBOARD":"今日学习","RESULTS":"学习回顾"}.get(page_id,"俄语课堂")
	if page_id == "STUDY_PREPARATION":
		var learned := 0
		for r in study.state.records.values():
			learned += int(r.firstLearned)
		top_text.text = "已首学 %d / %d" % [learned,study.content.words.size()]
		strengthen_label.text = "学校 > 俄语学习"
		display_total = study.content.words.size()
		display_passed = learned
	for child in progress_bar.get_children():
		progress_bar.remove_child(child)
		child.queue_free()
	for i in maxi(1,display_total):
		var segment := Panel.new()
		segment.custom_minimum_size.y = 14
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.add_theme_stylebox_override("panel",GameUI.flat(Color("7d9b30") if i < display_passed else Color("c6bcac"),6))
		progress_bar.add_child(segment)
	teacher.visible = study.state.settings.teacher
	teacher_lower.visible = teacher.visible
	teacher_button.text = "收起老师" if teacher.visible else "显示老师"
	pause_button.disabled = study.state.session.is_empty() or study.state.session.status == "completed"
	presenter.configure(study.state.settings)

func _tutor(message: String, pose := "idle") -> void:
	layout_frames = 4
	presenter.tutor_pose = pose
	teacher.texture = presenter.teacher_texture()
	teacher_lower.texture = teacher.texture
	speech.text = message
	hint_button.disabled = screen != "quiz" or study.state.session.activeQuestion.get("submitted",true)
	audio_button.disabled = true
	audio_button.text = "发音 · 未提供录音"
	if screen == "quiz" and not study.state.session.activeQuestion.is_empty():
		var q: Dictionary = study.state.session.activeQuestion
		if not study.content.has_audio(q.wordId):
			audio_button.text = "发音 · 未提供录音"
		elif q.kind == "ZH_TO_RU" and not q.submitted:
			audio_button.text = "发音 · 作答后开放"
		else:
			audio_button.disabled = false
			audio_button.text = "发音 · 点击重听"
	audio_button.tooltip_text = audio_button.text

func show_home() -> void:
	_clear("home")
	mode_buttons.clear()
	count_buttons.clear()
	if study.store != null and study.store.blocked:
		_text("学校学习暂不可用",28)
		_text(study.error if not study.error.is_empty() else study.store.error,19)
		_text("原存档已保留。可返回学校，或恢复对应内容后重试。",17)
		action_button = _chalk_button("返回学校",_leave)
		_tutor("原有生活内容不受影响。")
		return
	if portrait:
		PORTRAIT.preparation(self)
		return
	_text("学习准备",28)
	_text("──  选择学习模块  ──",16)
	var modes := GridContainer.new()
	modes.columns = 3
	modes.add_theme_constant_override("h_separation",12)
	body.add_child(modes)
	for item in [["new","学习新词"],["review","复习旧词"],["notebook","查看词本"]]:
		var mode: String = item[0]
		var card := _button(modes,item[1],func(): _select_mode(mode))
		card.name = "Mode_"+mode
		card.custom_minimum_size.y = 100 if not portrait else 80
		mode_buttons[mode] = card
		for style_state in ["normal","hover","pressed","focus"]:
			card.add_theme_stylebox_override(style_state,PRESENTER.decorated_style("mode_green" if selected_mode == mode else "mode_paper"))
		_decorate_mode_card(card,mode,item[1],selected_mode == mode)
	var mode := _effective_mode()
	var eligible := study.available(deck_id,mode).size()
	if selected_mode.is_empty():
		eligible = study.available(deck_id,"new").size()
	requested_count = clampi(requested_count,1,maxi(1,eligible))
	_text("──  今日学习计划  ──",18)
	var counts := HBoxContainer.new()
	counts.add_theme_constant_override("separation",8)
	body.add_child(counts)
	for count in range(1,eligible+1):
		var quantity: int = count
		var chip := _button(counts,str(count),func(): _choose_count(quantity))
		chip.name = "Count_"+str(count)
		chip.custom_minimum_size.y = 36
		chip.add_theme_font_size_override("font_size",20)
		count_buttons[count] = chip
		if count == requested_count:
			chip.add_theme_stylebox_override("normal",PRESENTER.decorated_style("primary_green"))
			chip.add_theme_color_override("font_color",Color("fff1bd"))
	if eligible == 0:
		_text("当前词包没有可学新词" if selected_mode in ["","new"] else "当前没有可复习的已学词",19)
		if not study.available(deck_id,"free_review").is_empty():
			_chalk_button("复习已学词 →",func(): _select_mode("review"))
	else:
		_text("本次可学 %d 词 · 已选 %d 词" % [eligible,requested_count],14)
	var deck := OptionButton.new()
	for id in study.state.availableDecks:
		deck.add_item(study.content.decks[id].title)
		deck.set_item_metadata(deck.item_count-1,id)
		if id == deck_id: deck.select(deck.item_count-1)
	deck.custom_minimum_size.y = 30
	deck.add_theme_font_size_override("font_size",14)
	deck.item_selected.connect(func(i): deck_id = deck.get_item_metadata(i); requested_count = mini(10,maxi(1,study.available(deck_id,_effective_mode()).size())); show_home())
	body.add_child(deck)
	_text("预计学习：%d 个%s  ·  旅行与生活" % [requested_count if eligible > 0 else 0,"新词" if mode == "new" else "复习词"],17)
	if selected_mode == "review" and mode == "free_review":
		_text("暂无到期单词，本次为已学词自由复习。",16)
	var pending: bool = not study.state.session.is_empty() and study.state.session.status != "completed"
	if not notice.is_empty():
		_text(notice,15,Color("9a3f28"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	body.add_child(actions)
	_button(actions,"返回学校",_leave)
	start_button = _button(actions,"继续上次学习 ▶" if pending else "开始学习 ▶",_prepare_start)
	start_button.name = "StartStudy"
	start_button.custom_minimum_size.y = 50
	start_button.size_flags_stretch_ratio = 1.7
	_decorate_primary(start_button)
	_button(actions,"学习设置",show_settings)
	var links := HBoxContainer.new()
	body.add_child(links)
	action_button = _button(links,"字母入门 · %d/33" % _alphabet_count(),interact)
	action_button.custom_minimum_size.y = 30
	action_button.add_theme_font_size_override("font_size",13)
	if not study.state.session.is_empty() and study.state.session.status == "completed":
		_chalk_button("查看上轮结算",func(): study.next_question(); show_session())
	_tutor(notice if not notice.is_empty() else ("上次学习已保存，点击继续回到原有题目。" if pending else "准备好开始今天的俄语学习了吗？"))
	feedback.text = "独立学习准备页"

func _effective_mode() -> String:
	if selected_mode == "review":
		return "review" if not study.available(deck_id,"review").is_empty() else "free_review"
	return "new"

func _select_mode(mode: String) -> void:
	print("SCHOOL_TRACE ",JSON.stringify({"event":"select_mode","mode":mode,"page":page_id}))
	if mode == "notebook":
		show_notebook()
		return
	selected_mode = mode
	notice = ""
	requested_count = mini(10,maxi(1,study.available(deck_id,_effective_mode()).size()))
	show_home()

func _choose_count(count: int) -> void:
	var eligible := study.available(deck_id,_effective_mode()).size()
	if count < 1 or count > eligible:
		notice = "本次仅有 %d 个可学习词，请选择 1～%d。" % [eligible,eligible]
	else:
		requested_count = count
		if not study.set_setting("newCount",count):
			notice = study.error
		else:
			notice = ""
	show_home()

func _prepare_start() -> void:
	if not study.state.session.is_empty() and study.state.session.status != "completed":
		_resume()
		return
	if selected_mode.is_empty():
		notice = "请先选择「学习新词」或「复习旧词」。"
		show_home()
		return
	var mode := _effective_mode()
	var eligible := study.available(deck_id,mode).size()
	if eligible == 0:
		notice = "当前词包没有可学新词，请查看词本或复习已学词。" if mode == "new" else "暂无已学词可复习，可以先选择学习新词。"
		show_home()
		return
	_start(mode,requested_count)

func _back_to_preparation() -> void:
	if study.pause():
		show_home()
	else:
		_text(study.error,17)

func interact() -> void:
	if not study.pause():
		_tutor(study.error)
		return
	interaction_count += 1
	feedback.text = "字母辨形练习"
	alphabet_test = false
	for i in study.content.letters.size():
		if not study.state.alphabet.get(study.content.letters[i].id,{}).get("passed",false):
			alphabet_index = i
			break
	show_alphabet()

func _alphabet_count() -> int:
	var count := 0
	for value in study.state.alphabet.values():
		count += int(value.get("passed",false))
	return count

func show_alphabet() -> void:
	_clear("alphabet")
	var letter: Dictionary = study.content.letters[alphabet_index]
	if not study.alphabet_view(letter.id):
		_text(study.error)
		return
	_text("字母入门 · 第 %d 组" % letter.lessonGroup,23)
	_text("%d / 33  ·  已辨认 %d" % [alphabet_index+1,_alphabet_count()],16)
	_text(letter.upper if alphabet_test else letter.upper+"  "+letter.lower,68)
	if not alphabet_test:
		_text({"vowel":"元音字母","consonant":"辅音字母","sign":"特殊符号 · 无独立常规读音"}.get(letter.category,""),21)
		_text(letter.notes if not letter.notes.is_empty() else "发音说明与录音待教学审校，本页先练习辨形。",16)
		_chalk_button("开始辨形 →",func(): alphabet_test = true; show_alphabet())
	else:
		_text("请选择它的小写字母",21)
		var options: Array = [letter.lower,study.content.letters[(alphabet_index+7)%33].lower,study.content.letters[(alphabet_index+19)%33].lower]
		options.sort()
		for choice in options:
			var selected: String = choice
			_chalk_button(selected,func():
				if study.alphabet_answer(letter.id,selected):
					alphabet_test = false
					if alphabet_index < 32:
						alphabet_index += 1
						show_alphabet()
					else:
						show_home()
				else:
					_tutor("再观察一次大写字母的形状。","hint"))
	var row := HBoxContainer.new()
	body.add_child(row)
	_button(row,"← 上一个",func(): alphabet_index = (alphabet_index+32)%33; alphabet_test = false; show_alphabet())
	_button(row,"下一个 →",func(): alphabet_index = (alphabet_index+1)%33; alphabet_test = false; show_alphabet())
	_chalk_button("返回学习中心",show_home)
	_tutor("辨形通过不会把示例词算作已学词。")

func _start(mode: String, count: int) -> void:
	print("SCHOOL_TRACE ",JSON.stringify({"event":"start_pressed","screen":screen,"mode":mode,"count":count,"eligible":study.available(deck_id,mode).size(),"save":study.store.path if study.store != null else "memory"}))
	if study.start(deck_id,count,mode,int(Time.get_unix_time_from_system())):
		print("SCHOOL_TRACE ",JSON.stringify({"event":"route","from":screen,"to":"WORD_PREVIEW","sessionId":study.state.session.sessionId}))
		presenter.on_session_start(study.state.session)
		show_session()
	else:
		notice = study.error
		show_home()

func _resume() -> void:
	if study.resume():
		show_session()
	else:
		notice = study.error
		show_home()

func show_session() -> void:
	var s: Dictionary = study.state.session
	if s.is_empty():
		show_home()
		return
	if s.status == "paused":
		show_paused()
	elif s.phase == "preview":
		show_preview()
	elif s.phase == "summary":
		show_summary()
	elif s.phase == "waiting":
		show_waiting()
	elif s.activeQuestion.is_empty():
		if study.next_question():
			show_session()
		else:
			_clear("error")
			_text(study.error)
			_chalk_button("暂停并返回",_pause)
	else:
		show_quiz()

func show_preview() -> void:
	_clear("preview")
	if not study.preview_view():
		_text(study.error)
		return
	var s: Dictionary = study.state.session
	var id: String = s.previewIds[int(s.previewIndex)]
	var word: Dictionary = study.content.words[id]
	_text("词卡预习 · %d / %d" % [s.previewIndex+1,s.previewIds.size()],22)
	_text("辨认辅助词 · 不计入本轮目标" if id not in s.targetLexemeIds else "本轮目标词",16)
	_text(word.stressDisplay,54)
	_text(" / ".join(word.zhMeanings),32)
	if word.has("partOfSpeech"):
		_text({"noun":"名词"}.get(word.partOfSpeech,word.partOfSpeech),17)
	_text("重音辅助如上；尚无经审校例句与发音录音。",16)
	var audio_preview := _chalk_button("发音 · 未提供录音",func(): _play_word(id))
	audio_preview.disabled = not study.content.has_audio(id)
	if not audio_preview.disabled:
		audio_preview.text = "播放真实发音"
	if s.previewIndex > 0:
		_chalk_button("← 上一张",func():
			if study.preview_previous():
				show_preview())
	_chalk_button("开始测验 →" if s.previewIndex+1 == s.previewIds.size() else "记下并查看下一张 →",func():
		if study.preview_next():
			show_session()
		else:
			_text(study.error))
	_chalk_button("返回学习准备 · 保存预习",_back_to_preparation)
	_tutor("先熟悉词形和含义。预习与正式通过分别记录。")

func show_quiz() -> void:
	_clear("quiz")
	if portrait:
		PORTRAIT.quiz(self)
		return
	var q: Dictionary = study.state.session.activeQuestion
	presenter.on_question_shown(q)
	var item: Dictionary = study.state.session.items[q.wordId]
	var type_label := _text("⇄  "+{"ZH_TO_RU":"中文选俄语","RU_TO_ZH":"俄语选中文","AUDIO_TO_RU":"听音选俄语"}[q.kind],24)
	type_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	type_label.custom_minimum_size.x = minf(canvas.size.x*0.29,400) if not portrait else 230
	type_label.add_theme_stylebox_override("normal",PRESENTER.decorated_style("primary_green"))
	if item.everWrong and not q.submitted:
		_text("强化练习 · 还需独立正确 %d 次" % item.remainingCorrect,15)
	if q.kind == "AUDIO_TO_RU":
		_chalk_button("▶ 听发音，选俄语",_play_audio)
	else:
		var prompt_panel := PanelContainer.new()
		var prompt_style := StyleBoxTexture.new()
		prompt_style.texture = load("res://assets/school/r2/chalk_prompt_swipe.svg")
		prompt_style.content_margin_top = 10
		prompt_style.content_margin_bottom = 10
		prompt_style.content_margin_left = 18
		prompt_style.content_margin_right = 18
		prompt_panel.add_theme_stylebox_override("panel",prompt_style)
		prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		prompt_panel.custom_minimum_size.x = canvas.size.x*0.36 if not portrait else 240
		body.add_child(prompt_panel)
		var prompt := Label.new()
		prompt.text = q.prompt
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_font_size_override("font_size",35 if portrait else 50)
		prompt.add_theme_color_override("font_color",Color("493c29"))
		prompt_panel.add_child(prompt)
	var grid := GridContainer.new()
	grid.columns = 1 if portrait else (2 if q.options.size() == 4 else q.options.size())
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",9)
	body.add_child(grid)
	for option in q.options:
		var answer: String = option.id
		var button := _button(grid,option.text,func(): _answer(q.id,answer))
		button.custom_minimum_size.y = 54 if portrait else 70
		button.add_theme_font_size_override("font_size",24 if portrait else 34)
		button.disabled = q.submitted
		var mark := "idle"
		if q.submitted:
			if answer == q.wordId:
				mark = "correct"
				button.text = "✓ "+option.text
			elif answer == q.result.selectedId:
				mark = "wrong"
				button.text = "× "+option.text
			else:
				mark = "disabled"
		_style_answer(button,mark)
		option_buttons.append(button)
	if q.submitted:
		presenter.on_answer_evaluated(q.result)
		var result_text := _result_text(q.result)
		_text(result_text,18,Color("e9dba7") if q.result.assisted else (Color("d3e8b6") if q.result.correct else Color("f0b8a5")))
		if not q.result.correct or q.result.assisted:
			var word: Dictionary = study.content.words[q.wordId]
			_text("正确答案：%s · %s" % [word.stressDisplay,word.zhMeanings[0]],20)
		next_button = _chalk_button("查看本轮结算 →" if study.state.session.status == "completed" else "继续 →",func():
			if study.next_question():
				show_session()
			else:
				_text(study.error))
		next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		next_button.custom_minimum_size = Vector2(230,40)
		for key in ["normal","hover","pressed","focus"]:
			next_button.add_theme_stylebox_override(key,PRESENTER.decorated_style("pill_cream"))
		for key in ["font_color","font_hover_color","font_pressed_color"]:
			next_button.add_theme_color_override(key,Color("563824"))
		_tutor("正确，继续保持。" if q.result.correct and not q.result.assisted else "不用着急，看看板上的说明。",presenter.tutor_pose)
	else:
		if q.assisted:
			_text("已查看提示，本题不计入独立通过。",16)
		_tutor("回想预习时的词义。选项的位置会变化。","hint" if q.assisted else "idle")
	_refresh_header()

func _result_text(result: Dictionary) -> String:
	if result.assisted:
		return "已查看提示，本题不计入独立通过。之后仍需正确 %d 次。" % result.remainingCorrect
	if result.correct:
		if result.wordPassed:
			return "✓ 强化完成，该词通过。" if result.strengthening else "✓ 回答正确，该词通过。"
		return "✓ 强化进度 %d/2，之后还需独立答对 %d 次。" % [result.correctInStrengthening,result.remainingCorrect]
	return "× 之后需累计独立答对 2 次。" if result.remainingCorrect == 2 else "× 强化仍需独立答对 %d 次，已正确的次数保留。" % result.remainingCorrect

func _answer(question_id: String, answer: String) -> void:
	if locked_input:
		return
	locked_input = true
	if study.submit(question_id,answer):
		show_quiz()
		var result: Dictionary = study.state.session.activeQuestion.result
		if result.wordPassed:
			presenter.on_word_passed(result.wordId,study.progress())
		if not study.state.settings.reducedMotion:
			teacher.modulate = Color(1.1,1.1,1.05)
			feedback_tween = create_tween()
			feedback_tween.tween_property(teacher,"modulate",Color.WHITE,presenter.feedback_seconds())
	else:
		locked_input = false
		if not study.error.is_empty():
			_text(study.error,17,Color("efb2a0"))
			_tutor(study.error,"explain")

func _hint() -> void:
	if screen != "quiz":
		return
	var q: Dictionary = study.state.session.activeQuestion
	if study.use_hint(q.id):
		show_quiz()
		_tutor("已标记辅助。\n本题暂不计通过。" if portrait else "先排除混淆的词义。已标记辅助作答，本题不会直接通过。","hint")
	elif not study.error.is_empty():
		_tutor(study.error,"explain")

func show_waiting() -> void:
	_clear("waiting")
	_text("分轮强化",32)
	_text("可穿插的不同词不足。先休息片刻，再换题型与选项位置重测。",21)
	_text("通过词数保留；这里不会冒充新题或额外目标词。",16)
	next_button = _chalk_button("稍后继续",func():
		if study.next_question():
			show_session())
	_tutor("从记忆中再回想一次，不必急着点答案。")
	_update_waiting()

func _process(_delta: float) -> void:
	if layout_frames > 0:
		layout_frames -= 1
		_layout()
	if screen == "waiting":
		_update_waiting()

func _update_waiting() -> void:
	if next_button == null or study.state.session.is_empty():
		return
	var left := maxi(0,int(study.state.session.readyAt)-int(study.now.call()))
	next_button.disabled = left > 0
	next_button.text = "休息 %d 秒后继续" % left if left > 0 else "开始下一轮强化 →"

func show_summary() -> void:
	_clear("summary")
	var p := study.progress()
	if study.state.session.status != "completed" or p.passed != p.total:
		_text("本轮尚未完成")
		return
	presenter.on_session_completed(p)
	_text("✓ 本轮学习完成",34)
	_text("已通过 %d / %d 个不同词条" % [p.passed,p.total],26)
	_text("强化过 %d 词  ·  本轮错误 %d 次" % [p.everStrengthened,p.errors],21)
	_text("学习记录已保存。最早复习间隔为 1 天；单轮通过不等于长期掌握。",18)
	_chalk_button("查看俄语记事本",show_notebook)
	_chalk_button("返回学习中心",show_home)
	_chalk_button("返回学校",_leave)
	_tutor("今天的练习完成了。下次再来巩固。","correct")

func _pause() -> void:
	if study.pause():
		presenter.on_session_paused(study.state.session)
		show_paused()
	else:
		_text(study.error)

func show_paused() -> void:
	_clear("paused")
	_text("已暂停 · 进度已保存",29)
	_text("当前题目、反馈、强化次数和重测顺序均已保留。",19)
	_chalk_button("继续学习 →",_resume)
	_chalk_button("返回学习中心",show_home)
	_tutor("休息一下，回来接着学。")

func show_notebook() -> void:
	if screen != "notebook":
		return_screen = screen
		if screen == "quiz" and not study.state.session.activeQuestion.submitted:
			# Consulting the dictionary must never bypass independent-answer scoring.
			study.use_hint(study.state.session.activeQuestion.id)
		if not study.pause():
			_text(study.error)
			return
	_clear("notebook")
	_text("俄语记事本",32)
	_text("已发现 / 已预习 / 已首学分别记录；与旅游手册分开。",16)
	if study.state.records.is_empty():
		_text("还没有接触过的词。先去浏览词卡吧。",20)
	for id in study.state.records:
		var r: Dictionary = study.state.records[id]
		var w: Dictionary = study.content.words[id]
		var status := "已首学" if r.firstLearned else ("已预习" if r.introduced else "已发现")
		_chalk_button("%s  ·  %s  [%s]" % [w.stressDisplay,w.zhMeanings[0],status],func(): show_word(id))
	_chalk_button("← 返回",_return_from_auxiliary)
	_tutor("来源原句只记录实际传入并标为已核对的内容。")

func show_word(id: String) -> void:
	_clear("word")
	var word: Dictionary = study.content.words[id]
	var r: Dictionary = study.state.records[id]
	_text(word.stressDisplay,42)
	_text(" / ".join(word.zhMeanings),27)
	_text("发现：%s  ·  预习：%s  ·  首学：%s" % [_yes(r.discovered),_yes(r.introduced),_yes(r.firstLearned)],17)
	if not r.reviewState.is_empty():
		_text("下次复习："+Time.get_datetime_string_from_unix_time(int(r.reviewState.nextReviewAt)).replace("T"," ")+"（UTC）",17)
		_text("间隔 %d 天  ·  出错轮次 %d" % [r.reviewState.intervalDays,r.reviewState.lapseCount],16)
	if r.sourceOccurrences.is_empty():
		_text("尚无真实剧情例句。",18)
	for source in r.sourceOccurrences:
		_text(source.ruSentence+"\n"+source.zhTranslation+"\n来源："+source.sourceId,17)
	var play := _chalk_button("发音 · 未提供录音",func(): _play_word(id))
	play.disabled = not study.content.has_audio(id)
	if not play.disabled:
		play.text = "播放真实发音"
	_chalk_button("← 返回记事本",show_notebook_from_word)
	_tutor("见过和学过都保留，但不会标作永久掌握。")

func show_notebook_from_word() -> void:
	screen = "notebook"
	show_notebook()

func _yes(value: bool) -> String:
	return "是" if value else "否"

func show_settings() -> void:
	if screen != "settings":
		return_screen = screen
		if not study.pause():
			_text(study.error)
			return
	_clear("settings")
	_text("课堂设置",30)
	_chalk_button("老师立绘："+_yes(study.state.settings.teacher),func(): _toggle_teacher(); show_settings())
	_chalk_button("减少动态效果："+_yes(study.state.settings.reducedMotion),func(): study.set_setting("reducedMotion",not study.state.settings.reducedMotion); show_settings())
	_chalk_button("黑板色板："+("柔和" if study.state.settings.themeId.ends_with("muted") else "经典"),func():
		study.set_setting("themeId","classroom_blackboard_v1" if study.state.settings.themeId.ends_with("muted") else "classroom_blackboard_muted")
		show_settings())
	_text("发音音量（仅有真实音频时生效）",16)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = study.state.settings.voiceVolume
	volume.custom_minimum_size.y = 44
	volume.value_changed.connect(func(value): study.set_setting("voiceVolume",value))
	body.add_child(volume)
	_text("火车 / 幻灯机主题仅预留接口，本轮不提供。",16)
	_chalk_button("← 返回",_return_from_auxiliary)
	_tutor("设置不改变题目与学习规则。")

func _return_from_auxiliary() -> void:
	if return_screen in ["quiz","preview","waiting","summary","paused"]:
		_resume()
	else:
		show_home()

func _toggle_teacher() -> void:
	study.set_setting("teacher",not study.state.settings.teacher)
	_refresh_header()

func _play_audio() -> void:
	if screen != "quiz":
		return
	var q: Dictionary = study.state.session.activeQuestion
	if q.kind == "ZH_TO_RU" and not q.submitted:
		return
	_play_word(q.wordId)

func _play_word(id: String) -> void:
	if not study.content.has_audio(id):
		return
	audio.stream = load(study.content.words[id].audioRef)
	audio.volume_db = linear_to_db(float(study.state.settings.voiceVolume))
	audio.play()

func _leave() -> void:
	if (study.store != null and study.store.blocked) or study.pause():
		return_requested.emit()
		# Direct school scene is explicitly a developer shortcut without a map parent.
		if get_parent() == get_tree().root:
			get_tree().quit()
	else:
		_text(study.error)

func _exit_tree() -> void:
	if study != null:
		study.pause()
	if is_inside_tree() and not previous_window_title.is_empty():
		get_window().title = previous_window_title

func _notification(what: int) -> void:
	if study == null:
		return
	if what in [NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_GO_BACK_REQUEST]:
		study.pause()

func _redraw_screen() -> void:
	match screen:
		"home": show_home()
		"alphabet": show_alphabet()
		"preview","quiz","waiting","summary": show_session()
		"paused": show_paused()
		"settings": show_settings()
		"notebook": show_notebook()
