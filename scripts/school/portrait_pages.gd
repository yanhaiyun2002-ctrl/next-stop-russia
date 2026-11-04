extends RefCounted
## Mobile composition only. The existing service remains the learning authority.
const ROOT := "res://assets/school/portrait/"
const THEME = preload("res://scripts/school/theme_presenter.gd")

static func _place(node: Control, rect: Rect2) -> void:
	node.set_meta("portrait_rect",rect)

static func _label(parent: Node, text: String, rect: Rect2, font := 18, color := Color("583820")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("portrait_font",font)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	_place(label,rect)
	return label

static func _image(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(path) if ResourceLoader.exists(path) else null
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	_place(picture,rect)
	return picture

static func _skin(button: Button, kind: String) -> void:
	for state in ["normal","hover","pressed","focus","disabled"]:
		button.add_theme_stylebox_override(state,THEME.decorated_style(kind))
	if kind.ends_with("green"):
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			button.add_theme_color_override(key,Color("fff0b5"))

static func _icon(parent: Node, mode: String, rect: Rect2) -> void:
	var picture := _image(parent,ROOT+"mode_icons.png",rect)
	if picture.texture != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = picture.texture
		var index: int = {"new":0,"review":1,"notebook":2}[mode]
		var cell: float = picture.texture.get_width()/3.0
		atlas.region = Rect2(cell*index,0,cell,picture.texture.get_height())
		picture.texture = atlas

static func preparation(view) -> void:
	var root: Control = view.pages.STUDY_PREPARATION.portrait
	view.mode_buttons.clear()
	view.count_buttons.clear()
	_label(root,"学校学习",Rect2(.24,.166,.52,.046),31)
	_label(root,"俄语词汇 · 准备学习",Rect2(.22,.214,.56,.024),14)
	var captions := [["new","学习新词","学习今天的新词汇"],["review","复习旧词","巩固已学的词汇"],["notebook","查看词本","浏览学习记录与词义"]]
	for index in captions.size():
		var item: Array = captions[index]
		var mode: String = item[0]
		var selected: bool = view.selected_mode == mode
		var rect := Rect2(.17,.247+index*.089,.66,.079)
		if selected:
			var glow := Panel.new()
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var glow_style := GameUI.flat(Color(0,0,0,0),18)
			glow_style.border_color = Color("e2ed75")
			glow_style.set_border_width_all(2)
			glow_style.shadow_color = Color(.62,.86,.13,.65)
			glow_style.shadow_size = 7
			glow.add_theme_stylebox_override("panel",glow_style)
			root.add_child(glow)
			_place(glow,rect.grow(.002))
		var button: Button = view._button(root,"",func(): view._select_mode(mode))
		button.name = "Mode_"+mode
		button.set_meta("caption",item[1])
		button.tooltip_text = item[1]
		button.custom_minimum_size.y = 44
		_skin(button,"portrait_card_green" if selected else "portrait_card_paper")
		_place(button,rect)
		_icon(button,mode,Rect2(.045,.08,.26,.82))
		_label(button,item[1],Rect2(.33,.08,.51,.43),23,Color("fff0bd") if selected else Color("57371e"))
		_label(button,item[2],Rect2(.33,.52,.51,.27),12,Color("f8e5b4") if selected else Color("7b4e2c"))
		_label(button,"›",Rect2(.86,.25,.10,.46),30,Color("f7df99") if selected else Color("a26a35"))
		if selected:
			var tick := _label(button,"✓",Rect2(.895,-.14,.115,.52),23,Color("fffbdc"))
			var tick_style := GameUI.flat(Color("5c8d22"),24)
			tick_style.set_content_margin_all(0)
			tick.add_theme_stylebox_override("normal",tick_style)
		view.mode_buttons[mode] = button
	var mode: String = view._effective_mode()
	var eligible: int = view.study.available(view.deck_id,mode).size()
	view.requested_count = clampi(view.requested_count,1,maxi(1,eligible))
	_label(root,"今日新词数量" if mode == "new" else "本次复习数量",Rect2(.22,.520,.56,.030),20)
	var choices: Array = []
	for count in [1,mini(5,eligible),eligible]:
		if count > 0 and count not in choices: choices.append(count)
	choices.sort()
	for i in choices.size():
		var count: int = choices[i]
		var selected: bool = count == view.requested_count
		var width := .66/choices.size()
		var button: Button = view._button(root,str(count),func(): view._choose_count(count))
		button.name = "Count_"+str(count)
		button.custom_minimum_size = Vector2(0,40)
		button.set_meta("portrait_font",24)
		_skin(button,"portrait_count_green" if selected else "portrait_pill")
		_place(button,Rect2(.17+i*width,.557,width-.018,.049))
		view.count_buttons[count] = button
	if eligible == 0:
		_label(root,"当前词包没有可学新词" if mode == "new" else "暂无已学词可复习",Rect2(.17,.56,.66,.046),16,Color("923d25"))
	var plan := Panel.new()
	plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := GameUI.flat(Color(.99,.9,.71,.55),12)
	style.border_color = Color("c79b62")
	plan.add_theme_stylebox_override("panel",style)
	root.add_child(plan)
	_place(plan,Rect2(.16,.625,.68,.072))
	_icon(plan,"new",Rect2(.035,.05,.25,.90))
	_label(plan,"主题：学校词汇\n本次：%d 个%s" % [view.requested_count if eligible else 0,"新词" if mode == "new" else "复习词"],Rect2(.30,.08,.45,.84),15)
	if view.selected_mode == "review" and mode == "free_review":
		_label(root,"自由复习 · 已学词尚未到期",Rect2(.47,.704,.35,.026),11)
	if eligible > 0:
		var other := OptionButton.new()
		other.name = "OtherQuantity"
		other.custom_minimum_size.y = 30
		for count in range(1,eligible+1):
			other.add_item("自选 %d 词" % count)
			if count == view.requested_count: other.select(count-1)
		other.item_selected.connect(func(i): view._choose_count(i+1))
		root.add_child(other)
		_place(other,Rect2(.19,.702,.29,.031))
		other.set_meta("portrait_font",12)
	var pending: bool = not view.study.state.session.is_empty() and view.study.state.session.status != "completed"
	view.start_button = view._button(root,"继续学习 ▶" if pending else "开始学习 ▶",view._prepare_start)
	view.start_button.name = "StartStudy"
	view.start_button.custom_minimum_size.y = 44
	view.start_button.set_meta("portrait_font",24)
	_skin(view.start_button,"primary_green")
	_place(view.start_button,Rect2(.235,.823,.44,.054))
	var alphabet: Button = view._button(root,"字母入门 · %d/33" % view._alphabet_count(),view.interact)
	alphabet.name = "AlphabetEntry"
	alphabet.custom_minimum_size.y = 28
	alphabet.set_meta("portrait_font",11)
	_place(alphabet,Rect2(.18,.885,.33,.031))
	view.action_button = alphabet
	view._tutor(view.notice if not view.notice.is_empty() else ("上次学习已保存，点击继续。" if pending else "今天准备学习\n多少个新词？"))
	view.feedback.text = "独立竖屏学习准备页"

static func quiz(view) -> void:
	var root: Control = view.pages.QUIZ_BLACKBOARD.portrait
	var q: Dictionary = view.study.state.session.activeQuestion
	view.presenter.on_question_shown(q)
	var title: String = {"ZH_TO_RU":"中文选俄语","RU_TO_ZH":"俄语选中文","AUDIO_TO_RU":"听音选俄语"}[q.kind]
	var banner := _label(root,title,Rect2(.24,.205,.51,.044),24,Color("f6efd4"))
	banner.add_theme_stylebox_override("normal",THEME.decorated_style("portrait_type_banner"))
	if q.kind == "AUDIO_TO_RU":
		var play: Button = view._button(root,"▶ 听发音，选俄语",view._play_audio)
		_place(play,Rect2(.27,.279,.40,.055))
	else:
		if q.prompt.length() <= 12:
			_label(root,q.prompt,Rect2(.25,.278,.43,.055),38,Color("fff0c5"))
		else:
			var scroll := ScrollContainer.new()
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			root.add_child(scroll)
			_place(scroll,Rect2(.21,.268,.48,.071))
			var prompt := _label(scroll,q.prompt,Rect2(),17,Color("fff0c5"))
			prompt.remove_meta("portrait_rect")
			prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_label(root,"↕ 滑动查看完整题目",Rect2(.25,.338,.43,.020),10,Color("f5e8b0"))
	_image(root,ROOT+"chalk_underline.svg",Rect2(.26,.335,.40,.011))
	var grid := GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation",9)
	root.add_child(grid)
	_place(grid,Rect2(.19,.370,.51,.255))
	for index in q.options.size():
		var option: Dictionary = q.options[index]
		var answer: String = option.id
		var mark := "idle"
		var prefix := String.chr(65+index)+".   "
		if q.submitted:
			if answer == q.wordId: mark = "correct"; prefix = "✓ "+prefix
			elif answer == q.result.selectedId: mark = "wrong"; prefix = "× "+prefix
			else: mark = "disabled"
		var button: Button = view._button(grid,prefix+option.text,func(): view._answer(q.id,answer))
		button.name = "Answer_"+str(index)
		button.custom_minimum_size.y = 44
		button.set_meta("portrait_font",13 if option.text.length() > 18 else 23)
		button.tooltip_text = option.text
		var russian := SystemFont.new()
		russian.font_names = PackedStringArray(["Times New Roman"])
		button.add_theme_font_override("font",russian)
		button.disabled = q.submitted
		view._style_answer(button,mark)
		if mark == "correct":
			var halo := Panel.new()
			halo.show_behind_parent = true
			halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var light := GameUI.flat(Color(0,0,0,0),15)
			light.border_color = Color("ffe99a")
			light.set_border_width_all(2)
			light.shadow_color = Color(.91,.83,.26,.65)
			light.shadow_size = 6
			halo.add_theme_stylebox_override("panel",light)
			button.add_child(halo)
			halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style: StyleBox = button.get_theme_stylebox(state).duplicate()
			style.content_margin_top = 5
			style.content_margin_bottom = 5
			button.add_theme_stylebox_override(state,style)
		view.option_buttons.append(button)
	if q.submitted:
		view.presenter.on_answer_evaluated(q.result)
		var message: String = view._result_text(q.result)
		if not q.result.correct or q.result.assisted:
			var word: Dictionary = view.study.content.words[q.wordId]
			message += "\n正确答案："+word.stressDisplay+" · "+word.zhMeanings[0]
		var result := _label(root,message,Rect2(.12,.742,.51,.065),13,Color("59331e"))
		result.add_theme_stylebox_override("normal",THEME.decorated_style("pill_cream"))
		view.next_button = view._button(root,"查看结算 →" if view.study.state.session.status == "completed" else "继续 →",func():
			if view.study.next_question(): view.show_session()
			else: view.notice = view.study.error; view._tutor(view.notice))
		view.next_button.name = "ContinueQuestion"
		view.next_button.custom_minimum_size.y = 40
		view.next_button.set_meta("portrait_font",18)
		_place(view.next_button,Rect2(.18,.817,.42,.047))
		view._tutor("答对啦！\n继续下一题。" if q.result.correct and not q.result.assisted else "再看看答案，\n之后再复习。",view.presenter.tutor_pose)
	else:
		if q.assisted:
			_label(root,"已查看提示，本题不计入独立通过。",Rect2(.12,.74,.52,.045),12,Color("f4e9bf"))
		view._tutor("再想一想，\n选哪个答案？","hint" if q.assisted else "idle")
	view._refresh_header()

static func layout(view) -> void:
	var root: Control = view.pages[view.page_id].portrait
	_walk(root,view.canvas.size.x/439.0)

static func _walk(parent: Control, scale: float) -> void:
	for child in parent.get_children():
		if not child is Control: continue
		if child.has_meta("portrait_rect"):
			var rect: Rect2 = child.get_meta("portrait_rect")
			child.position = rect.position*parent.size
			child.size = rect.size*parent.size
		if child.has_meta("portrait_font"):
			child.add_theme_font_size_override("font_size",maxi(10,roundi(float(child.get_meta("portrait_font"))*clampf(scale,.8,1.15))))
		_walk(child,scale)
