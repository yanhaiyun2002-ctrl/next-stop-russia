class_name CatHunt
extends RefCounted
## One room-local search loop. No level, pet progression or persistent state.
signal changed

const SPOTS := [
	{"id": &"under_bed", "furniture": &"bed", "offset": Vector3(0, 0, 0.65), "peek": true,
		"ru": "Кот под кроватью.", "zh": "猫在床下面。"},
	{"id": &"under_desk", "furniture": &"desk", "offset": Vector3(0, 0, 0.5), "peek": false,
		"ru": "Кот под столом.", "zh": "猫在桌子下面。"},
	{"id": &"by_wardrobe", "furniture": &"wardrobe", "offset": Vector3(-1.05, 0, -0.15), "peek": false,
		"ru": "Кот у шкафа.", "zh": "猫在衣柜旁。"}
]
var rng := RandomNumberGenerator.new()
var spot_index := -1
var found := false
var hint_requested := false
var feedback_kind: StringName = &"search"
var found_count := 0
var attempt_count := 0

func _init() -> void:
	rng.randomize()
	_choose()

func current_spot() -> Dictionary:
	return SPOTS[spot_index]

func anchor(furniture: Dictionary) -> Vector3:
	var spot := current_spot()
	var floor: Vector2 = furniture[spot.furniture].floor_position
	return Vector3(floor.x, 0, floor.y) + spot.offset

func find_cat() -> bool:
	if found:
		return false
	found = true
	found_count += 1
	feedback_kind = &"found"
	changed.emit()
	return true

func miss() -> bool:
	if found:
		return false
	attempt_count += 1
	feedback_kind = &"miss"
	changed.emit()
	return true

func show_hint() -> void:
	if not found:
		hint_requested = true
		feedback_kind = &"hint"
		changed.emit()

func next_search() -> bool:
	if not found:
		return false
	_choose()
	changed.emit()
	return true

func restart() -> void:
	spot_index = -1
	found_count = 0
	attempt_count = 0
	_choose()

func _choose() -> void:
	var candidates: Array[int] = []
	for i in range(SPOTS.size()):
		if i != spot_index:
			candidates.append(i)
	spot_index = candidates[rng.randi_range(0, candidates.size() - 1)]
	found = false
	hint_requested = false
	feedback_kind = &"search"

func prompt() -> String:
	var spot := current_spot()
	if found:
		return "Вот кот! 找到啦！\n%s\n%s" % [spot.ru, spot.zh]
	if hint_requested:
		return "%s\n%s\n留意家具旁露出的小猫。" % [spot.ru, spot.zh]
	if feedback_kind == &"miss":
		return "还没点到猫，慢慢找。\nГде кот? 猫在哪里？"
	return "Где кот?\n猫在哪里？\n左右拖动，点点露出的小猫。"
