class_name GrayboxCat
extends RefCounted
## Minimal geometric placeholder, in room coordinates, with no animation/AI.
const BODY := Color("52616c")
const HEAD := Color("39464d")
const EYES := Color("f2db97")
const NOSE := Color("25333c")

static func parts(anchor: Vector3, peek: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var z := anchor.z
	var head_z := z - 0.75 if peek else z
	_add(result, anchor, [Vector2(-0.36, 0.1), Vector2(-0.63, 0.16), Vector2(-0.64, 0.38), Vector2(-0.53, 0.4), Vector2(-0.5, 0.22), Vector2(-0.3, 0.22)], z, BODY, 10)
	_add(result, anchor, _ellipse(Vector2(-0.08, 0.16), Vector2(0.34, 0.15)), z, BODY, 11)
	_add(result, anchor, [Vector2(0.07, 0.4), Vector2(0.1, 0.63), Vector2(0.24, 0.44)], head_z, HEAD, 12)
	_add(result, anchor, [Vector2(0.26, 0.44), Vector2(0.4, 0.63), Vector2(0.43, 0.4)], head_z, HEAD, 12)
	_add(result, anchor, _ellipse(Vector2(0.24, 0.3), Vector2(0.18, 0.18)), head_z, HEAD, 13)
	for x in [0.17, 0.31]:
		_add(result, anchor, _ellipse(Vector2(x, 0.34), Vector2(0.027, 0.027)), head_z, EYES, 14)
	_add(result, anchor, [Vector2(0.21, 0.27), Vector2(0.27, 0.27), Vector2(0.24, 0.23)], head_z, NOSE, 15)
	return result

static func _ellipse(center: Vector2, radius: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(20):
		var angle := TAU * i / 20
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

static func _add(result: Array[Dictionary], anchor: Vector3, polygon: Array[Vector2], z: float, color: Color, tie: float) -> void:
	var points: Array[Vector3] = []
	for point in polygon:
		points.append(Vector3(anchor.x + point.x, anchor.y + point.y, z))
	result.append({"points": points, "depth": z, "color": color, "tie": tie})
