extends Area3D
## Physical trigger that reports an exact authored room zone to the map.
@export var room_id := ""
@export var room_name := ""

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not _is_player(body):
		return
	GameState.puzzle_flags["map_current_room_id"] = room_id
	GameState.puzzle_flags["map_current_room_name"] = room_name
	GameState.puzzle_flags["map_current_room_marker_id"] = get_instance_id()
	GameState.puzzle_flags["map_discovered_rooms"] = _mark_discovered(GameState.puzzle_flags.get("map_discovered_rooms", {}))
	_save_map_state()

func _on_body_exited(body: Node3D) -> void:
	if not _is_player(body):
		return
	if int(GameState.puzzle_flags.get("map_current_room_marker_id", -1)) != get_instance_id():
		return
	GameState.puzzle_flags["map_current_room_id"] = ""
	GameState.puzzle_flags["map_current_room_name"] = "LOCALIZAÇÃO NÃO CONFIRMADA"
	GameState.puzzle_flags.erase("map_current_room_marker_id")
	_save_map_state()

func _is_player(body: Node3D) -> bool:
	return body is CharacterBody3D and body.name == "Player"

func _save_map_state() -> void:
	if GameState.has_method("save_game"):
		GameState.save_game()

func _mark_discovered(value: Variant) -> Dictionary:
	var discovered: Dictionary = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
	discovered[room_id] = true
	return discovered
