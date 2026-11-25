extends Area3D
class_name NewbornPuzzleStation

@export var puzzle_id: String = ""
@export var title: String = "TERMINAL DE OPERAÇÃO"
@export_multiline var instructions: String = "Insira a sequência correta."
@export var choices: Array[String] = []
@export var solution: Array[String] = []
@export var success_flag: String = ""

var entered: Array[String] = []
var layer: CanvasLayer
var status_label: Label
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
	status_label.text = "ENTRADA: " + " → ".join(entered)
	if entered.size() == solution.size():
		if _commit_puzzle():
			status_label.text = "SISTEMA RESTAURADO"
			GameState.notification_requested.emit("Puzzle concluído: " + title)
			get_tree().create_timer(0.8).timeout.connect(_close)
		else:
			entered.clear()
			status_label.text = "FALHA DE VALIDAÇÃO — VERIFIQUE OS RECURSOS"

func _commit_puzzle() -> bool:
	var sequence: Array[String] = entered.duplicate()
	var success := false
	match puzzle_id:
		"medical_pin":
			success = PuzzleSystem.submit_pin("".join(sequence))
		"medical_relays":
			success = PuzzleSystem.submit_relays(sequence)
		"dna_matrix":
			success = PuzzleSystem.submit_dna_matrix(sequence)
		"therapy_melody":
			success = PuzzleSystem.submit_melody(sequence)
		"genesis_valves":
			success = PuzzleSystem.submit_valves(sequence)
		"reactor_shutdown":
			success = PuzzleSystem.submit_reactor_shutdown(sequence)
		"omega_biochips":
			success = PuzzleSystem.submit_biochips(sequence)
		"hangar_couplings":
			for i in range(1, 4):
				PuzzleSystem.activate_hydraulic_coupling(i)
			GameState.set_flag("hangar_couplings_complete")
			success = true
		"set_flag":
			GameState.set_flag(success_flag)
			GameState.save_game()
			success = true
		_:
			push_warning("Unknown puzzle station: " + puzzle_id)
	return success

func _close() -> void:
	active = false
	if is_instance_valid(layer):
		layer.queue_free()
