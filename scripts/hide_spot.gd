extends Area3D
class_name NewbornHideSpot

@export var spot_label: String = "Armário"
var occupant: Node = null

func interact(player: Node) -> void:
	if occupant == player:
		if player.has_method("leave_hide_spot"):
			player.leave_hide_spot()
		occupant = null
		return
	if occupant != null:
		GameState.notification_requested.emit("Esconderijo ocupado")
		return
	if player.has_method("enter_hide_spot"):
		player.enter_hide_spot()
		occupant = player
		GameState.notification_requested.emit("Escondido: segure a respiração e aguarde")
