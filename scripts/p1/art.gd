class_name P1Art
extends RefCounted
## Visual lookup only; no story/save decisions. Missing art has a code fallback.
static var paths: Dictionary = {}
static var registry_loaded := false
static var cache: Dictionary = {}
static var alpha_cache: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if not registry_loaded:
		registry_loaded = true
		var registry = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art_registry.json"))
		if registry is Dictionary:
			for entry in registry.get("assets", []):
				if entry.get("rendererKey", "") != "":
					paths[entry.rendererKey] = "res://" + str(entry.path).trim_prefix("res://")
	if cache.has(id):
		return cache[id]
	var path: String = paths.get(id, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		cache[id] = load(path)
		return cache[id]
	return null

static func alpha_image(id: String) -> Image:
	if not alpha_cache.has(id):
		var image_texture := texture(id)
		if image_texture:
			alpha_cache[id] = image_texture.get_image()
	return alpha_cache.get(id)
