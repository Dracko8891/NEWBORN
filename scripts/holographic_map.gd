extends Control
## Interactive holographic schematic. Position is read from the live player transform;
## room discovery is persisted in GameState.puzzle_flags.
const MapData = preload("res://systems/world_map_data.gd")

const CYAN := Color(0.25, 0.95, 0.92, 1.0)
const DIM_CYAN := Color(0.12, 0.42, 0.46, 0.85)
const AMBER := Color(1.0, 0.68, 0.25, 1.0)
const DARK := Color(0.015, 0.055, 0.075, 0.96)

var _map_canvas: Control
var _room_list: VBoxContainer
var _position_label: Label
var _detail_label: Label
var _selected_room := ""
var _current_room := ""
var _discovered: Dictionary = {}
var _chapter := 1
var _refresh_elapsed := 0.0
var _room_points: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_discovery()
	_build_ui()
	set_process(true)

func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed < 0.25:
		return
	_refresh_elapsed = 0.0
	_update_player_position()

func toggle_map() -> void:
	visible = not visible
	if visible:
		_update_player_position()
		_refresh_room_list()
		_map_canvas.queue_redraw()

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.025, 0.04, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.06
	panel.anchor_top = 0.07
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.93
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "VANGUARD-7  //  MAPA HOLOGRÁFICO"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "FECHAR  [M]"
	close.pressed.connect(toggle_map)
	header.add_child(close)

	_position_label = Label.new()
	_position_label.add_theme_color_override("font_color", AMBER)
	_position_label.add_theme_font_size_override("font_size", 15)
	root.add_child(_position_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_map_canvas = Control.new()
	_map_canvas.custom_minimum_size = Vector2(500, 360)
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_canvas.draw.connect(_draw_map)
	_map_canvas.gui_input.connect(_on_map_input)
	body.add_child(_map_canvas)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(250, 0)
	body.add_child(side)
	var legend := Label.new()
	legend.text = "SETOR / SALAS DESCOBERTAS"
	legend.add_theme_color_override("font_color", CYAN)
	side.add_child(legend)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(scroll)
	_room_list = VBoxContainer.new()
	_room_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_room_list)
	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(230, 60)
	side.add_child(_detail_label)

	var footer := Label.new()
	footer.text = "TOQUE NOS PONTOS PARA INSPECIONAR  •  POSIÇÃO ATUAL ATUALIZADA EM TEMPO REAL"
	footer.add_theme_color_override("font_color", DIM_CYAN)
	root.add_child(footer)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = DARK
	style.border_color = CYAN
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _load_discovery() -> void:
	var saved: Variant = GameState.puzzle_flags.get("map_discovered_rooms", {})
	if typeof(saved) == TYPE_DICTIONARY:
		_discovered = saved.duplicate(true)

func _save_discovery() -> void:
	GameState.puzzle_flags["map_discovered_rooms"] = _discovered.duplicate(true)
	GameState.save_game()

func _update_player_position() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_chapter = clampi(GameState.chapter, 1, 7)
	var p: Vector3 = player.global_position
	var room_id := _resolve_room(_chapter, p)
	if room_id != _current_room:
		_current_room = room_id
		if not room_id.is_empty() and not bool(_discovered.get(room_id, false)):
			_discovered[room_id] = true
			_save_discovery()
			_refresh_room_list()
			_map_canvas.queue_redraw()
	var room := MapData.get_room(room_id)
	var room_name := str(room.get("name", "Setor não catalogado"))
	_position_label.text = "POSIÇÃO DO OPERADOR: %s  |  X %.1f  Z %.1f" % [room_name.to_upper(), p.x, p.z]
	if visible:
		_map_canvas.queue_redraw()

func _resolve_room(chapter: int, p: Vector3) -> String:
	var rooms: Array = []
	for room in MapData.get_rooms():
		if int(room.get("chapter", 0)) == chapter:
			rooms.append(room)
	if rooms.is_empty():
		return ""
	# The current level is a corridor with physical side annexes. Resolve those
	# annexes first, then use corridor depth to identify the nearest authored zone.
	if absf(p.x) > 4.2 and p.z > -8.0 and p.z < 2.0:
		return str(rooms[mini(rooms.size() - 1, 1)].get("id", ""))
	if p.z > 14.0:
		return str(rooms[0].get("id", ""))
	if p.z < -24.0:
		return str(rooms[rooms.size() - 1].get("id", ""))
	if p.z < -8.0:
		return str(rooms[mini(rooms.size() - 1, 2)].get("id", ""))
	return str(rooms[mini(1, rooms.size() - 1)].get("id", ""))

func _refresh_room_list() -> void:
	if _room_list == null:
		return
	for child in _room_list.get_children():
		child.queue_free()
	for room in MapData.get_rooms():
		if int(room.get("chapter", 0)) != _chapter or not bool(_discovered.get(str(room.id), false)):
			continue
		var button := Button.new()
		button.text = ("▶ " if str(room.id) == _current_room else "• ") + str(room.name)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_room.bind(str(room.id)))
		_room_list.add_child(button)

func _select_room(room_id: String) -> void:
	_selected_room = room_id
	var room := MapData.get_room(room_id)
	_detail_label.text = "%s\n%s\n%s" % [str(room.get("name", "")), str(room.get("sector", "")), "SUA POSIÇÃO" if room_id == _current_room else "LOCAL JÁ EXPLORADO"]
	_map_canvas.queue_redraw()

func _draw_map() -> void:
	if _map_canvas == null:
		return
	var rooms: Array = []
	for room in MapData.get_rooms():
		if int(room.get("chapter", 0)) == _chapter:
			rooms.append(room)
	if rooms.is_empty():
		return
	_room_points.clear()
	var w := _map_canvas.size.x
	var h := _map_canvas.size.y
	var cols := 2
	for i in range(rooms.size()):
		var col := i % cols
		var row := int(i / cols)
		var rows := ceili(float(rooms.size()) / float(cols))
		var point := Vector2(w * (0.28 if col == 0 else 0.72), h * (float(row + 1) / float(rows + 1)))
		_room_points[str(rooms[i].id)] = point
	for edge in MapData.get_connections():
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if not _room_points.has(from_id) or not _room_points.has(to_id):
			continue
		var known := bool(_discovered.get(from_id, false)) and bool(_discovered.get(to_id, false))
		_map_canvas.draw_line(_room_points[from_id], _room_points[to_id], CYAN if known else DIM_CYAN, 3.0 if known else 1.5, true)
	for room in rooms:
		var id := str(room.id)
		var point: Vector2 = _room_points[id]
		var known := bool(_discovered.get(id, false))
		var is_current := id == _current_room
		var color := AMBER if is_current else (CYAN if known else DIM_CYAN)
		_map_canvas.draw_circle(point, 13.0 if is_current else 9.0, color)
		_map_canvas.draw_arc(point, 17.0 if is_current else 12.0, 0.0, TAU, 32, color, 2.0, true)
		if known:
			_map_canvas.draw_string(ThemeDB.fallback_font, point + Vector2(18, 5), str(room.name), HORIZONTAL_ALIGNMENT_LEFT, 220, 13, color)
		else:
			_map_canvas.draw_string(ThemeDB.fallback_font, point + Vector2(16, 5), "ÁREA NÃO MAPEADA", HORIZONTAL_ALIGNMENT_LEFT, 180, 11, DIM_CYAN)

func _on_map_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for room_id in _room_points:
		if event.position.distance_to(_room_points[room_id]) <= 22.0:
			if bool(_discovered.get(room_id, false)):
				_select_room(room_id)
			return
