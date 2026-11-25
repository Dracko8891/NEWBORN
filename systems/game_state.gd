extends Node

signal inventory_changed
signal health_changed(value: int)
signal chapter_changed(chapter: int)
signal notification_requested(message: String)

const START_SLOTS := 6
const EXPANDED_SLOTS := 8
const STACK_LIMIT := 2
const SAVE_PATH := "user://newborn_save.json"

enum StartMode { STANDARD, CLASSIC_DATA_RODS }
var start_mode: StartMode = StartMode.STANDARD
var photosensitive_mode := false
var directional_subtitles := true
var chapter: int = 1
var health_state: int = 0
var flashlight_charge_saved: float = 240.0
var inventory_capacity: int = START_SLOTS
var inventory: Array[Dictionary] = []
var safe_storage: Array[Dictionary] = []
var unlocked_chapters: Array[int] = [1]
var puzzle_flags: Dictionary = {}
var collected_flags: Dictionary = {}

func _ready() -> void:
	load_game()

func start_new_game(mode: int = StartMode.STANDARD) -> void:
	start_mode = clampi(mode, 0, 1)
	chapter = 1
	health_state = 0
	flashlight_charge_saved = 240.0
	inventory_capacity = START_SLOTS
	inventory.clear()
	safe_storage.clear()
	unlocked_chapters = [1]
	puzzle_flags.clear()
	collected_flags.clear()
	save_game()
	inventory_changed.emit()
	health_changed.emit(health_state)
	chapter_changed.emit(chapter)

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

func use_item(item_id: String, user: Node = null) -> bool:
	if not has_item(item_id):
		return false
	var key := item_id.strip_edges().to_lower()
	var used := false
	match key:
		"kit_estanca", "hemostatic_kit", "bandage", "curativo", "kit_medico", "first_aid_kit", "medkit", "hypo_spray", "hipospray":
			if health_state != 1:
				notification_requested.emit("O tratamento só é necessário durante um sangramento")
				return false
			set_health_state(0)
			notification_requested.emit("Ferimento tratado")
			used = true
		"bateria", "battery", "energy_cell", "celula_energia":
			if user == null or not user.has_method("recharge_flashlight") or not bool(user.recharge_flashlight(90.0)):
				notification_requested.emit("Não foi possível recarregar a lanterna")
				return false
			notification_requested.emit("Carga da lanterna restaurada")
			used = true
		_:
			notification_requested.emit("Este recurso ainda não pode ser usado")
			return false
	if used:
		remove_item(item_id, 1)
		save_game()
	return used

func discard_item(item_id: String) -> bool:
	for i in range(inventory.size()):
		if str(inventory[i].get("id", "")) == item_id:
			inventory.remove_at(i)
			inventory_changed.emit()
			save_game()
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
			save_game()
			return true
	return false

func retrieve_item(item_id: String) -> bool:
	if inventory.size() >= inventory_capacity:
		notification_requested.emit("Inventário cheio")
		return false
	for i in range(safe_storage.size()):
		if str(safe_storage[i].get("id", "")) == item_id:
			inventory.append(safe_storage.pop_at(i))
			inventory_changed.emit()
			save_game()
			return true
	return false

func store_all_items() -> int:
	var moved := inventory.size()
	for slot in inventory:
		safe_storage.append(slot.duplicate(true))
	inventory.clear()
	if moved > 0:
		inventory_changed.emit()
		save_game()
	return moved

func retrieve_all_items() -> int:
	var moved := 0
	while not safe_storage.is_empty() and inventory.size() < inventory_capacity:
		inventory.append(safe_storage.pop_front())
		moved += 1
	if moved > 0:
		inventory_changed.emit()
		save_game()
	return moved

func safe_storage_count() -> int:
	return safe_storage.size()

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
	for player_node in get_tree().get_nodes_in_group("player"):
		var current_charge: Variant = player_node.get("flashlight_charge")
		if current_charge != null:
			flashlight_charge_saved = clampf(float(current_charge), 0.0, 240.0)
			break
	var data := {
		"chapter": chapter,
		"health_state": health_state,
		"flashlight_charge": flashlight_charge_saved,
		"inventory_capacity": inventory_capacity,
		"inventory": inventory,
		"safe_storage": safe_storage,
		"unlocked_chapters": unlocked_chapters,
		"puzzle_flags": puzzle_flags,
		"collected_flags": collected_flags,
		"start_mode": int(start_mode),
		"photosensitive_mode": photosensitive_mode,
		"directional_subtitles": directional_subtitles
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		notification_requested.emit("Falha ao abrir arquivo de salvamento")
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		notification_requested.emit("Falha ao gravar salvamento")
		return false
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	chapter = clampi(int(data.get("chapter", 1)), 1, 7)
	health_state = clampi(int(data.get("health_state", 0)), 0, 2)
	flashlight_charge_saved = clampf(float(data.get("flashlight_charge", 240.0)), 0.0, 240.0)
	inventory_capacity = EXPANDED_SLOTS if chapter >= 4 else START_SLOTS
	inventory = _valid_slots(data.get("inventory", []), inventory_capacity)
	safe_storage = _valid_slots(data.get("safe_storage", []), 1000)
	unlocked_chapters.clear()
	var unlocked_data: Variant = data.get("unlocked_chapters", [1])
	if typeof(unlocked_data) == TYPE_ARRAY:
		for item in unlocked_data:
			var unlocked := clampi(int(item), 1, 7)
			if not unlocked_chapters.has(unlocked):
				unlocked_chapters.append(unlocked)
	puzzle_flags = data.get("puzzle_flags", {}) if typeof(data.get("puzzle_flags", {})) == TYPE_DICTIONARY else {}
	collected_flags = data.get("collected_flags", {}) if typeof(data.get("collected_flags", {})) == TYPE_DICTIONARY else {}
	start_mode = clampi(int(data.get("start_mode", 0)), 0, 1)
	photosensitive_mode = bool(data.get("photosensitive_mode", false))
	directional_subtitles = bool(data.get("directional_subtitles", true))
	inventory_changed.emit()
	health_changed.emit(health_state)
	chapter_changed.emit(chapter)
	return true

func _valid_slots(value: Variant, max_slots: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		if typeof(item) == TYPE_DICTIONARY and item.has("id") and result.size() < max_slots:
			var slot: Dictionary = item.duplicate(true)
			slot["count"] = clampi(int(slot.get("count", 1)), 1, STACK_LIMIT)
			result.append(slot)
	return result
