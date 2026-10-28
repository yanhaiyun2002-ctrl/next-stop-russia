class_name P1Organization
extends RefCounted
## Validate rules, never compare against verification.exampleSolution.
static func validate(puzzle: Dictionary, placements: Dictionary) -> String:
	var bins: Dictionary = {}
	for bin in puzzle.bins:
		bins[bin.id] = {"capacity": bin.capacity, "used": 0}
	if placements.size() != puzzle.items.size():
		return "请放好全部物品。"
	for item in puzzle.items:
		var destination = placements.get(item.id, "")
		if not destination is String or not bins.has(destination):
			return "每件物品都需要合法仓位。"
		bins[destination].used += item.size
	for bin in bins.values():
		if bin.used > bin.capacity:
			return "容量不足，请撤销或换一个区域。"
	for rule in puzzle.rules:
		match rule.type:
			"fixedBin":
				if placements.get(rule.itemId) != rule.binId:
					return "检查物品对应的区域。"
			"allowedBins":
				if placements.get(rule.itemId) not in rule.binIds:
					return "有物品放入了不允许的区域。"
			"forbiddenTogether":
				var occupied: Array = []
				for id in rule.itemIds:
					if occupied.has(placements.get(id)):
						return "这些物品不能同仓。"
					occupied.append(placements.get(id))
			_:
				return "未知题目规则，请保留进度并反馈。"
	return ""

static func validate_placement(puzzle: Dictionary, placements: Dictionary, item_id: String, bin_id: String) -> String:
	## Partial placement shares the puzzle rules, without requiring unplaced items.
	var known_items: Dictionary = {}
	var capacities: Dictionary = {}
	for item in puzzle.items:
		known_items[item.id] = item.size
	for bin in puzzle.bins:
		capacities[bin.id] = bin.capacity
	if not known_items.has(item_id) or not capacities.has(bin_id):
		return "不是可放置的物品或区域。"
	var proposed := placements.duplicate()
	proposed[item_id] = bin_id
	var used: Dictionary = {}
	for id in proposed:
		if not known_items.has(id) or not capacities.has(proposed[id]):
			return "有未识别的物品或区域，请保留进度反馈。"
		used[proposed[id]] = used.get(proposed[id], 0) + known_items[id]
	for id in used:
		# Old P1 drafts may already contain an invalid partial layout. Reject a new
		# violation in the destination while allowing those drafts to be repaired.
		if id == bin_id and used[id] > capacities[id]:
			return "%s 区容量不足：需要 %d 格，只有 %d 格。" % [id, used[id], capacities[id]]
	for rule in puzzle.rules:
		match rule.type:
			"fixedBin":
				if rule.itemId == item_id and proposed[rule.itemId] != rule.binId:
					return "这件物品应放入 %s 区。" % rule.binId
			"allowedBins":
				if rule.itemId == item_id and proposed[rule.itemId] not in rule.binIds:
					return "这件物品不能放入该区域。"
			"forbiddenTogether":
				if item_id not in rule.itemIds:
					continue
				for id in rule.itemIds:
					if id == item_id or not proposed.has(id):
						continue
					if proposed[id] == bin_id:
						return "这些物品不能放在同一区域。"
			_:
				return "未知题目规则，请保留进度反馈。"
	return ""
