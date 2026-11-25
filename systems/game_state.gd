extends Node
class_name NewbornGameState

signal inventory_changed
signal health_changed(value: float)
signal chapter_changed(chapter: int)

const START_SLOTS := 6
const EXPANDED_SLOTS := 8
const STACK_LIMIT := 2

var chapter := 1
var health_state := 0 # 0 verde, 1 trauma/sangramento, 2 morto
var inventory_capacity := START_SLOTS
var inventory: Array[Dictionary] = []
var safe_storage: Array[Dictionary] = []
var unlocked_chapters: Array[int] = [1]
var puzzle_flags: Dictionary = {}
var collected_flags: Dictionary = {}

func add_item(item_id: String, display_name: String, consumable := false) -> bool:
    if consumable:
        for slot in inventory:
            if slot.id == item_id and int(slot.count) < STACK_LIMIT:
                slot.count += 1
                inventory_changed.emit()
                return true
    if inventory.size() >= inventory_capacity:
        return false
    inventory.append({"id": item_id, "name": display_name, "count": 1, "consumable": consumable})
    inventory_changed.emit()
    return true

func remove_item(item_id: String, amount := 1) -> bool:
    for i in range(inventory.size()):
        if inventory[i].id == item_id:
            inventory[i].count -= amount
            if inventory[i].count <= 0:
                inventory.remove_at(i)
            inventory_changed.emit()
            return true
    return false

func expand_belt_in_chapter_four() -> void:
    if chapter >= 4:
        inventory_capacity = EXPANDED_SLOTS
        inventory_changed.emit()

func store_item(item_id: String) -> bool:
    for i in range(inventory.size()):
        if inventory[i].id == item_id:
            safe_storage.append(inventory.pop_at(i))
            inventory_changed.emit()
            return true
    return false

func retrieve_item(item_id: String) -> bool:
    if inventory.size() >= inventory_capacity:
        return false
    for i in range(safe_storage.size()):
        if safe_storage[i].id == item_id:
            inventory.append(safe_storage.pop_at(i))
            inventory_changed.emit()
            return true
    return false

func set_chapter(value: int) -> void:
    chapter = clampi(value, 1, 7)
    if not unlocked_chapters.has(chapter):
        unlocked_chapters.append(chapter)
    chapter_changed.emit(chapter)
