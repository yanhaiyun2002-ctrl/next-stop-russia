extends SceneTree
var board: P1OrganizationBoard
var player: P1Session
var checks: Array[Dictionary] = []
var passed := 0
var failed := 0
var evidence := ""
var observed_ghost := false

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool,label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if ok:
		passed += 1
	else:
		failed += 1
		push_error(label)

func _frames(count := 5) -> void:
	for i in range(count):
		await process_frame

func _mouse(point: Vector2,down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = down
	root.push_input(event,true)

func _touch(point: Vector2,down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = root.get_final_transform()*point
	event.pressed = down
	Input.parse_input_event(event)

func _click(point: Vector2,touch := false) -> void:
	if touch:
		_touch(point,true)
	else:
		_mouse(point,true)
	await _frames(3)
	if touch:
		_touch(point,false)
	else:
		_mouse(point,false)
	await _frames(5)

func _drag(id: String,destination: Vector2,touch := false) -> void:
	var origin := board.item_rect(id).get_center()
	var starting_rect := board.item_rect(id)
	if touch:
		_touch(origin,true)
	else:
		_mouse(origin,true)
	await _frames(3)
	for i in range(1,9):
		var point := origin.lerp(destination,float(i)/8)
		if touch:
			var motion := InputEventScreenDrag.new()
			motion.index = 0
			motion.position = root.get_final_transform()*point
			motion.relative = root.get_final_transform().basis_xform((destination-origin)/8)
			Input.parse_input_event(motion)
		else:
			var motion := InputEventMouseMotion.new()
			motion.position = point
			motion.relative = (destination-origin)/8
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(motion,true)
		await _frames(3)
		observed_ghost = observed_ghost or board.dragging
		_check(board.item_rect(id) == starting_rect,"拖动只画 ghost，不改变 Control 几何 %s %d" % [id,i])
	if touch:
		_touch(destination,false)
	else:
		_mouse(destination,false)
	await _frames(6)

func _start_drag(id: String,touch := false) -> void:
	var origin := board.item_rect(id).get_center()
	if touch:
		_touch(origin,true)
	else:
		_mouse(origin,true)
	await _frames(3)
	if touch:
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = root.get_final_transform()*(origin+Vector2(16,-16))
		event.relative = root.get_final_transform().basis_xform(Vector2(16,-16))
		Input.parse_input_event(event)
	else:
		var event := InputEventMouseMotion.new()
		event.position = origin+Vector2(16,-16)
		event.relative = Vector2(16,-16)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(event,true)
	await _frames(4)

func _wheel_down(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.position = point
	event.pressed = true
	root.push_input(event,true)
	await _frames(6)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(evidence.path_join(label+".png")) == OK,"实际整理截图 "+label)

func _run() -> void:
	evidence = OS.get_environment("P1R_ORGANIZATION_EVIDENCE")
	if evidence.is_empty():
		evidence = ProjectSettings.globalize_path("res://docs/evidence/p1-01r/organization-independent")
	DirAccess.make_dir_recursive_absolute(evidence)
	create_timer(90).timeout.connect(func():quit(124))
	player = P1Session.new("PLAYTEST",evidence.path_join("data"))
	for i in range(5):
		player.advance_arrival()
	player.enter_home()
	player.choose_spot("by_window")
	player.pet_reaction_completed()
	player.confirm_name("测试猫")
	root.content_scale_size = Vector2i(1280,720)
	root.size = Vector2i(1280,720)
	board = P1OrganizationBoard.new()
	board.theme = load("res://ui/theme.tres")
	board.position = Vector2(32,32)
	board.size = Vector2(1200,420)
	root.add_child(board)
	board.configure(player)
	await _frames(12)
	_check(board.item_controls.size() == 4 and board.bin_controls.size() == 3,"四件独立物品与三仓")
	_check(board.unit_rects.A.size() == 2 and board.unit_rects.B.size() == 2 and board.unit_rects.C.size() == 1,"2/2/1 可视格位")
	_check(board.item_sources.textbook.position.x == board.item_sources.passport.position.x and board.item_sources.passport.position.y < board.item_sources.scarf.position.y,"PC左侧物品托盘为单列四件")
	_check(board.bin_regions.A.position.y < board.bin_regions.B.position.y and board.bin_regions.C.position.x > board.bin_regions.B.position.x,"PC右上A、右下B与窄C")
	var revision: int = player.state.revision
	await _drag("textbook",board.bin_rect("B").get_center())
	_check(not player.state.organization.placements.has("textbook") and player.state.revision == revision,"鼠标非法仓位拒绝且不改存档")
	_check(board.last_feedback.contains("A 区"),"非法原因可读")
	await _drag("textbook",board.bin_rect("A").get_center())
	_check(player.state.organization.placements.get("textbook") == "A","鼠标真正拖放放教材入A")
	_check(observed_ghost and not board.dragging and not board.pointer_active,"ghost 跟随期间可观察，松开清理")
	_check(player.undo_organization() and not player.state.organization.placements.has("textbook"),"撤销复用领域历史")
	await _frames()
	await _click(board.item_rect("textbook").get_center())
	_check(board.selected_item == "textbook","鼠标点击选择替代路径")
	await _click(board.global_position+board.unit_rects.A[0].get_center())
	_check(player.state.organization.placements.get("textbook") == "A","鼠标点空格位主体也能放置，不限标题")
	await _drag("textbook",board.global_position+Vector2(-15,-15))
	_check(player.state.organization.placements.get("textbook") == "A","已放物拖出有效区仍保留原位")
	await _capture("pc_organization")
	root.size = Vector2i(360,780)
	root.content_scale_size = Vector2i(360,780)
	board.position = Vector2(16,20)
	board.size = Vector2(308,496)
	await _frames(14)
	for id in board.item_controls:
		_check(Rect2(Vector2.ZERO,board.size).encloses(Rect2(board.item_controls[id].position,board.item_controls[id].size)),"手机物品未裁切 "+id)
	for id in board.bin_controls:
		_check(board.bin_controls[id].size.x >= 48 and board.bin_controls[id].size.y >= 48,"手机放置目标大于48 "+id)
	_check(board.bin_regions.A.end.y < board.bin_regions.B.position.y and board.bin_regions.B.end.y < board.bin_regions.C.position.y,"手机三个箱体上下堆叠")
	_check(is_equal_approx(board.unit_rects.A[0].position.y,board.unit_rects.A[1].position.y) and is_equal_approx(board.unit_rects.B[0].position.y,board.unit_rects.B[1].position.y),"手机A和B两个格位保持横排")
	_check(board.item_sources.textbook.position.y > board.bin_regions.C.end.y and board.item_sources.textbook.position.y == board.item_sources.passport.position.y and board.item_sources.scarf.position.y == board.item_sources.washbag.position.y,"手机底部物品托盘2x2")
	for id in board.unit_rects:
		for rect in board.unit_rects[id]:
			_check(rect.size.x >= 48 and rect.size.y >= 48,"手机箱内交互格位大于48 "+id)
	await _drag("passport",board.bin_rect("B").get_center(),true)
	_check(player.state.organization.placements.get("passport") == "B","合成触摸真正拖放护照入B")
	await _click(board.item_rect("scarf").get_center(),true)
	await _click(board.global_position+board.unit_rects.B[1].get_center(),true)
	_check(player.state.organization.placements.get("scarf") == "B","手机点B剩余空格位可放围巾，不抢已放护照")
	await _drag("washbag",board.bin_rect("C").get_center(),true)
	_check(player.state.organization.placements.get("washbag") == "C","合成触摸真正拖放洗漱包入C")
	_check(player.complete_organization(),"完整合法摆放复用原判题完成教程")
	await _capture("phone_organization")
	_check(player.undo_organization(true) and player.state.organization.placements.is_empty(),"重置不清除既有教程完成事件")
	await _frames()
	var solution_puzzle := {"bins":[{"id":"A","capacity":2},{"id":"B","capacity":2},{"id":"C","capacity":2}],"items":[{"id":"book","size":2},{"id":"passport","size":1},{"id":"cup","size":1}],"rules":[{"type":"allowedBins","itemId":"book","binIds":["A","B"]},{"type":"forbiddenTogether","itemIds":["passport","cup"]}]}
	_check(P1Organization.validate_placement(solution_puzzle,{},"book","B").is_empty(),"partial 允许多个合法仓位，不匹配唯一示例")
	_check(not P1Organization.validate_placement(solution_puzzle,{"book":"A"},"passport","A").is_empty(),"partial 容量超出拒绝")
	_check(not P1Organization.validate_placement(solution_puzzle,{"passport":"B"},"cup","B").is_empty(),"partial 禁止共仓拒绝")
	_check(P1Organization.validate_placement(player.puzzle,{"textbook":"B","passport":"A","scarf":"C"},"textbook","A").is_empty() == false,"修旧档时不能挤入仍被占满的目标仓")
	_check(P1Organization.validate_placement(player.puzzle,{"textbook":"B","scarf":"C"},"textbook","A").is_empty(),"旧P1非法草稿可逐件修复，不被其他旧错误锁住")
	await _click(board.item_rect("washbag").get_center())
	await _click(board.bin_rect("C").end-Vector2(10,10))
	_check(player.state.organization.placements.get("washbag") == "C","区域剩余空白主体也支持点选放置")
	player.undo_organization(true)
	await _frames()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16,20)
	scroll.size = Vector2(328,430)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	var top := Control.new()
	top.custom_minimum_size.y = 80
	stack.add_child(top)
	board.reparent(stack)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom := Control.new()
	bottom.custom_minimum_size.y = 500
	stack.add_child(bottom)
	await _frames(20)
	_check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page,"真实 ScrollContainer 内容可滚动")
	scroll.ensure_control_visible(board.item_controls.passport)
	await _frames(12)
	var before_scroll: Rect2 = board.get_global_rect()
	var before_revision: int = player.state.revision
	await _start_drag("passport")
	_check(board.pointer_active and board.dragging,"滚动前实际鼠标事件启动拖动")
	await _wheel_down(scroll.get_global_rect().get_center())
	_check(scroll.scroll_vertical > 0 and board.get_global_rect() != before_scroll,"真实滚轮事件滚动容器并移动board全局矩形")
	_check(not board.pointer_active and not board.dragging and board.pointer_item.is_empty(),"滚动发生后取消拖动并清理ghost状态")
	_mouse(board.bin_rect("B").get_center(),false)
	await _frames(5)
	_check(player.state.organization.placements.is_empty() and player.state.revision == before_revision,"滚动后松开不误放也不改存档")
	scroll.scroll_vertical = 0
	await _frames(12)
	scroll.ensure_control_visible(board.item_controls.passport)
	await _frames(12)
	await _start_drag("passport",true)
	_check(board.pointer_active and board.dragging,"祖先移动前实际合成触摸启动拖动")
	scroll.position += Vector2(4,8)
	await _frames(5)
	_check(not board.pointer_active and not board.dragging and board.hovered_bin.is_empty(),"祖先位置变化取消触摸拖动，不依赖resized信号")
	_touch(board.bin_rect("B").get_center(),false)
	await _frames(6)
	_check(player.state.organization.placements.is_empty() and player.state.revision == before_revision,"祖先移动后触摸释放不误放或悬挂")
	scroll.queue_free()
	await _frames()
	var output := FileAccess.open(evidence.path_join("organization_results.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":checks,"display":DisplayServer.get_name(),"note":"actual engine synthetic mouse/touch; no physical device or human acceptance"},"\t"))
	output.close()
	print("P1R_ORGANIZATION passed=%d failed=%d" % [passed,failed])
	quit(0 if failed == 0 else 1)
