extends Area3D
class_name NewbornItemPickup

@export var item_id: String = ""
@export var display_name: String = "Item"
@export var is_consumable: bool = false

var collected: bool = false

func interact(_player: Node) -> void:
	if collected:
		return
	if GameState.collected_flags.get(item_id, false):
		queue_free()
		return
	if GameState.add_item(item_id, display_name, is_consumable):
		collected = true
		GameState.collected_flags[item_id] = true
		GameState.notification_requested.emit(display_name + " recolhido")
		queue_free()
