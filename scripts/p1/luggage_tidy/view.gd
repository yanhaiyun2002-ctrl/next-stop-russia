extends Control
## One runtime view shared by Q02 and isolated DEV replay.
signal closed
signal continued
var player: P1Session
var continue_button: Button
var restored_host := false
const MODEL = preload("res://scripts/p1/luggage_tidy/model.gd")
const INK := Color("4b463b")
const VOCAB := {"passport":"паспорт · 护照","textbook":"учебник · 教材","scarf":"шарф · 围巾","washbag":"洗漱包"}
var model = MODEL.new()
var host: Control
var prior_process_mode: int
var prior_focus: WeakRef
var selected := ""
var held := ""
var dragging := false
var offset := Vector2.ZERO
var press_point := Vector2.ZERO
var pointer := Vector2.ZERO
var proposed: Dictionary = {}
var geometry: Array = []
var guides: Array = []
var snapped := false
var layer_order: Array = ["textbook","passport","washbag","scarf"]
var origin := Vector2.ZERO
var scale_factor := 1.0
var done := false
var settling := 0.0
var glow := 0.0
var invalid_flash := 0.0
var last_drop := ""
var drop_age := 1.0
var hint_level := 0
var vocab_age := 0.0
var title: Label
var intro: Label
var info: Label
var vocab: Label
var status: Label
var hint_button: Button
var actions: HBoxContainer
var action_buttons: Dictionary = {}
var sound: AudioStreamPlayer

func setup(app: Control, session: P1Session = null) -> void:
	player = session
	if player != null:
		model = player.luggage_model()
		info.text = "摆放自动保存 · 可以随时回房间。"
	host = app
	prior_process_mode = app.process_mode
	var focused := get_viewport().gui_get_focus_owner()
	prior_focus = weakref(focused) if focused != null else null
	app.process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	title = _label("初到俄罗斯\n整理行李",25)
	intro = _label("把摊开的行李收拾一下吧。",17)
	info = _label("把四件行李整理成舒服的样子。",13)
	vocab = _label("",15)
	status = _label("拿起一件物品试试看。",16)
	hint_button = _button("线索",_hint)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation",7)
	add_child(actions)
	for pair in [["转向",_rotate],["撤销",_undo],["重来",_restart],["退出",_close]]:
		var button := _button(pair[0],pair[1])
		remove_child(button)
		actions.add_child(button)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_buttons[pair[0]] = button
	continue_button = _button("整理好了 · 继续",_continue)
	continue_button.visible = false
	sound = AudioStreamPlayer.new()
	add_child(sound)
	resized.connect(_layout)
	_layout()

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",INK)
	add_child(label)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(60,48)
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",INK)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e5cda8")
	style.border_color = Color("9b7a50")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	for state in ["normal","hover","pressed","focus"]:
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(callback)
	add_child(button)
	return button

func _layout() -> void:
	_cancel()
	if not is_instance_valid(title):
		return
	var portrait := size.y > size.x
	title.position = Vector2(20,16)
	title.size = Vector2(size.x-110 if portrait else 230,66)
	intro.position = Vector2(20,86 if portrait else 100)
	intro.size = Vector2(size.x-40 if portrait else 230,50)
	hint_button.position = Vector2(size.x-80,20) if portrait else Vector2(20,165)
	hint_button.size = Vector2(60,48)
	info.position = Vector2(20,size.y-205 if portrait else 245)
	info.size = Vector2(size.x-40 if portrait else 230,60)
	vocab.position = Vector2(20,size.y-140 if portrait else 330)
	vocab.size = Vector2(size.x-40 if portrait else 230,28)
	status.position = Vector2(20,size.y-110 if portrait else 375)
	status.size = Vector2(size.x-40 if portrait else 230,44)
	actions.position = Vector2(16,size.y-60)
	actions.size = Vector2(size.x-32,48)
	continue_button.position = Vector2(20,size.y-205 if portrait else 445)
	continue_button.size = Vector2(size.x-40 if portrait else 230,50)
	var area := Rect2(16,138,size.x-32,maxf(220,size.y-362)) if portrait else Rect2(285,20,maxf(260,size.x-305),maxf(300,size.y-100))
	scale_factor = minf(area.size.x/600,area.size.y/600)
	origin = area.position+(area.size-Vector2(600,600)*scale_factor)/2
	queue_redraw()

func _signature() -> Array:
	return [size,get_global_transform_with_canvas(),get_viewport_rect(),get_window().size]

