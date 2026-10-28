class_name P1CatEncounter
extends Node
## Continuous room-coordinate motion; visual retention is recorded independently.
signal phase_changed
signal pet_finished
var world: DormitoryWorld
var view: DormitoryView
var session: P1Session
var phase := "idle"
var anchor := Vector3.ZERO
var spot: Dictionary = {}
var elapsed := 0.0
var start := Vector3.ZERO
var finish := Vector3.ZERO
var duration := 1.0
var waypoints: Array[Vector3] = []
var waypoint_index := 0
var explore_center := 640.0
var audio_status := ""
var last_attempt := ""
var pet_bob := 0.0

func setup(room_world: DormitoryWorld, room_view: DormitoryView, player: P1Session) -> void:
	world = room_world
	view = room_view
	session = player
	world.encounter = self
	world.set_hunt_paused(true)
	if session.state.cat.namePending:
		phase = "name_required"
		anchor = Vector3(0, 0, 0.4)
		world.changed.emit()
	else:
		begin_round(true)

func begin_round(resume := false, forced := "") -> bool:
	if session.state.cat.namePending or (not resume and phase != "complete"):
		return false
	var candidates: Array = P1Content.data().spots.filter(func(value): return value.spotId != session.state.cat.spotId)
	var chosen: String = forced
	if chosen.is_empty():
		chosen = session.state.cat.spotId if resume and not session.state.cat.spotId.is_empty() else candidates.pick_random().spotId
	if P1Content.spot(chosen).is_empty() or not session.choose_spot(chosen):
		return false
	spot = P1Content.spot(chosen)
	audio_status = ""
	last_attempt = ""
	explore_center = view.browse_center_x
	anchor = Vector3(0, 0, 0.4)
	elapsed = 0
	phase = "first_visible"
	view.set_browse_center(view.project_base(anchor).x)
	world.changed.emit()
	phase_changed.emit()
	return true

func hide_anchor() -> Vector3:
	return P1Content.object_anchor(world, spot.roomObjectId) + P1Content.vector(spot.hideOffset)

func _motion(next_phase: String, to: Vector3, seconds: float) -> void:
	phase = next_phase
	start = anchor
	finish = to
	elapsed = 0
	duration = seconds
	phase_changed.emit()

func _process(delta: float) -> void:
	if world == null or phase in ["idle", "guessing", "await_pet", "name_required", "complete"]:
		return
	elapsed += delta
	match phase:
		"first_visible":
			if elapsed >= 1.0:
				_motion("run_to_spot", hide_anchor(), 1.8)
		"run_to_spot", "peek_ears", "peek_face", "walk_out":
			var t := clampf(elapsed / duration, 0, 1)
			anchor = start.lerp(finish, smoothstep(0, 1, t))
			# Follow only continuous movement; exploration remains freely draggable.
			view.set_browse_center(view.project_base(anchor).x)
			world.changed.emit()
			if t >= 1:
				if phase == "run_to_spot":
					phase = "guessing"
					phase_changed.emit()
				elif phase == "peek_ears":
					_motion("peek_face", hide_anchor() + Vector3(0, 0.12, -0.4), 0.35)
				elif phase == "peek_face":
					waypoint_index = 0
					_motion("walk_out", waypoints[0], 0.7)
				else:
					waypoint_index += 1
					if waypoint_index < waypoints.size():
						_motion("walk_out", waypoints[waypoint_index], 0.9)
					else:
						phase = "await_pet"
						phase_changed.emit()
		"pet_reaction":
			pet_bob = sin(minf(elapsed, 0.9) / 0.9 * TAU) * 0.09
			world.changed.emit()
			if elapsed >= 0.9:
				pet_bob = 0
				if session.pet_reaction_completed():
					phase = "name_required" if session.state.cat.namePending else "complete"
					pet_finished.emit()
				else:
					phase = "await_pet"
				phase_changed.emit()

func attempt(id: String) -> bool:
	if phase != "guessing":
		return false
	last_attempt = id
	# No voice assets delivered: explicit, non-blocking text fallback per gesture.
	audio_status = "暂无俄语音频 · 文字回退："
	for entry in P1Content.data().spots:
		if entry.roomObjectId == id:
			audio_status += entry.ru + " · " + entry.zh
	if id != spot.roomObjectId:
		phase_changed.emit()
		return false
	waypoints.clear()
	var origin := P1Content.object_anchor(world, spot.roomObjectId)
	for offset in spot.exitWaypoints:
		waypoints.append(origin + P1Content.vector(offset))
	_motion("peek_ears", hide_anchor() + Vector3(0, 0.08, -0.16), 0.35)
	return true

func pet() -> bool:
	if phase != "await_pet":
		return false
	phase = "pet_reaction"
	elapsed = 0
	phase_changed.emit()
	return true

func parts() -> Array[Dictionary]:
	if phase == "idle":
		return []
	if P1Art.texture("cat") != null:
		return P1CatVisual.parts(anchor + Vector3(0,pet_bob,0),not spot.is_empty() and spot.peek and phase == "guessing")
	return GrayboxCat.parts(anchor + Vector3(0, pet_bob, 0), not spot.is_empty() and spot.peek and phase == "guessing")

func prompt() -> String:
	match phase:
		"first_visible", "run_to_spot": return "咦，有只猫！看看它跑向哪里。"
		"guessing": return "Где кот? 猫在哪里？\n左右拖动，点击藏处旁的俄语家具标签。"
		"peek_ears", "peek_face", "walk_out": return "Вот кот! 找到啦！它正在走出来……"
		"await_pet": return "猫咪走近了，点一下画面中的猫，摸摸它。"
		"pet_reaction": return "Мур-мур… 呼噜呼噜……"
		"name_required": return "首遇纪念已记录。给猫咪起个名字吧。"
		"complete": return "还可以再找一次，或从右侧进入整理。"
	return ""
