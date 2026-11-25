extends CanvasLayer
## In-world campaign context: chapter identity, active objective and progress.

const Campaign = preload("res://systems/campaign_data.gd")

var chapter_label: Label
var objective_label: Label
var progress_label: Label
var message_label: Label
var holographic_map: Control

func _ready() -> void:
	layer = 25
	_build_interface()
	holographic_map = Control.new()
	holographic_map.name = "HolographicMap"
	holographic_map.set_script(load("res://scripts/holographic_map.gd"))
	add_child(holographic_map)
	CampaignDirector.chapter_started.connect(_on_chapter_started)
	CampaignDirector.objective_updated.connect(_on_objective_updated)
	CampaignDirector.campaign_message.connect(_show_message)
	CampaignDirector.chapter_completed.connect(_on_chapter_completed)
	GameState.notification_requested.connect(_show_message)
	_refresh_current()

func _build_interface() -> void:
	var panel := PanelContainer.new()
	panel.name = "MinimalDiegeticHUD"
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(310, 0)
	panel.size = Vector2(310, 112)
	panel.modulate = Color(1, 1, 1, 0.78)
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(0.012, 0.022, 0.028, 0.10)
	glass.border_color = Color(0.35, 0.62, 0.65, 0.10)
	glass.set_border_width_all(1)
	glass.set_corner_radius_all(3)
	glass.content_margin_left = 8
	glass.content_margin_right = 8
	glass.content_margin_top = 4
	glass.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", glass)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	chapter_label = Label.new()
	chapter_label.add_theme_font_size_override("font_size", 17)
	chapter_label.text = "PROTOCOLO NEWBORN"
	column.add_child(chapter_label)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.modulate = Color(0.35, 0.9, 0.88, 0.8)
	column.add_child(progress_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(330, 46)
	column.add_child(objective_label)
	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.modulate = Color(1.0, 0.78, 0.35, 0.85)
	column.add_child(message_label)
	var map_button := Button.new()
	map_button.text = "PADD  [M]"
	map_button.flat = true
	map_button.modulate = Color(0.68, 0.82, 0.84, 0.68)
	map_button.pressed.connect(_toggle_map)
	column.add_child(map_button)
	var credits_button := Button.new()
	credits_button.text = "CRÉDITOS"
	credits_button.flat = true
	credits_button.modulate = Color(0.68, 0.82, 0.84, 0.68)
	credits_button.pressed.connect(_show_credits)
	column.add_child(credits_button)

func _refresh_current() -> void:
	var chapter := GameState.chapter
	var data := Campaign.get_chapter(chapter)
	if data.is_empty():
		return
	chapter_label.text = "SETOR %02d  |  %s" % [chapter, str(data.get("sector", "SETOR"))]
	var objectives: Array = data.get("objectives", [])
	var current := clampi(CampaignDirector.current_objective, 0, objectives.size())
	progress_label.text = "PROTOCOLO %d/7  •  OBJETIVO %d/%d" % [chapter, mini(current + 1, objectives.size()), objectives.size()]
	if current < objectives.size():
		objective_label.text = "OBJETIVO ATUAL\n" + str(objectives[current])
	else:
		objective_label.text = "TODOS OS OBJETIVOS CONCLUÍDOS"

func _on_chapter_started(_chapter: int, _title: String) -> void:
	_refresh_current()

func _on_objective_updated(chapter: int, objective_index: int, objective_text: String) -> void:
	var data := Campaign.get_chapter(chapter)
	var objectives: Array = data.get("objectives", [])
	chapter_label.text = "SETOR %02d  |  %s" % [chapter, str(data.get("sector", "SETOR"))]
	progress_label.text = "PROTOCOLO %d/7  •  OBJETIVO %d/%d" % [chapter, objective_index + 1, objectives.size()]
	objective_label.text = "OBJETIVO ATUAL\n" + objective_text

func _show_message(message: String) -> void:
	message_label.text = message
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(message_label) and message_label.text == message:
			message_label.text = ""
	)

func _on_chapter_completed(chapter: int) -> void:
	if chapter == 7:
		chapter_label.text = "PROTOCOLO ENCERRADO"
		progress_label.text = "CAMPANHA 100% — SETE CAPÍTULOS"
		objective_label.text = "FIM\nA escotilha se fecha. O Newborn alcançou a superfície. O sinal de Clara desaparece."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_map()
		get_viewport().set_input_as_handled()

func _toggle_map() -> void:
	if holographic_map != null and holographic_map.has_method("toggle_map"):
		holographic_map.toggle_map()

func _show_credits() -> void:
	var credits := [
		"IDEIA ORIGINAL: Nycollas Gabriel",
		"CRIAÇÃO: Damião Bruno",
		"CONCEPÇÃO DO UNIVERSO: Damião Bruno",
		"CRIAÇÃO DO NEWBORN: Damião Bruno",
		"CRIAÇÃO DOS PERSONAGENS: Damião Bruno",
		"INTERPRETAÇÃO DO ALIEN FANTASIADO: Damião Bruno",
		"ATUAÇÃO: Damião Bruno",
		"VOZES: Damião Bruno",
		"NARRAÇÃO: Damião Bruno",
		"DIREÇÃO DE VOZ: Damião Bruno",
		"SONORIZAÇÃO: Damião Bruno",
	"EFEITOS SONOROS: Damião Bruno",
		"TRILHA SONORA: Damião Bruno",
		"CRIAÇÃO ARTÍSTICA: Damião Bruno",
		"DIREÇÃO DE ARTE: Damião Bruno",
		"DIREÇÃO VISUAL: Damião Bruno",
		"DESIGN DE CRIATURAS: Damião Bruno",
		"DESIGN DE AMBIENTES: Damião Bruno",
		"DESIGN DE FASES: Damião Bruno",
		"DESIGN DE GAMEPLAY: Damião Bruno",
		"CRIAÇÃO DOS PUZZLES: Damião Bruno",
		"ROTEIRO: Damião Bruno",
		"DIÁLOGOS: Damião Bruno",
		"CONCEPÇÃO DO TERROR: Damião Bruno",
		"PROGRAMAÇÃO: Damião Bruno",
		"INTEGRAÇÃO: Damião Bruno",
		"PRODUÇÃO: Damião Bruno",
		"IDEALIZAÇÃO E DIREÇÃO DO PROJETO: Damião Bruno",
		"",
		"RECURSOS DE TERCEIROS: manter os créditos e licenças dos respectivos autores."
	]
	var dialog := AcceptDialog.new()
	dialog.title = "CRÉDITOS — PROTOCOLO NEWBORN"
	dialog.dialog_text = "\n".join(credits)
	dialog.min_size = Vector2i(560, 680)
	add_child(dialog)
	dialog.popup_centered()
