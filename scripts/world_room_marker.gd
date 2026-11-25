extends Area3D
## Physical trigger that reports an exact authored room zone to the map.
@export var room_id := ""
@export var room_name := ""

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D) or body.name != "Player":
		return
	GameState.puzzle_flags["map_current_room_id"] = room_id
	GameState.puzzle_flags["map_current_room_name"] = room_name
	GameState.puzzle_flags["map_discovered_rooms"] = _mark_discovered(GameState.puzzle_flags.get("map_discovered_rooms", {}))
	if GameState.has_method("save_game"):
		GameState.save_game()

func _mark_discovered(value: Variant) -> Dictionary:
	var discovered: Dictionary = value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
	discovered[room_id] = true
	return discovered
