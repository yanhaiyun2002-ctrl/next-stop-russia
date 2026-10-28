class_name GrayboxFurniture
extends Node2D
## Three replaceable geometric samples, not a furniture/decoration system.
@export var furniture_id: StringName
@export var display_name: String
@export var floor_position: Vector2
@export var dimensions: Vector3
@export_enum("bed", "desk", "wardrobe") var shape: String = "bed"

func footprint() -> Rect2:
	return Rect2(floor_position - Vector2(dimensions.x / 2.0, 0), Vector2(dimensions.x, dimensions.z))

func boxes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if shape == "bed":
		_add(result, Vector3(-0.8, 0.28, 0), Vector3(1.6, 0.22, 2.0), Color("687d8a"))
		_add(result, Vector3(-0.8, 0.5, 0.02), Vector3(1.6, 0.15, 1.94), Color("bdc8cb"))
		_add(result, Vector3(-0.68, 0.65, 1.53), Vector3(1.36, 0.10, 0.34), Color("e4e4db"))
		_add(result, Vector3(-0.83, 0.05, 1.96), Vector3(1.66, 0.95, 0.12), Color("6b7f8c"))
		for x in [-0.72, 0.60]:
			for z in [0.05, 1.80]:
				_add(result, Vector3(x, 0, z), Vector3(0.12, 0.30, 0.12), Color("53646e"))
	elif shape == "desk":
		_add(result, Vector3(-0.725, 0.84, 0), Vector3(1.45, 0.12, 0.80), Color("a5967d"))
		for x in [-0.66, 0.55]:
			for z in [0.04, 0.65]:
				_add(result, Vector3(x, 0, z), Vector3(0.11, 0.84, 0.11), Color("71695b"))
	else:
		_add(result, Vector3(-0.65, 0.05, 0.04), Vector3(1.30, 2.15, 0.84), Color("6b7c76"))
		_add(result, Vector3(-0.61, 0.15, 0), Vector3(0.59, 1.94, 0.055), Color("8c9d92"))
		_add(result, Vector3(0.02, 0.15, 0), Vector3(0.59, 1.94, 0.055), Color("84968c"))
	return result

func _add(result: Array[Dictionary], offset: Vector3, extent: Vector3, color: Color) -> void:
	result.append({"owner": furniture_id, "origin": Vector3(floor_position.x, 0, floor_position.y) + offset,
		"size": extent, "color": color})
