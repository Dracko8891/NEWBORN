extends Area3D
class_name NewbornItemPickup

@export var item_id: String = ""
@export var display_name: String = "Item"
@export var is_consumable: bool = false
# Set a stable ID per placed pickup when the same item appears more than once.
@export var pickup_id: String = ""

var collected: bool = false

func _ready() -> void:
	if item_id.is_empty():
		push_warning("NewbornItemPickup sem item_id: " + str(get_path()))
		return
	if _is_already_collected():
		collected = true
		queue_free()

func interact(_player: Node) -> void:
	if collected or item_id.is_empty():
		return
	if _is_already_collected():
		collected = true
		queue_free()
		return
	if GameState.add_item(item_id, display_name, is_consumable):
		collected = true
		GameState.collected_flags[_collection_key()] = true
		GameState.notification_requested.emit(display_name + " recolhido")
		GameState.save_game()
		queue_free()

func _collection_key() -> String:
	var stable_id := pickup_id.strip_edges()
	if stable_id.is_empty():
		stable_id = str(get_path())
	return "chapter_%d:%s" % [GameState.chapter, stable_id]

func _is_already_collected() -> bool:
	return bool(GameState.collected_flags.get(_collection_key(), false))
