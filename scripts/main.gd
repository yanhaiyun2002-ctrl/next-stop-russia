extends Control
## A small P0 navigator: ID validation, transition guard, and independent rooms.
signal navigation_rejected(code: StringName)
signal room_entered(id: StringName)
signal map_returned

const MAP_SCENE = preload("res://scenes/map.tscn")
const CATALOG: Array[BuildingDefinition] = [
	preload("res://data/buildings/dormitory.tres"),
	preload("res://data/buildings/school.tres"),
	preload("res://data/buildings/shop.tres"),
]

@onready var safe_layout: MarginContainer = $SafeLayout
var map_view: VBoxContainer
var active_room: BuildingRoom
var active_id: StringName = &""
var buildings: Dictionary = {}
var transitioning := false
var last_rejection: StringName = &""
var technical_mode := false
var session: P1Session
var story_flow: Control

func _ready() -> void:
	get_tree().auto_accept_quit = true
	get_tree().quit_on_go_back = false
	for building in CATALOG:
		buildings[building.id] = building
	map_view = MAP_SCENE.instantiate()
	safe_layout.add_child(map_view)
	map_view.configure(CATALOG)
	map_view.building_requested.connect(enter_building)
	if not technical_mode:
		var channel := "DEV" if "--dev" in OS.get_cmdline_user_args() else "PLAYTEST"
		session = P1Session.new(channel)
		if channel == "DEV" and "--name-pending" in OS.get_cmdline_user_args() and not session.store.blocked and not session.state.cat.firstPetCompleted:
			while session.state.story.arrivalIndex < 5:
				if not session.advance_arrival():
					break
			if session.enter_home() and session.choose_spot("by_window"):
				session.pet_reaction_completed()
		map_view.hide()
		story_flow = load("res://scripts/p1/flow.gd").new()
		add_child(story_flow)
		story_flow.setup(self, session)
		if OS.has_feature("p1_playtest") and "--verify-p1-package" in OS.get_cmdline_user_args():
			var verifier: Node = load("res://scripts/p1/package_check.gd").new()
			verifier.app = self
			add_child(verifier)
		if channel == "DEV" and "--technical-map" in OS.get_cmdline_user_args():
			technical_mode = true
			story_flow._clear()
			map_view.show()

func enter_building(id: StringName) -> bool:
	if transitioning or is_instance_valid(active_room):
		return _reject(&"busy", "正在切换场景，请稍候。")
	if not buildings.has(id):
		return _reject(&"invalid_id", "无法进入：未知建筑 ID。")
	var building: BuildingDefinition = buildings[id]
	if not technical_mode and session != null:
		if (id == &"dormitory" and not session.state.story.homeEntered) or (id != &"dormitory" and not session.state.story.cityUnlocked):
			return _reject(&"story_locked", "先完成宿舍里的相识、整理与安娜消息。")
	if not building.is_open:
		return _reject(&"locked", "%s暂未开放。" % building.display_name)
	if building.destination.is_empty() or not ResourceLoader.exists(building.destination, "PackedScene"):
		return _reject(&"missing_scene", "无法进入：目的场景缺失，请检查建筑配置。")
	var packed := load(building.destination) as PackedScene
	if packed == null:
		return _reject(&"invalid_scene", "无法进入：目的场景无效。")
	var room := packed.instantiate()
	if not room is BuildingRoom:
		room.free()
		return _reject(&"invalid_scene", "无法进入：场景缺少返回地图接口。")
	transitioning = true
	last_rejection = &""
	map_view.selected_id = id
	_enter_room.call_deferred(room, id)
	return true

func _enter_room(room: BuildingRoom, id: StringName) -> void:
	active_room = room
	active_id = id
	map_view.hide()
	safe_layout.add_child(room)
	if not technical_mode and id == &"dormitory":
		var controller := P1HomeController.new()
		room.add_child(controller)
		controller.setup(room, session, story_flow)
	room.return_requested.connect(return_to_map)
	await get_tree().process_frame
	room.back_button.grab_focus()
	transitioning = false
	room_entered.emit(id)

func return_to_map() -> bool:
	if not technical_mode and story_flow != null and story_flow.block_return():
		return false
	if transitioning or not is_instance_valid(active_room):
		return false
	transitioning = true
	_restore_map.call_deferred()
	return true

func _restore_map() -> void:
	active_room.hide()
	active_room.queue_free()
	active_room = null
	active_id = &""
	map_view.show()
	map_view.show_feedback("已返回地图，保留上次建筑位置与选择。")
	map_view.restore_focus()
	await get_tree().process_frame
	transitioning = false
	map_returned.emit()

func _reject(code: StringName, message: String) -> bool:
	last_rejection = code
	map_view.show_feedback(message)
	navigation_rejected.emit(code)
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(active_room):
		return_to_map()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(active_room):
		return_to_map()
