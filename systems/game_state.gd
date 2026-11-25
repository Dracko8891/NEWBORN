extends Node

signal inventory_changed
signal health_changed(value: int)
signal chapter_changed(chapter: int)
signal notification_requested(message: String)

const START_SLOTS := 6
const EXPANDED_SLOTS := 8
const STACK_LIMIT := 2
const SAVE_PATH := "user://newborn_save.json"

var chapter: int = 1
var health_state: int = 0 # 0 = saudável, 1 = sangramento, 2 = morto
var inventory_capacity: int = START_SLOTS
var inventory: Array[Dictionary] = []
var safe_storage: Array[Dictionary] = []
var unlocked_chapters: Array[int] = [1]
var puzzle_flags: Dictionary = {}
var collected_flags: Dictionary = {}

func _ready() -> void:
	load_game()

func add_item(item_id: String, display_name: String, consumable: bool = false) -> bool:
	if item_id.is_empty():
		return false
	if consumable:
		for i in range(inventory.size()):
			if inventory[i].get("id") == item_id and int(inventory[i].get("count", 1)) < STACK_LIMIT:
				inventory[i]["count"] = int(inventory[i].get("count", 1)) + 1
				inventory_changed.emit()
				return true
	if inventory.size() >= inventory_capacity:
		notification_requested.emit("Inventário cheio")
		return false
	inventory.append({"id": item_id, "name": display_name, "count": 1, "consumable": consumable})
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var total := 0
	for slot in inventory:
		if str(slot.get("id", "")) == item_id:
			total += maxi(0, int(slot.get("count", 1)))
			if total >= amount:
				return true
	return false

func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not has_item(item_id, amount):
		return false
	var remaining := amount
	# Consume from the last matching stack first; pre-check prevents partial removal.
	for i in range(inventory.size() - 1, -1, -1):
		if str(inventory[i].get("id", "")) != item_id:
			continue
		var available := maxi(0, int(inventory[i].get("count", 1)))
		var taken := mini(available, remaining)
		remaining -= taken
		inventory[i]["count"] = available - taken
		if int(inventory[i]["count"]) <= 0:
			inventory.remove_at(i)
		if remaining <= 0:
			break
	inventory_changed.emit()
	return true

func discard_item(item_id: String) -> bool:
	for i in range(inventory.size()):
		if str(inventory[i].get("id", "")) == item_id:
			inventory.remove_at(i)
			inventory_changed.emit()
			return true
	return false

func expand_belt_in_chapter_four() -> void:
	if chapter >= 4 and inventory_capacity != EXPANDED_SLOTS:
		inventory_capacity = EXPANDED_SLOTS
		inventory_changed.emit()

func store_item(item_id: String) -> bool:
	for i in range(inventory.size()):
		if str(inventory[i].get("id", "")) == item_id:
			safe_storage.append(inventory.pop_at(i))
			inventory_changed.emit()
			return true
	return false

func retrieve_item(item_id: String) -> bool:
	if inventory.size() >= inventory_capacity:
		return false
	for i in range(safe_storage.size()):
		if str(safe_storage[i].get("id", "")) == item_id:
			inventory.append(safe_storage.pop_at(i))
			inventory_changed.emit()
			return true
	return false

func set_health_state(value: int) -> void:
	health_state = clampi(value, 0, 2)
	health_changed.emit(health_state)

func set_chapter(value: int) -> void:
	chapter = clampi(value, 1, 7)
	if chapter >= 4:
		expand_belt_in_chapter_four()
	if not unlocked_chapters.has(chapter):
		unlocked_chapters.append(chapter)
	chapter_changed.emit(chapter)

func set_flag(flag: String, value: Variant = true) -> void:
	puzzle_flags[flag] = value

func get_flag(flag: String, fallback: Variant = false) -> Variant:
	return puzzle_flags.get(flag, fallback)

func save_game() -> bool:
	var data := {
		"chapter": chapter,
		"health_state": health_state,
		"inventory_capacity": inventory_capacity,
		"inventory": inventory,
		"safe_storage": safe_storage,
		"unlocked_chapters": unlocked_chapters,
		"puzzle_flags": puzzle_flags,
		"collected_flags": collected_flags
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		notification_requested.emit("Falha ao abrir arquivo de salvamento")
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	chapter = clampi(int(data.get("chapter", 1)), 1, 7)
	health_state = clampi(int(data.get("health_state", 0)), 0, 2)
	inventory_capacity = EXPANDED_SLOTS if chapter >= 4 else START_SLOTS
	inventory = _valid_slots(data.get("inventory", []))
	safe_storage = _valid_slots(data.get("safe_storage", []))
	unlocked_chapters.clear()
	for item in data.get("unlocked_chapters", [1]):
		unlocked_chapters.append(clampi(int(item), 1, 7))
	puzzle_flags = data.get("puzzle_flags", {})
	collected_flags = data.get("collected_flags", {})
	inventory_changed.emit()
	health_changed.emit(health_state)
	chapter_changed.emit(chapter)
	return true

func _valid_slots(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			result.append(item.duplicate(true))
	return result
