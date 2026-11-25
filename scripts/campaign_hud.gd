extends CanvasLayer
## In-world campaign context: chapter identity, active objective and progress.

const Campaign = preload("res://systems/campaign_data.gd")

var chapter_label: Label
var objective_label: Label
var progress_label: Label
var message_label: Label

func _ready() -> void:
	layer = 25
	_build_interface()
	CampaignDirector.chapter_started.connect(_on_chapter_started)
	CampaignDirector.objective_updated.connect(_on_objective_updated)
	CampaignDirector.campaign_message.connect(_show_message)
	GameState.notification_requested.connect(_show_message)
	_refresh_current()

func _build_interface() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(390, 0)
	panel.size = Vector2(390, 150)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	chapter_label = Label.new()
	chapter_label.add_theme_font_size_override("font_size", 19)
	chapter_label.text = "PROTOCOLO NEWBORN"
	column.add_child(chapter_label)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.modulate = Color(0.35, 0.9, 0.88)
	column.add_child(progress_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(360, 52)
	column.add_child(objective_label)
	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.modulate = Color(1.0, 0.78, 0.35)
	column.add_child(message_label)

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
