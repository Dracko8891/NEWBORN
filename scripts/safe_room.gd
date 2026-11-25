extends Area3D
class_name NewbornSafeRoom

@export var room_label: String = "Sala Segura"
var occupant_count: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		occupant_count += 1
		body.set("in_safe_room", true)
		GameState.notification_requested.emit("Zona segura: Newborn não pode entrar")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		occupant_count = maxi(0, occupant_count - 1)
		body.set("in_safe_room", false)

func interact(player: Node) -> void:
	if not player.is_in_group("player") or not bool(player.get("in_safe_room")):
		return
	if GameState.inventory.is_empty():
		var restored := GameState.retrieve_all_items()
		GameState.notification_requested.emit("Itens retirados do armazenamento: %d" % restored)
	else:
		var stored := GameState.store_all_items()
		GameState.notification_requested.emit("Itens guardados: %d" % stored)
