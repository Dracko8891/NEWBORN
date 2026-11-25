extends Node
## Developer telemetry: sampled panic context and discrete gameplay/resource events.
## Heart rate is a gameplay estimate, not a physiological measurement.

const LOG_PATH := "user://panic_events.csv"
var _player: Node3D
var _last_panic_bucket := -1
var _last_resource_snapshot := ""

func _ready() -> void:
	add_to_group("panic_event_recorder")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if not FileAccess.file_exists(LOG_PATH):
		var initial := FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if initial != null:
			initial.store_line("timestamp,chapter,event,panic,estimated_bpm,enemy_distance_m,enemy_state,health_state,flashlight_seconds,stamina,inventory_count,detail")
			initial.close()
	print("[PANIC] Telemetria iniciada. CSV: ", LOG_PATH)

func record_sample(panic: float, bpm: int, enemy_distance: float, enemy_state: int, health: int) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	var bucket := int(floor(clampf(panic, 0.0, 1.0) * 10.0))
	if bucket != _last_panic_bucket:
		_last_panic_bucket = bucket
		record_event("PANIC_LEVEL", "bucket_%02d" % bucket, panic, bpm, enemy_distance, enemy_state, health)
	else:
		_write_row("SAMPLE", "", panic, bpm, enemy_distance, enemy_state, health)
		print("[PANIC] %.0f%% | FC simulada %d BPM | Newborn %.1fm | IA %s | vida %d" % [panic * 100.0, bpm, enemy_distance, _state_name(enemy_state), health])

func record_resource(resource_name: String, remaining_count: int = -1) -> void:
	var panic := 0.0
	var bpm := 72
	var distance := 100.0
	var state := -1
	var health := 0
	if is_instance_valid(_player):
		var game_state := get_node_or_null("/root/GameState")
		health = int(game_state.get("health_state")) if game_state != null else 0
		distance = _enemy_distance()
		state = _enemy_state()
		panic = clampf(1.0 - distance / 14.0, 0.0, 1.0) * 0.78 + float(health) * 0.11
		bpm = int(round(72.0 + panic * 72.0 + float(health) * 7.0))
	record_event("RESOURCE_USED", resource_name + "|remaining=" + str(remaining_count), panic, bpm, distance, state, health)

func record_event(event_name: String, detail: String, panic: float, bpm: int, enemy_distance: float, enemy_state: int, health: int) -> void:
	_write_row(event_name, detail, panic, bpm, enemy_distance, enemy_state, health)
	print_rich("[color=orange][PANIC EVENT][/color] %s | %s | panic %.0f%% | FC~%d BPM | Newborn %.1fm | %s" % [event_name, detail, panic * 100.0, bpm, enemy_distance, _state_name(enemy_state)])

func _write_row(event_name: String, detail: String, panic: float, bpm: int, enemy_distance: float, enemy_state: int, health: int) -> void:
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE_READ)
	if file == null:
		push_warning("Não foi possível gravar telemetry CSV: " + LOG_PATH)
		return
	file.seek_end()
	var chapter := int(get_node_or_null("/root/GameState").get("chapter")) if get_node_or_null("/root/GameState") != null else 0
	var flashlight := float(_player.get("flashlight_charge")) if is_instance_valid(_player) else 0.0
	var stamina := float(_player.get("stamina")) if is_instance_valid(_player) else 0.0
	var game_state := get_node_or_null("/root/GameState")
	var inventory_count := int(game_state.get("inventory").size()) if game_state != null else 0
	file.store_line("%s,%d,%s,%.3f,%d,%.2f,%s,%d,%.1f,%.1f,%d,%s" % [Time.get_datetime_string_from_system(), chapter, event_name, panic, bpm, enemy_distance, _state_name(enemy_state), health, flashlight, stamina, inventory_count, detail.replace(",", ";")])
	file.close()

func _enemy_distance() -> float:
	var enemy := get_tree().get_first_node_in_group("noise_listeners") as Node3D
	return _player.global_position.distance_to(enemy.global_position) if is_instance_valid(enemy) and is_instance_valid(_player) else 100.0

func _enemy_state() -> int:
	var enemy := get_tree().get_first_node_in_group("noise_listeners")
	return int(enemy.get("state")) if enemy != null and enemy.get("state") != null else -1

func _state_name(state: int) -> String:
	match state:
		0: return "OBSERVE"
		1: return "PATROL"
		2: return "INVESTIGATE"
		3: return "HUNT"
		4: return "STUNNED"
		5: return "MIMIC_AMBUSH"
		_: return "UNKNOWN"
