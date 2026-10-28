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
