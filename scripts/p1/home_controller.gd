class_name P1HomeController
extends Node
const WORLD_LABEL = preload("res://ui/p1_world_label.gd")
var room: BuildingRoom
var session: P1Session
var flow: Control
var encounter: P1CatEncounter
var labels: Dictionary = {}
var sidebar: BoxContainer
var organize_button: Button
var message_button: Button
var replay_button: Button
var help_button: Button
var show_chinese := false

func setup(home: BuildingRoom, player: P1Session, story_flow: Control) -> void:
	room = home
	session = player
	flow = story_flow
	room.p1_controller = self
	room.debug_button.hide()
	room.mode_label.text = "小屋 · 美术方向试用"
	room.mode_label.hide()
	room.hunt_action.hide()
	room.hunt_panel.show()
	room.hunt_prompt.custom_minimum_size.y = 38
	room.hunt_prompt.text = ""
	# Shared room canvas, with a genuinely separate life-activity sidebar.
	var index: int = room.room_view.get_index()
	room.remove_child(room.room_view)
	var area := HBoxContainer.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.add_child(area)
	room.move_child(area, index)
	room.room_view.custom_minimum_size = Vector2(0, 220)
	room.room_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(spacer)
	flow.app.add_child(room.room_view)
	flow.app.move_child(room.room_view,0)
	room.tree_exiting.connect(func():
		if is_instance_valid(room.room_view): room.room_view.queue_free())
	room.visibility_changed.connect(func():
		if is_instance_valid(room.room_view): room.room_view.visible = room.is_visible_in_tree())
	sidebar = HBoxContainer.new()
	sidebar.alignment = BoxContainer.ALIGNMENT_END
	room.add_child(sidebar)
	room.move_child(sidebar,area.get_index())
	organize_button = _side_button("整理", flow.show_organization)
	message_button = _side_button("消息", flow.show_message)
	replay_button = _side_button("再找", func(): encounter.begin_round())
	help_button = _side_button("释义", func():
		show_chinese = not show_chinese
		_refresh())
	var window_button: Button = room._make_button("窗")
	window_button.pressed.connect(func():
		room.room_view.set_browse_center(room.room_view.project_base(P1Content.object_anchor(room.world, "window")).x))
	room.selection_bar.add_child(window_button)
	room.selection_bar.move_child(window_button, 1)
	# Player-facing browse arrows; the historical furniture/test bar stays in DEV/P0.
	room.selection_bar.hide()
	var browse_bar := HBoxContainer.new()
	room.add_child(browse_bar)
	room.move_child(browse_bar,room.feedback.get_index())
	var left: Button = room._make_button("‹")
	left.custom_minimum_size.x = 64
	left.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.pressed.connect(room.room_view.pan.bind(-1.0))
	flow.style_button(left)
	browse_bar.add_child(left)
	var browse_hint := Label.new()
	browse_hint.text = "左右拖动 · 探索小屋"
	browse_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	browse_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browse_hint.add_theme_font_size_override("font_size",14)
	browse_bar.add_child(browse_hint)
	var right: Button = room._make_button("›")
	right.custom_minimum_size.x = 64
	right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.pressed.connect(room.room_view.pan.bind(1.0))
	flow.style_button(right)
	browse_bar.add_child(right)
	flow.style_button(room.back_button)
	for entry in P1Content.data().spots:
		var label = WORLD_LABEL.new()
		label.object_id = entry.roomObjectId
		label.view = room.room_view
		label.attempted.connect(func(id): encounter.attempt(id))
		labels[entry.roomObjectId] = label
		room.room_view.add_child(label)
	encounter = P1CatEncounter.new()
	add_child(encounter)
	encounter.phase_changed.connect(_refresh)
	encounter.pet_finished.connect(func():
		if session.state.cat.namePending:
			flow.show_naming()
		else:
			room.room_view.set_browse_center(encounter.explore_center))
	encounter.setup(room.world, room.room_view, session)
	if flow.app.runtime_mode.can_dev:
		room.mode_label.text = "DEV · 模块预览" if flow.app.preview_active else "DEV · 完整流程"
	room.room_view.framing_changed.connect(_position_labels)
	session.changed.connect(_refresh)
	_refresh()
	if session.state.cat.namePending:
		flow.show_naming.call_deferred()
	elif session.state.organization.tutorialCompleted and not session.state.story.cityUnlocked:
		flow.show_message.call_deferred()
	# One safe HUD wrapper; the existing room canvas covers the real viewport.
	var hud := VBoxContainer.new()
	hud.add_theme_constant_override("separation",8)
	for child in room.get_children():
		if child is Control and child != room.room_view:
			room.remove_child(child)
			hud.add_child(child)
	var margins := MarginContainer.new()
	margins.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left","right","top","bottom"]:
		margins.add_theme_constant_override("margin_"+side,12)
	room.add_child(margins)
	margins.add_child(hud)
	_passthrough_layout(room)
	GameUI.legible(room.hunt_prompt)
	GameUI.legible(room.feedback)
	for child in hud.get_children():
		if child is HBoxContainer:
			for label in child.get_children():
				if label is Label: GameUI.legible(label)
	room.resized.connect(_full_bleed_canvas)
	flow.app.resized.connect(_full_bleed_canvas)
	_full_bleed_canvas.call_deferred()

