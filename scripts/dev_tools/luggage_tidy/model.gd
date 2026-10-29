extends RefCounted
## Pure-memory geometry experiment. No game session, rewards or file access.
const AREA := Rect2(20,20,560,560)
const IDS := ["passport","washbag","textbook","scarf"]
const SIZES := {"passport":Vector2(90,135),"washbag":Vector2(125,190),"textbook":Vector2(150,220),"scarf":Vector2(95,280)}
var poses: Dictionary = {}
var history: Array[Dictionary] = []

func _init() -> void:
	restart()

func restart() -> void:
	poses = {"passport":{"position":Vector2(286,100),"turn":0},"textbook":{"position":Vector2(120,140),"turn":0},"washbag":{"position":Vector2(425,235),"turn":1},"scarf":{"position":Vector2(385,345),"turn":1}}
	history.clear()

func footprint(id: String, pose: Dictionary = {}) -> Rect2:
	var value: Dictionary = poses[id] if pose.is_empty() else pose
	var extent: Vector2 = SIZES[id]
	if value.turn % 2:
		extent = Vector2(extent.y,extent.x)
	return Rect2(value.position-extent/2,extent)

func place(id: String, pose: Dictionary) -> bool:
	if not poses.has(id) or not pose.position.is_finite() or not AREA.encloses(footprint(id,pose)):
		return false
	if poses[id] == pose:
		return true
	history.append(poses.duplicate(true))
	if history.size() > 40:
		history.pop_front()
	poses[id] = pose.duplicate(true)
	return true

func undo() -> bool:
	if history.is_empty():
		return false
	poses = history.pop_back()
	return true

func result() -> Dictionary:
	var axis: int = poses[IDS[0]].turn % 2
	var order := IDS.duplicate()
	order.sort_custom(func(a,b): return poses[a].position[axis] < poses[b].position[axis])
	var within := true
	var orientation := true
	var spaced := true
	var ascending := true
	var descending := true
	var low := INF
	var high := -INF
	var low_end := INF
	var high_end := -INF
	for index in range(order.size()):
		var id: String = order[index]
		var rect := footprint(id)
		within = within and AREA.encloses(rect)
		orientation = orientation and poses[id].turn % 2 == axis
		var edge: float = rect.position[1-axis]
		var end_edge: float = rect.end[1-axis]
		low = minf(low,edge)
		high = maxf(high,edge)
		low_end = minf(low_end,end_edge)
		high_end = maxf(high_end,end_edge)
		if index > 0:
			var prior: String = order[index-1]
			var gap: float = rect.position[axis]-footprint(prior).end[axis]
			spaced = spaced and gap >= 8 and gap <= 28
			ascending = ascending and SIZES[prior].y < SIZES[id].y
			descending = descending and SIZES[prior].y > SIZES[id].y
	var aligned := high-low <= 12 or high_end-low_end <= 12
	var ordered := ascending or descending
	return {"complete":within and orientation and spaced and ordered and aligned,"within":within,"orientation":orientation,"spaced":spaced,"ordered":ordered,"aligned":aligned,"axis":axis}

func snap(id: String, raw: Dictionary, radius: float) -> Dictionary:
	var pose := raw.duplicate(true)
	var axis: int = pose.turn % 2
	var guides: Array = []
	var best_alignment := radius+0.01
	var best_gap := radius+0.01
	var alignment_delta := 0.0
	var gap_delta := 0.0
	var aligned_peer := ""
	var aligned_edge := 0.0
	var own := footprint(id,raw)
	# Snap to nearby real edges regardless of size order: no automatic solution.
	for peer_id in IDS:
		if peer_id == id or poses[peer_id].turn % 2 != axis:
			continue
		var peer := footprint(peer_id)
		if absf(peer.get_center()[axis]-own.get_center()[axis]) > 270:
			continue
		for delta in [peer.position[1-axis]-own.position[1-axis],peer.end[1-axis]-own.end[1-axis]]:
			if absf(delta) < best_alignment:
				alignment_delta = delta
				best_alignment = absf(delta)
				aligned_peer = peer_id
				aligned_edge = peer.position[1-axis] if is_equal_approx(delta,peer.position[1-axis]-own.position[1-axis]) else peer.end[1-axis]
		if minf(absf(peer.position[1-axis]-own.position[1-axis]),absf(peer.end[1-axis]-own.end[1-axis])) <= radius:
			for delta in [peer.end[axis]+16-own.position[axis],peer.position[axis]-16-own.end[axis]]:
				if absf(delta) < best_gap:
					gap_delta = delta
					best_gap = absf(delta)
	# Apply at most one correction per axis, always measured from the raw pointer.
	pose.position[1-axis] += alignment_delta
	pose.position[axis] += gap_delta
	if not aligned_peer.is_empty():
		var peer := footprint(aligned_peer)
		var final_rect := footprint(id,pose)
		guides = [{"axis":axis,"edge":aligned_edge,"from":minf(peer.position[axis],final_rect.position[axis]),"to":maxf(peer.end[axis],final_rect.end[axis])}]
	return {"pose":pose,"guides":guides,"snapped":best_alignment <= radius or best_gap <= radius}