func world_to_screen(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas()*(origin+point*scale_factor)

func _world(point: Vector2) -> Vector2:
	return (point-origin)/scale_factor

func _pick(point: Vector2) -> String:
	var order := layer_order.duplicate()
	order.reverse()
	for id in order:
		if model.footprint(id).has_point(point):
			return id
	for id in order:
		var rect: Rect2 = model.footprint(id)
		var margin := maxf(0,(48/scale_factor-minf(rect.size.x,rect.size.y))/2)
		if rect.grow(margin).has_point(point):
			return id
	return ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected = _pick(_world(event.position))
		if not selected.is_empty():
			held = selected
			proposed = model.poses[held].duplicate(true)
			offset = proposed.position-_world(event.position)
			press_point = event.position
			pointer = event.position
			geometry = _signature()
			layer_order.erase(selected)
			layer_order.append(selected)
			vocab.text = VOCAB[selected]
			vocab_age = 0
			vocab.modulate.a = 1
		accept_event()
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_rotate()
			get_viewport().set_input_as_handled()
	if held.is_empty():
		return
	if geometry != _signature():
		_cancel()
		status.text = "画面变化，物品留在原处。"
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pointer = get_global_transform_with_canvas().affine_inverse()*event.position
		dragging = dragging or pointer.distance_to(press_point) >= 4
		var raw := proposed.duplicate(true)
		raw.position = _world(pointer)+offset
		var result: Dictionary = model.snap(held,raw,clampf(12/scale_factor,12,26))
		proposed = result.pose
		guides = result.guides
		snapped = result.snapped
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if dragging:
			if model.place(held,proposed):
				status.text = "边缘对齐了。" if snapped else "轻轻放好了，还可以再调整。"
				_persist()
				last_drop = held
				drop_age = 0
				_tone(false)
			else:
				status.text = "超出布垫了，先放回原处。"
				invalid_flash = 0.3
			_refresh_completion()
		_cancel()
		get_viewport().set_input_as_handled()

func _cancel() -> void:
	held = ""
	dragging = false
	guides.clear()
	snapped = false
	queue_redraw()

func _rotate() -> void:
	if selected.is_empty():
		status.text = "轻点一件行李，再转个方向。"
		return
	if not held.is_empty() and dragging:
		proposed.turn = 1-int(proposed.turn)
		offset = Vector2(-offset.y,offset.x)
		proposed.position = _world(pointer)+offset
		guides.clear()
	else:
		_cancel()
		var pose: Dictionary = model.poses[selected].duplicate(true)
		pose.turn = 1-int(pose.turn)
		if model.place(selected,pose):
			status.text = "转好了。"
			_persist()
			_tone(false)
		else:
			status.text = "靠桌边太近，先挪开一点。"
			invalid_flash = 0.3
		_refresh_completion()
	queue_redraw()

func _undo() -> void:
	_cancel()
	if model.undo():
		status.text = "回到刚才的摆法。"
		_persist()
		_refresh_completion()

func _restart() -> void:
	_cancel()
	model.restart()
	continue_button.visible = false
	selected = ""
	done = false
	settling = 0
	glow = 0
	vocab.text = ""
	status.text = "还是这四件行李，慢慢来。"
	_persist()
	queue_redraw()

func _hint() -> void:
	var clues := ["看看物件的长短，能不能发现一个顺序？","转个方向，把它们的一条边排齐试试。"]
	info.text = clues[mini(hint_level,1)]
	hint_level = mini(hint_level+1,1)

func _refresh_completion() -> void:
	settling = 0
	if not model.result().complete:
		done = false
		continue_button.visible = false
	queue_redraw()

func _process(delta: float) -> void:
	if held.is_empty():
		vocab_age += delta
		vocab.modulate.a = clampf(1.5-vocab_age,0,1)
	if not held.is_empty() and geometry != _signature():
		_cancel()
		status.text = "画面变化，物品留在原处。"
	if held.is_empty() and model.result().complete:
		settling += delta
		if settling >= 0.3 and not done:
			done = true
			glow = 1
			status.text = "收好了。看看你的摆法，再继续旅程。"
			continue_button.visible = player != null
			_tone(true)
	else:
		settling = 0
	glow = maxf(0,glow-delta*1.5)
	invalid_flash = maxf(0,invalid_flash-delta)
	drop_age += delta
	if glow > 0 or invalid_flash > 0 or drop_age < 0.2:
		queue_redraw()

func _tone(complete: bool) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count := int((0.26 if complete else 0.06)*22050)
	var data := PackedByteArray()
	data.resize(count*2)
	for i in range(count):
		var t := float(i)/22050
		var wave := sin(TAU*(784 if complete else 480)*t)
		if complete:
			wave = (wave+sin(TAU*988*t)+sin(TAU*1175*t))/3
		data.encode_s16(i*2,int(wave*sin(PI*float(i)/count)*exp(-t*8)*1500))
	stream.data = data
	sound.stream = stream
	sound.play()

func _persist() -> void:
	if player != null and not player.save_luggage(model.snapshot()):
		model = player.luggage_model()
		status.text = player.last_error

func _continue() -> void:
	if player == null or not done or not model.result().complete:
		return
	if not player.complete_organization():
		status.text = player.last_error
		return
	_restore_host()
	continued.emit()
	queue_free()

func _restore_host() -> void:
	if restored_host:
		return
	restored_host = true
	if is_instance_valid(host):
		host.process_mode = prior_process_mode
	if prior_focus != null and is_instance_valid(prior_focus.get_ref()):
		prior_focus.get_ref().grab_focus()

func _close() -> void:
	_cancel()
	_restore_host()
	closed.emit()
	queue_free()

func _exit_tree() -> void:
	_restore_host()

func _round(rect: Rect2, color: Color, border: Color = Color(0,0,0,0), radius := 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0 else 0)
	style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("efe5d3"))
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	# One travel cloth, no container IDs, slots, capacity counters or answer outlines.
	_round(Rect2(0,0,600,600),Color("a3846a"),Color("82654d"),20)
	_round(Rect2(12,12,576,576),Color("d8c8a7").lerp(Color("f4dfaa"),glow*0.25),Color("bead89"),13)
	for y in range(25,580,11):
		draw_line(Vector2(22,y),Vector2(578,y),Color(0.47,0.37,0.23,0.045),1)
	for x in range(25,580,13):
		draw_line(Vector2(x,22),Vector2(x,578),Color(0.47,0.37,0.23,0.035),1)
	for id in layer_order:
		_draw_item(id,proposed if held == id and dragging else model.poses[id],held == id and dragging)
	for guide in guides:
		var a := Vector2.ZERO
		var b := Vector2.ZERO
		a[guide.axis] = guide.from
		b[guide.axis] = guide.to
		a[1-guide.axis] = guide.edge
		b[1-guide.axis] = guide.edge
		draw_dashed_line(a,b,Color("fff3ac"),2,7)
	if done:
		_round(Rect2(12,12,576,576),Color(0,0,0,0),Color(0.93,0.75,0.35,0.4+glow*0.5),13)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_item(id: String, pose: Dictionary, lifted: bool) -> void:
	var lift := -5/scale_factor if lifted else 0.0
	if id == last_drop and drop_age < 0.16:
		lift += sin(drop_age/0.16*PI)*2/scale_factor
	draw_set_transform(origin+pose.position*scale_factor+Vector2(0,lift*scale_factor),pose.turn*PI/2,Vector2.ONE*scale_factor)
	var extent: Vector2 = MODEL.SIZES[id]
	var box := Rect2(-extent/2,extent)
	_round(Rect2(box.position+Vector2(5,8 if lifted else 4),box.size),Color(0.22,0.15,0.09,0.22 if lifted else 0.14),Color(0,0,0,0),10)
	match id:
		"passport":
			_round(box,Color("813f43"),INK,5)
			_round(box.grow(-6),Color(0,0,0,0),Color("bf8e62"),3)
			draw_arc(Vector2(0,-10),16,0,TAU,32,Color("d2ac6a"),2,true)
			draw_arc(Vector2(0,-10),9,-PI/2,PI/2,24,Color("d2ac6a"),1,true)
			draw_line(Vector2(-16,-10),Vector2(16,-10),Color("d2ac6a"),1)
			draw_line(Vector2(-19,30),Vector2(19,30),Color("c59c67"),2)
		"textbook":
			_round(box,Color("577c98"),INK,6)
			_round(Rect2(box.position+Vector2(12,6),extent-Vector2(17,16)),Color("7498ae"),Color(0,0,0,0),4)
			draw_line(box.position+Vector2(13,4),box.position+Vector2(13,extent.y-5),Color("3a596e"),3)
			draw_line(Vector2(box.position.x+19,box.end.y-8),box.end-Vector2(5,8),Color("eee1bd"),5)
			_round(Rect2(-36,-60,72,45),Color("d7cbae"),Color(0,0,0,0),2)
		"scarf":
			_round(box,Color("b86f4c"),Color("88513e"),5)
			for y in range(-130,134,34):
				draw_rect(Rect2(-44,y,88,11),Color("d7ae72"))
			for x in range(-36,40,16):
				draw_line(Vector2(x,-134),Vector2(x,128),Color(0.43,0.23,0.18,0.25),3)
			for x in range(-38,40,10):
				draw_line(Vector2(x,125),Vector2(x+2,139),Color("915a42"),3)
		"washbag":
			_round(box,Color("5d8d87"),INK,22)
			_round(box.grow(-10),Color("79a29a"),Color("47746e"),17)
			draw_line(Vector2(26,-76),Vector2(26,70),Color("d9c397"),4)
			for y in range(-70,66,9):
				draw_line(Vector2(23,y),Vector2(29,y),Color("8c7b5a"),2)
			draw_arc(Vector2(25,-68),8,-PI,PI,20,Color("d9c397"),3,true)
	if selected == id:
		var color := Color("cc6d58") if invalid_flash > 0 else Color("dfb459")
		if lifted and not MODEL.AREA.encloses(model.footprint(id,pose)):
			color = Color("cc6d58")
		_round(box.grow(4),Color(0,0,0,0),color,12)
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
