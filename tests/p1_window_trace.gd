extends Node
## Test-only observation. No input handling/mutation; no production dependency.
var app: Control
var evidence := ""
var requested_size := Vector2i.ZERO
var records: Array[Dictionary] = []
var previous: Array = []

func _process(_delta: float) -> void:
	var window := get_tree().root
	var geometry := [window.size, window.get_visible_rect().size, window.content_scale_size]
	if geometry != previous:
		previous = geometry
		capture("geometry_changed")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag:
		capture(event.get_class(), str(event.get("position")))

func capture(kind: String, point := "") -> void:
	if records.size() > 3000:
		return
	var window := get_tree().root
	var row := {"atMsec":Time.get_ticks_msec(),"kind":kind,"point":point,"requested":str(requested_size),"actual":str(window.size),"logical":str(window.get_visible_rect().size),"screen":str(DisplayServer.screen_get_size()),"usable":str(DisplayServer.screen_get_usable_rect()),"borderless":window.borderless}
	if is_instance_valid(app) and is_instance_valid(app.active_room):
		var view: DormitoryView = app.active_room.room_view
		row.merge({"canvas":str(view.get_global_rect()),"scale":view.view_scale,"camera":view.focus_x,"revision":view.view_revision,"settled":app.safe_layout.is_layout_settled()})
	records.append(row)

func _exit_tree() -> void:
	var file := FileAccess.open(evidence.path_join("window_input_trace.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(records,"\t"))
		file.close()
