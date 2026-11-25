extends Area3D
class_name NewbornHideSpot

@export var spot_label: String = "Armário"
var occupant: Node = null

func interact(player: Node) -> void:
	if occupant != null and not is_instance_valid(occupant):
		occupant = null
	if occupant == player:
		if player.has_method("leave_hide_spot"):
			player.leave_hide_spot()
		occupant = null
		GameState.notification_requested.emit("Você saiu do esconderijo")
		return
	if occupant != null:
		GameState.notification_requested.emit("Esconderijo ocupado")
		return
	if player.is_in_group("player") and bool(player.get("in_safe_room")):
		GameState.notification_requested.emit("Você já está em uma zona segura")
		return
	if player.has_method("enter_hide_spot"):
		player.enter_hide_spot()
		occupant = player
		GameState.notification_requested.emit("Escondido em " + spot_label + ": permaneça imóvel")
