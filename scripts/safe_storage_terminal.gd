extends Area3D
class_name NewbornSafeStorageTerminal

func interact(player: Node) -> void:
	if not player.is_in_group("player") or not bool(player.get("in_safe_room")):
		GameState.notification_requested.emit("Acesse o terminal dentro da sala segura")
		return
	if GameState.inventory.is_empty():
		var restored := GameState.retrieve_all_items()
		GameState.notification_requested.emit("Itens retirados do armazenamento: %d" % restored)
	else:
		var stored := GameState.store_all_items()
		GameState.notification_requested.emit("Itens guardados: %d" % stored)

func store_item(item_id: String) -> bool:
	return GameState.store_item(item_id)

func retrieve_item(item_id: String) -> bool:
	return GameState.retrieve_item(item_id)
