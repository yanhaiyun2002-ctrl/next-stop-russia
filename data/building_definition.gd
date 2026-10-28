class_name BuildingDefinition
extends Resource
## Stable navigation identity. Display position is normalized map data, not pixels.

@export var id: StringName
@export var display_name: String
@export var map_position: Vector2
@export_file("*.tscn") var destination: String
@export var is_open: bool = false
