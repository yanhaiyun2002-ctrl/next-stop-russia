extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
    var app: Control
    var integrated := OS.get_environment("SCHOOL_ENTRY") == "integrated"
    if integrated:
        var base := P1SaveStore.storage_root()
        var fixture := preload("res://scripts/dev_tools/module_preview.gd").fixture("home",base)
        var store := P1SaveStore.new("PLAYTEST",base)
        if not store.write_save(fixture.state): quit(2); return
        app = preload("res://scenes/main.tscn").instantiate()
    else:
        app = preload("res://scenes/school_demo.tscn").instantiate()
    root.add_child(app)
    for i in 12: await process_frame
    var probe := preload("res://scripts/school/playthrough_probe.gd").new()
    probe.app = app
    probe.integrated = integrated
    if not integrated: probe.view = app.get_node("SafeLayout").get_child(0)
    app.add_child(probe)
