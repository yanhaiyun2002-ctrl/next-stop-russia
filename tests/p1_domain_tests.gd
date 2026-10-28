extends SceneTree
var passed := 0
var failed := 0
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label, "passed":ok})
	if ok:
		passed += 1
	else:
		failed += 1
		push_error(label)

func _arrived(player: P1Session) -> void:
	for i in range(5):
		check(player.advance_arrival(), "到达对白持久化 %d" % i)
	check(player.enter_home(), "持钥匙入宿舍")

func _run() -> void:
	evidence = OS.get_environment("P1_EVIDENCE_DIR")
	var base := evidence.path_join("domain-data")
	var player := P1Session.new("PLAYTEST", base)
	check(player.state.schemaVersion == 1, "显式 schema 1；无 P0 玩家存档迁移源")
	check(not player.advance_message() and not player.enter_home() and not player.complete_organization(), "新档不能绕过钥匙或猫首遇")
	_arrived(player)
	check(not player.state.cat.firstPetCompleted and player.state.rewards.is_empty(), "摸猫前无奖励")
	check(player.choose_spot("by_window"), "窗为合法独立构件藏点")
	check(not player.choose_spot("bad_spot"), "拒绝未知藏点")
	check(player.pet_reaction_completed(), "摸猫完成原子写奖励及待命名")
	var pet_revision: int = player.state.revision
	check(player.pet_reaction_completed() and player.state.revision == pet_revision and player.state.cat.rounds == 1, "同一轮摸猫完成事件重放幂等")
	var restored := P1Session.new("PLAYTEST", base)
	check(restored.state.cat.namePending and restored.state.rewards.size() == 1 and restored.state.quests.q01_cat == "active", "命名前重启恢复且 Q01 未完成")
	check(not restored.confirm_name("   ") and not restored.confirm_name("a".repeat(21)), "空白与超长名字拒绝")
	check(not restored.advance_message() and not restored.complete_organization(), "命名未完成不开放整理或城市")
	check(restored.confirm_name("  Снежок 小雪  "), "俄中名字去首尾空格并确认")
	check(not restored.confirm_name("第二次") and restored.state.cat.displayName == "Снежок 小雪", "确认幂等，不重复命名")
	check(restored.state.quests.q01_cat == "completed" and restored.state.quests.q02_organize == "active", "名字确认才完成 Q01")
	check(not restored.complete_organization(), "未放完物品不能通过")
	for pair in [["textbook","B"],["passport","B"],["scarf","B"],["washbag","C"]]:
		check(restored.place_item(pair[0], pair[1]), "教程摆放保存 " + pair[0])
	check(not restored.complete_organization(), "容量及区域非法拒绝")
	check(restored.undo_organization(), "非法摆放可撤销")
	var mid := P1Session.new("PLAYTEST", base)
	check(mid.state.organization.placements.size() == 3 and not mid.state.organization.tutorialCompleted, "退出重入保留局部摆放，不跳 Q02")
	check(mid.undo_organization(true), "可重置教程")
	for pair in [["textbook","A"],["passport","B"],["scarf","B"],["washbag","C"]]:
		mid.place_item(pair[0], pair[1])
	check(mid.complete_organization(), "源教程合法解通过")
	check(mid.state.rewards.size() == 2 and not mid.state.story.cityUnlocked, "整理纪念一次；消息读完前城市仍锁")
	check(mid.complete_organization() and mid.state.rewards.size() == 2, "重做教程不重复奖励")
	check(mid.advance_message() and not mid.state.story.cityUnlocked, "消息第一条不提前解锁")
	check(mid.advance_message() and mid.state.story.cityUnlocked, "消息第二条完成 Q03")
	check(mid.advance_message() and mid.state.story.annaMessageIndex == 2, "重复读消息幂等")
	var dev := P1Session.new("DEV", base)
	check(dev.state.revision == 0 and dev.store.directory != mid.store.directory, "DEV PLAYTEST 物理目录隔离")
	check(P1Session.new("PLAYTEST", base).state.story.cityUnlocked, "完整进度重启仍保留")
	# Rule fixture deliberately has multiple valid layouts; exampleSolution is wrong.
	var multiple := {"bins":[{"id":"A","capacity":2},{"id":"B","capacity":2},{"id":"C","capacity":1}], "items":[{"id":"book","size":2},{"id":"passport","size":1},{"id":"cup","size":1}], "rules":[{"type":"allowedBins","itemId":"book","binIds":["A","B"]},{"type":"fixedBin","itemId":"cup","binId":"C"},{"type":"forbiddenTogether","itemIds":["passport","cup"]}], "verification":{"exampleSolution":{}}}
	check(P1Organization.validate(multiple, {"book":"A","passport":"B","cup":"C"}).is_empty(), "约束判题接受合法解一")
	check(P1Organization.validate(multiple, {"book":"B","passport":"A","cup":"C"}).is_empty(), "约束判题接受合法解二，不匹配示例")
	check(not P1Organization.validate(multiple, {"book":"A","passport":"C","cup":"C"}).is_empty(), "禁止共仓或容量非法失败")
	multiple.bins[2].capacity = 3
	check(not P1Organization.validate(multiple, {"book":"A","passport":"C","cup":"C"}).is_empty(), "容量足够时禁止共仓仍生效")
	check(not P1Organization.validate(multiple, {"book":"C","passport":"A","cup":"C"}).is_empty(), "allowedBins 生效")
	var save_path := mid.store.directory.path_join("save.json")
	var original := FileAccess.get_file_as_string(save_path)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string("broken {")
	file.close()
	var recovered := P1Session.new("PLAYTEST", base)
	check(not recovered.store.blocked and not recovered.store.notice.is_empty(), "坏档恢复有效备份并提示")
	check(Array(DirAccess.get_files_at(mid.store.directory)).any(func(name): return name.contains(".corrupt-")), "损坏原文件已保留")
	check(recovered.advance_message(), "恢复备份可继续可靠写入")
	var future: Dictionary = JSON.parse_string(original)
	future.schemaVersion = 999
	file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(future))
	file.close()
	var newer := P1Session.new("PLAYTEST", base)
	check(newer.store.blocked and not newer.advance_arrival() and JSON.parse_string(FileAccess.get_file_as_string(save_path)).schemaVersion == 999, "未来版本禁止覆盖及倒退迁移")
	var invalid := P1SaveStore.fresh()
	invalid.cat = {"firstPetCompleted":true}
	check(not P1SaveStore.valid(invalid), "不完整数据结构拒绝")
	invalid = P1SaveStore.fresh()
	invalid.story.cityUnlocked = true
	check(not P1SaveStore.valid(invalid), "坏档不能注入城市解锁")
	for section_key in [["story","arrivalIndex"],["story","annaMessageIndex"],["cat","rounds"],["cat","roundId"]]:
		invalid = P1SaveStore.fresh()
		invalid[section_key[0]][section_key[1]] = 0.5
		check(not P1SaveStore.valid(invalid), "拒绝小数进度防软锁 " + section_key[1])
	invalid = P1SaveStore.fresh()
	invalid.story.arrivalIndex = 5
	check(not P1SaveStore.valid(invalid), "对白结束但无钥匙的坏档拒绝")
	invalid = mid.state.duplicate(true)
	invalid.story.cityUnlocked = false
	invalid.quests.q03_anna_message = "active"
	check(not P1SaveStore.valid(invalid), "消息完成但城市未解锁的坏档拒绝")
	invalid = player.state.duplicate(true)
	invalid.cat.displayName = "   "
	invalid.cat.namePending = false
	check(not P1SaveStore.valid(invalid), "空白名字与待命名标志不一致拒绝")
	for schema in ["broken", {}, 0.5]:
		var malformed := P1SaveStore.new("MALFORMED_" + str(typeof(schema)), base)
		DirAccess.make_dir_recursive_absolute(malformed.directory)
		invalid = P1SaveStore.fresh()
		invalid.schemaVersion = schema
		file = FileAccess.open(malformed.directory.path_join("save.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(invalid))
		file.close()
		malformed.read_save()
		check(malformed.blocked, "畸形 schema 正常报错保留原档 " + str(schema))
	var no_backup := P1SaveStore.new("BROKEN", base)
	DirAccess.make_dir_recursive_absolute(no_backup.directory)
	file = FileAccess.open(no_backup.directory.path_join("save.json"), FileAccess.WRITE)
	file.store_string("invalid")
	file.close()
	no_backup.read_save()
	check(no_backup.blocked and FileAccess.get_file_as_string(no_backup.directory.path_join("save.json")) == "invalid", "无备份坏档保留，拒绝静默新档")
	var blocked_base := base.path_join("file_instead_of_directory")
	file = FileAccess.open(blocked_base, FileAccess.WRITE)
	file.store_string("fixture")
	file.close()
	var unwritable := P1Session.new("PLAYTEST", blocked_base)
	check(not unwritable.advance_arrival() and unwritable.state.story.arrivalIndex == 0 and not unwritable.last_error.is_empty(), "写入失败内存与剧情不推进")
	var output := FileAccess.open(evidence.path_join("domain_results.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":checks}, "\t"))
	output.close()
	print("P1_DOMAIN passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
