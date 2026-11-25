extends Area3D
class_name NewbornSafeStorageTerminal

var ui_layer: CanvasLayer
var panel: PanelContainer
var inventory_list: VBoxContainer
var storage_list: VBoxContainer
var status_label: Label
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var is_open: bool = false

func _ready() -> void:
	_build_interface()
	GameState.inventory_changed.connect(_refresh_lists)

func interact(player: Node) -> void:
	if not player.is_in_group("player") or not bool(player.get("in_safe_room")):
		GameState.notification_requested.emit("Acesse o terminal dentro da sala segura")
		return
	open_terminal()

func open_terminal() -> void:
	if is_open:
		return
	is_open = true
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true
	status_label.text = "ARMAZENAMENTO LOCAL // ACESSO AUTORIZADO"
	_refresh_lists()

func close_terminal() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	Input.mouse_mode = previous_mouse_mode

func _input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		close_terminal()
		get_viewport().set_input_as_handled()

func _build_interface() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "SafeStorageInterface"
	ui_layer.layer = 30
	add_child(ui_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.035, 0.045, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.name = "StoragePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-440, -285)
	panel.size = Vector2(880, 570)
	panel.custom_minimum_size = Vector2(880, 570)
	ui_layer.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "VANGUARD-7  //  TERMINAL DE ARMAZENAMENTO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "FECHAR  [ESC]"
	close_button.pressed.connect(close_terminal)
	header.add_child(close_button)

	status_label = Label.new()
	status_label.text = "ARMAZENAMENTO LOCAL"
	status_label.add_theme_color_override("font_color", Color(0.35, 0.9, 0.88))
	outer.add_child(status_label)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	outer.add_child(columns)

	var inventory_column := VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(inventory_column)
	var inventory_title := Label.new()
	inventory_title.text = "INVENTÁRIO DO ARTHUR"
	inventory_title.add_theme_font_size_override("font_size", 16)
	inventory_column.add_child(inventory_title)
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_column.add_child(inventory_scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.add_child(inventory_list)
	var store_all := Button.new()
	store_all.text = "GUARDAR TODOS"
	store_all.pressed.connect(_store_all)
	inventory_column.add_child(store_all)

	var storage_column := VBoxContainer.new()
	storage_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(storage_column)
	var storage_title := Label.new()
	storage_title.text = "COFRE DA SALA SEGURA"
	storage_title.add_theme_font_size_override("font_size", 16)
	storage_column.add_child(storage_title)
	var storage_scroll := ScrollContainer.new()
	storage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	storage_column.add_child(storage_scroll)
	storage_list = VBoxContainer.new()
	storage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_scroll.add_child(storage_list)
	var retrieve_all := Button.new()
	retrieve_all.text = "RETIRAR ATÉ ENCHER"
	retrieve_all.pressed.connect(_retrieve_all)
	storage_column.add_child(retrieve_all)

	var footer := Label.new()
	footer.text = "SELECIONE UM ITEM PARA TRANSFERÊNCIA INDIVIDUAL  //  DADOS SALVOS AUTOMATICAMENTE"
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(footer)
	panel.visible = false

func _refresh_lists() -> void:
	if not is_instance_valid(inventory_list) or not is_instance_valid(storage_list):
		return
	_clear_rows(inventory_list)
	_clear_rows(storage_list)
	if GameState.inventory.is_empty():
		_add_empty_label(inventory_list, "Inventário vazio")
	else:
		for slot in GameState.inventory:
			_add_item_row(inventory_list, slot, true)
	if GameState.safe_storage.is_empty():
		_add_empty_label(storage_list, "Armazenamento vazio")
	else:
		for slot in GameState.safe_storage:
			_add_item_row(storage_list, slot, false)

func _clear_rows(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _add_empty_label(container: VBoxContainer, message: String) -> void:
	var label := Label.new()
	label.text = message
	label.modulate = Color(0.65, 0.75, 0.78)
	container.add_child(label)

func _add_item_row(container: VBoxContainer, slot: Dictionary, is_inventory: bool) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(row)
	var item_label := Label.new()
	var count := maxi(1, int(slot.get("count", 1)))
	item_label.text = "%s  x%d" % [str(slot.get("name", slot.get("id", "Item"))), count]
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(item_label)
	var action := Button.new()
	action.text = "GUARDAR" if is_inventory else "RETIRAR"
	action.disabled = not is_inventory and GameState.inventory.size() >= GameState.inventory_capacity
	var item_id := str(slot.get("id", ""))
	if is_inventory:
		action.pressed.connect(_store_one.bind(item_id))
	else:
		action.pressed.connect(_retrieve_one.bind(item_id))
	row.add_child(action)

func _store_one(item_id: String) -> void:
	if GameState.store_item(item_id):
		status_label.text = "ITEM ARMAZENADO: " + item_id
	else:
		status_label.text = "NÃO FOI POSSÍVEL ARMAZENAR O ITEM"
	_refresh_lists()

func _retrieve_one(item_id: String) -> void:
	if GameState.retrieve_item(item_id):
		status_label.text = "ITEM RECUPERADO: " + item_id
	else:
		status_label.text = "SEM ESPAÇO NO INVENTÁRIO"
	_refresh_lists()

func _store_all() -> void:
	var moved := GameState.store_all_items()
	status_label.text = "ITENS ARMAZENADOS: %d" % moved
	_refresh_lists()

func _retrieve_all() -> void:
	var moved := GameState.retrieve_all_items()
	status_label.text = "ITENS RECUPERADOS: %d" % moved
	_refresh_lists()
