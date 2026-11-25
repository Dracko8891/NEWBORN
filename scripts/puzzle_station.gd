extends Area3D
class_name NewbornPuzzleStation

@export var puzzle_id: String = ""
@export var title: String = "TERMINAL DE OPERAÇÃO"
@export_multiline var instructions: String = "Insira a sequência correta."
@export var choices: Array[String] = []
@export var solution: Array[String] = []
@export var success_flag: String = ""
@export var required_items: Dictionary = {}

var entered: Array[String] = []
var layer: CanvasLayer
var status_label: Label
var countdown_timer: Timer
var countdown_remaining: float = 0.0
var countdown_action: String = ""
var active: bool = false

func interact(player: Node) -> void:
	if not player.is_in_group("player") or active:
		return
	if player.has_method("is_hidden") and player.is_hidden():
		return
	_open()

func _open() -> void:
	active = true
	entered.clear()
	layer = CanvasLayer.new()
	layer.layer = 40
	get_tree().current_scene.add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.01, 0.025, 0.035, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-230, -190)
	panel.size = Vector2(460, 380)
	panel.custom_minimum_size = Vector2(460, 380)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var detail := Label.new()
	detail.text = instructions
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	status_label = Label.new()
	status_label.text = "ENTRADA: —"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)
	for token in choices:
		var button := Button.new()
		button.text = token.to_upper()
		button.custom_minimum_size = Vector2(180, 48)
		button.pressed.connect(_submit_token.bind(token))
		grid.add_child(button)
	var close := Button.new()
	close.text = "CANCELAR"
	close.pressed.connect(_close)
	column.add_child(close)

func _submit_token(token: String) -> void:
	if not active:
		return
	entered.append(token)
	if entered.size() > solution.size() or entered[entered.size() - 1] != solution[entered.size() - 1]:
		entered.clear()
		status_label.text = "SEQUÊNCIA INCORRETA — TENTE NOVAMENTE"
		return
	status_label.text = "ENTRADA: " + str(entered)
	if entered.size() == solution.size():
		if _commit_puzzle():
			status_label.text = "SISTEMA RESTAURADO"
			GameState.notification_requested.emit("Puzzle concluído: " + title)
			get_tree().create_timer(0.8).timeout.connect(_close)
		else:
			entered.clear()
			status_label.text = "FALHA DE VALIDAÇÃO — VERIFIQUE OS RECURSOS"

func _commit_puzzle() -> bool:
	for item_id in required_items:
		var amount := maxi(1, int(required_items[item_id]))
		if not GameState.has_item(str(item_id), amount):
			GameState.notification_requested.emit("Recurso necessário: " + str(item_id))
			return false
	var sequence: Array[String] = entered.duplicate()
	var success := false
	match puzzle_id:
		"medical_pin":
			success = PuzzleSystem.submit_pin("".join(sequence))
		"quarters_pin":
			success = PuzzleSystem.submit_quarters_pin("".join(sequence))
		"medical_relays":
			success = PuzzleSystem.submit_relays(sequence)
		"dna_matrix":
			success = PuzzleSystem.submit_dna_matrix(sequence)
		"therapy_melody":
			success = PuzzleSystem.submit_melody(sequence)
		"genesis_valves":
			success = PuzzleSystem.submit_valves(sequence)
		"synthesis_recipe":
			if sequence != ["nitro", "nitro", "acid", "enzyme", "enzyme", "enzyme"]:
				return false
			if not GameState.remove_item("nitro_sterile", 2):
				return false
			if not GameState.remove_item("acid_buffer", 1):
				return false
			if not GameState.remove_item("enzyme", 3):
				return false
			GameState.set_flag("synthesis_compound_created")
			GameState.save_game()
			success = true
		"reactor_shutdown":
			success = PuzzleSystem.submit_reactor_shutdown(sequence)
		"robot_arms":
			success = PuzzleSystem.submit_robot_arms(sequence)
		"omega_biochips":
			success = PuzzleSystem.submit_biochips(sequence)
		"omega_download":
			_start_countdown(75.0, "download")
			success = true
		"omega_siege":
			if sequence != ["north", "east", "south", "west"]:
				return false
			if not GameState.remove_item("battery", 2):
				return false
			_start_countdown(75.0, "siege")
			success = true
		"hangar_couplings":
			if sequence != ["1", "2", "3"]:
				return false
			for i in range(1, 4):
				if not PuzzleSystem.activate_hydraulic_coupling(i):
					return false
			success = bool(GameState.get_flag("hangar_couplings_complete", false))
		"hangar_override":
			success = PuzzleSystem.execute_hangar_override()
		"set_flag":
			if success_flag.is_empty():
				return false
			GameState.set_flag(success_flag)
			if required_items.has("tricorder_upgrade"):
				GameState.set_flag("tricorder_level_2")
			GameState.save_game()
			success = true
		_:
			push_warning("Unknown puzzle station: " + puzzle_id)
	if success:
		for item_id in required_items:
			if bool(GameState.get_flag("consume_puzzle_item_" + str(item_id), false)):
				GameState.remove_item(str(item_id), maxi(1, int(required_items[item_id])))
		GameState.save_game()
	return success


func _start_countdown(duration: float, action: String) -> void:
	if countdown_timer != null and is_instance_valid(countdown_timer):
		countdown_timer.stop()
		countdown_timer.queue_free()
	countdown_action = action
	countdown_remaining = maxf(0.05, duration)
	var label := "DOWNLOAD ÔMEGA" if action == "download" else "CERCO ÔMEGA"
	GameState.notification_requested.emit(label + " iniciado: " + str(int(ceil(countdown_remaining))) + "s")
	countdown_timer = Timer.new()
	countdown_timer.name = "TimedObjectiveTimer"
	countdown_timer.one_shot = true
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)
	_schedule_countdown_tick()

func _schedule_countdown_tick() -> void:
	if countdown_timer == null or not is_instance_valid(countdown_timer):
		return
	countdown_timer.wait_time = minf(1.0, countdown_remaining)
	countdown_timer.start()

func _on_countdown_tick() -> void:
	if not is_inside_tree():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or GameState.health_state == 2 or (player.has_method("is_dead") and player.is_dead()):
		var failed_label := "DOWNLOAD ÔMEGA" if countdown_action == "download" else "CERCO ÔMEGA"
		GameState.notification_requested.emit(failed_label + " interrompido")
		countdown_timer.queue_free()
		countdown_timer = null
		return
	countdown_remaining = maxf(0.0, countdown_remaining - countdown_timer.wait_time)
	var seconds_left := int(ceil(countdown_remaining))
	if seconds_left == 0 or seconds_left % 15 == 0 or seconds_left <= 5:
		var label := "DOWNLOAD ÔMEGA" if countdown_action == "download" else "CERCO ÔMEGA"
		GameState.notification_requested.emit(label + ": " + str(seconds_left) + "s restantes")
	if countdown_remaining <= 0.0:
		if countdown_action == "download":
			PuzzleSystem.complete_omega_download()
			GameState.notification_requested.emit("DOWNLOAD ÔMEGA concluído")
		else:
			PuzzleSystem.survive_omega_siege()
			GameState.notification_requested.emit("CERCO ÔMEGA concluído")
		countdown_timer.queue_free()
		countdown_timer = null
		return
	_schedule_countdown_tick()

func _close() -> void:
	active = false
	if is_instance_valid(layer):
		layer.queue_free()
