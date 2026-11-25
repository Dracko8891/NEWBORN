extends Area3D
var active := false
var layer: CanvasLayer

func interact(player: Node) -> void:
	if active or not player.is_in_group("player"):
		return
	active = true
	var ui := CanvasLayer.new()
	ui.name = "EpiloguePADDUI"
	ui.layer = 60
	get_tree().root.add_child(ui)
	layer = ui
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.008, 0.016, 0.028, 0.9)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(backdrop)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270, -190)
	panel.size = Vector2(540, 380)
	panel.custom_minimum_size = Vector2(540, 380)
	ui.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "PADD // REGISTRO TÉRMICO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var report := Label.new()
	report.text = "ÚLTIMA LEITURA DO COMPLEXO VANGUARD-7\n\nAs grades térmicas externas permanecem abertas. O protocolo de contenção não foi concluído.\n\nUma segunda assinatura térmica foi detectada junto à chaminé da montanha. O padrão respiratório coincide com o de Arthur Vance."
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.custom_minimum_size = Vector2(500, 230)
	column.add_child(report)
	var close := Button.new()
	close.text = "FECHAR REGISTRO"
	close.custom_minimum_size = Vector2(0, 52)
	close.pressed.connect(_close_report)
	column.add_child(close)

func _close_report() -> void:
	if is_instance_valid(layer):
		layer.queue_free()
	active = false
	GameState.set_flag("epilogue_padd_read")
	GameState.save_game()
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("reveal_eyes"):
		scene.reveal_eyes()
