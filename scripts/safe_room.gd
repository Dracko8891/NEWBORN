extends Area3D
class_name NewbornSafeRoomZone

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.set("in_safe_room", true)
		GameState.notification_requested.emit("Zona segura: Newborn não pode entrar")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.set("in_safe_room", false)