func _full_bleed_canvas() -> void:
	if is_instance_valid(room) and is_instance_valid(room.room_view):
		room.room_view.global_position = Vector2.ZERO
		room.room_view.size = flow.get_viewport_rect().size

func _passthrough_layout(node: Node) -> void:
	if node is Container:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_passthrough_layout(child)


func _side_button(text: String, callback: Callable) -> Button:
	var button: Button = room._make_button(text)
	button.custom_minimum_size.x = 64
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	flow.style_button(button)
	button.pressed.connect(callback)
	sidebar.add_child(button)
	return button

func selected(id: StringName) -> void:
	if id == &"cat":
		encounter.pet()
	elif encounter.phase == "guessing":
		room.feedback.text = "请点击家具旁的俄语名称标签。"

func _refresh() -> void:
	if encounter == null:
		return
	room.hunt_panel.show()
	room.hunt_prompt.text = encounter.prompt()
	organize_button.disabled = session.state.quests.q01_cat != "completed"
	message_button.disabled = not session.state.organization.tutorialCompleted
	replay_button.disabled = encounter.phase != "complete" or session.state.cat.namePending
	room.back_button.text = "← 城市" if session.state.story.cityUnlocked else "出门未解锁"
	if not session.last_error.is_empty():
		room.feedback.text = session.last_error
	elif not encounter.audio_status.is_empty():
		room.feedback.text = encounter.audio_status
	elif session.state.story.cityUnlocked:
		room.feedback.text = "首段已完成 · 可自由找猫、整理或出门。"
	elif session.state.quests.q01_cat == "completed":
		room.feedback.text = "以后就叫你「%s」！下一步：点击「整理」。" % session.state.cat.displayName
	else:
		room.feedback.text = "首次摸猫后会记录纪念，再确认猫咪名字。"
	for entry in P1Content.data().spots:
		var label: Control = labels[entry.roomObjectId]
		label.caption.text = entry.ru + ("\n" + entry.zh if not session.state.cat.firstPetCompleted or show_chinese else "")
		label.queue_redraw()
	_position_labels()

func _position_labels() -> void:
	for entry in P1Content.data().spots:
		var label: Control = labels[entry.roomObjectId]
		var anchor := P1Content.object_anchor(room.world, entry.roomObjectId) + P1Content.vector(entry.labelOffset)
		label.size = Vector2(92, 52)
		label.position = room.room_view.project(anchor) - label.size / 2
		label.visible = encounter != null and encounter.phase == "guessing" and Rect2(Vector2.ZERO, room.room_view.size).encloses(Rect2(label.position, label.size))
