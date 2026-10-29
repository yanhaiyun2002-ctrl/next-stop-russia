class_name P1Session
extends RefCounted
signal changed
var store: P1SaveStore
var state: Dictionary
var puzzle: Dictionary
var last_error := ""

func _init(channel := "PLAYTEST", base := "", profile := "legacy") -> void:
	store = P1SaveStore.new(channel, base, profile)
	state = store.read_save()
	last_error = store.error
	puzzle = JSON.parse_string(FileAccess.get_file_as_string("res://data/p1/organization_tutorial.json"))

func _commit(next: Dictionary) -> bool:
	next.revision += 1
	if not store.write_save(next):
		last_error = store.error
		changed.emit()
		return false
	state = next
	last_error = ""
	changed.emit()
	return true

func advance_arrival() -> bool:
	if state.story.homeEntered or state.story.arrivalIndex >= 5:
		return false
	var next := state.duplicate(true)
	next.story.arrivalIndex += 1
	if next.story.arrivalIndex >= 3:
		next.story.hasHomeKey = true
	return _commit(next)

func enter_home() -> bool:
	if state.story.arrivalIndex != 5 or not state.story.hasHomeKey:
		return false
	if state.story.homeEntered:
		return true
	var next := state.duplicate(true)
	next.story.homeEntered = true
	next.quests.q00_arrival = "completed"
	next.quests.q01_cat = "active"
	return _commit(next)

func choose_spot(id: String) -> bool:
	if not state.story.homeEntered or state.cat.namePending or P1Content.spot(id).is_empty():
		return false
	var next := state.duplicate(true)
	if next.cat.spotId != id or next.cat.roundId == next.cat.petRoundId:
		next.cat.roundId += 1
	next.cat.spotId = id
	return _commit(next)

func pet_reaction_completed() -> bool:
	if not state.story.homeEntered or state.cat.spotId.is_empty():
		return false
	if state.cat.petRoundId == state.cat.roundId:
		return true
	var next := state.duplicate(true)
	next.cat.rounds += 1
	next.cat.petRoundId = next.cat.roundId
	if not next.cat.firstPetCompleted:
		next.cat.firstPetCompleted = true
		next.cat.namePending = true
		next.rewards.cat_first_meeting_v1 = true
	return _commit(next)

func confirm_name(value: String) -> bool:
	var trimmed := value.strip_edges()
	if not state.cat.namePending or trimmed.is_empty() or trimmed.length() > 20:
		last_error = "请输入 1～20 个字符的名字，再点击确认。"
		return false
	for i in range(trimmed.length()):
		if trimmed.unicode_at(i) < 32:
			last_error = "名字不能包含控制字符。"
			return false
	var next := state.duplicate(true)
	next.cat.displayName = trimmed
	next.cat.namePending = false
	next.quests.q01_cat = "completed"
	next.quests.q02_organize = "active"
	return _commit(next)

func place_item(id: String, destination: String) -> bool:
	if state.quests.q01_cat != "completed" or not P1Content.data().itemNames.has(id) or not P1Content.data().binNames.has(destination):
		return false
	var next := state.duplicate(true)
	next.organization.history.append(next.organization.placements.duplicate())
	if next.organization.history.size() > 50:
		next.organization.history.pop_front()
	next.organization.placements[id] = destination
	return _commit(next)

func undo_organization(reset := false) -> bool:
	if state.quests.q01_cat != "completed":
		return false
	var next := state.duplicate(true)
	if reset:
		next.organization.history.append(next.organization.placements.duplicate())
		next.organization.placements = {}
	elif not next.organization.history.is_empty():
		next.organization.placements = next.organization.history.pop_back()
	else:
		return false
	return _commit(next)

func complete_organization() -> bool:
	if state.quests.q01_cat != "completed":
		return false
	last_error = P1Organization.validate(puzzle, state.organization.placements)
	if not last_error.is_empty():
		return false
	var next := state.duplicate(true)
	next.organization.tutorialCompleted = true
	if next.organization.journalDate.is_empty():
		next.organization.journalDate = Time.get_date_string_from_system()
	next.rewards.organization_tutorial_v1 = true
	next.quests.q02_organize = "completed"
	if not next.story.cityUnlocked:
		next.quests.q03_anna_message = "active"
	return _commit(next)

func advance_message() -> bool:
	if state.quests.q01_cat != "completed" or not state.organization.tutorialCompleted:
		return false
	if state.story.cityUnlocked:
		return true
	var next := state.duplicate(true)
	next.story.annaMessageIndex += 1
	if next.story.annaMessageIndex == 2:
		next.story.cityUnlocked = true
		next.quests.q03_anna_message = "completed"
	return _commit(next)
