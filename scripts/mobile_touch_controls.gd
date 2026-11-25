extends Control
## Landscape touch controls with saved sensitivity sliders and animated feedback.

var joystick_finger := -1
var look_finger := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var active_buttons: Dictionary = {}
var button_rects: Dictionary = {}
var button_scales: Dictionary = {}
var settings_panel: PanelContainer
var look_slider: HSlider
var movement_slider: HSlider
var look_value_label: Label
var movement_value_label: Label

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = OS.has_feature("mobile")
	z_index = 100
	_rebuild_button_rects()
	_build_sensitivity_ui()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild_button_rects()
		_position_sensitivity_ui()
		queue_redraw()

func _rebuild_button_rects() -> void:
	var s := get_viewport_rect().size
	var d := clampf(minf(s.x, s.y) * 0.105, 48.0, 80.0)
	button_rects = {
		"interact": Rect2(Vector2(s.x - d * 2.35, s.y - d * 2.25), Vector2(d, d)),
		"crouch": Rect2(Vector2(s.x - d * 1.2, s.y - d * 2.25), Vector2(d, d)),
		"sprint": Rect2(Vector2(s.x - d * 2.35, s.y - d * 1.1), Vector2(d, d)),
		"flashlight": Rect2(Vector2(s.x - d * 1.2, s.y - d * 1.1), Vector2(d, d)),
		"medical": Rect2(Vector2(s.x - d * 2.35, s.y - d * 3.4), Vector2(d, d)),
		"battery": Rect2(Vector2(s.x - d * 1.2, s.y - d * 3.4), Vector2(d, d)),
	}

func _build_sensitivity_ui() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "ControlTuning"
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(settings_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	settings_panel.add_child(column)

	look_value_label = Label.new()
	column.add_child(look_value_label)
	look_slider = HSlider.new()
	look_slider.min_value = 0.5
	look_slider.max_value = 2.0
	look_slider.step = 0.05
	look_slider.value = float(_game_state().get("look_sensitivity")) if _game_state() != null else 1.0
	look_slider.custom_minimum_size = Vector2(220, 20)
	look_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	look_slider.value_changed.connect(_on_look_sensitivity_changed)
	column.add_child(look_slider)

	movement_value_label = Label.new()
	column.add_child(movement_value_label)
	movement_slider = HSlider.new()
	movement_slider.min_value = 0.75
	movement_slider.max_value = 1.25
	movement_slider.step = 0.05
	movement_slider.value = float(_game_state().get("movement_speed_multiplier")) if _game_state() != null else 1.0
	movement_slider.custom_minimum_size = Vector2(220, 20)
	movement_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	movement_slider.value_changed.connect(_on_movement_speed_changed)
	column.add_child(movement_slider)
	_position_sensitivity_ui()
	_refresh_tuning_labels()

func _position_sensitivity_ui() -> void:
	if settings_panel == null:
		return
	var s := get_viewport_rect().size
	settings_panel.position = Vector2(s.x * 0.58, 18)
	settings_panel.size = Vector2(minf(s.x * 0.38, 330.0), 112)

func _refresh_tuning_labels() -> void:
	var state := _game_state()
	var look_value := 1.0
	var movement_value := 1.0
	if state != null:
		look_value = float(state.get("look_sensitivity"))
		movement_value = float(state.get("movement_speed_multiplier"))
	if look_value_label != null:
		look_value_label.text = "LOOK SENSITIVITY  %.2fx" % look_value
	if movement_value_label != null:
		movement_value_label.text = "MOVEMENT SPEED  %.2fx" % movement_value

func _on_look_sensitivity_changed(value: float) -> void:
	if _game_state() != null:
		_game_state().call("set_look_sensitivity", value)
	_refresh_tuning_labels()

func _on_movement_speed_changed(value: float) -> void:
	if _game_state() != null:
		_game_state().call("set_movement_speed_multiplier", value)
	_refresh_tuning_labels()

func get_virtual_move() -> Vector2:
	return joystick_vector

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_begin(event.index, event.position)
		else:
			_touch_end(event.index)
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position, event.relative)

func _touch_begin(index: int, pos: Vector2) -> void:
	if settings_panel != null and settings_panel.get_global_rect().has_point(pos):
		return
	for action in button_rects:
		if button_rects[action].has_point(pos):
			active_buttons[index] = action
			_pulse_button(action)
			if action == "sprint":
				Input.action_press("sprint")
			elif action == "interact":
				Input.action_press("interact")
				Input.action_release("interact")
			elif action == "crouch":
				Input.action_press("crouch")
				Input.action_release("crouch")
			elif action == "flashlight":
				Input.action_press("flashlight")
				Input.action_release("flashlight")
			elif action == "medical":
				Input.action_press("use_medical")
				Input.action_release("use_medical")
			elif action == "battery":
				Input.action_press("use_battery")
				Input.action_release("use_battery")
			return
	if pos.x < get_viewport_rect().size.x * 0.43 and joystick_finger == -1:
		joystick_finger = index
		joystick_origin = pos
		joystick_vector = Vector2.ZERO
		queue_redraw()
	elif look_finger == -1:
		look_finger = index

func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if index == joystick_finger:
		var radius := minf(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.14
		joystick_vector = ((pos - joystick_origin) / radius).limit_length(1.0)
		queue_redraw()
	elif index == look_finger:
		var target := get_tree().get_first_node_in_group("player")
		if target != null and target.has_method("apply_touch_look"):
			target.apply_touch_look(relative)

func _touch_end(index: int) -> void:
	if index == joystick_finger:
		joystick_finger = -1
		joystick_vector = Vector2.ZERO
	if index == look_finger:
		look_finger = -1
	if active_buttons.has(index):
		if active_buttons[index] == "sprint":
			Input.action_release("sprint")
		active_buttons.erase(index)
	queue_redraw()

func _pulse_button(action: String) -> void:
	var current := float(button_scales.get(action, 1.0))
	button_scales[action] = current
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(Callable(self, "_set_button_scale").bind(action), current, 1.18, 0.075)
	tween.tween_method(Callable(self, "_set_button_scale").bind(action), 1.18, 1.0, 0.13)

func _set_button_scale(value: float, action: String) -> void:
	button_scales[action] = value
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	modulate.a = 0.68
	var s := get_viewport_rect().size
	var radius := minf(s.x, s.y) * 0.14
	var origin := joystick_origin if joystick_finger != -1 else Vector2(radius * 1.45, s.y - radius * 1.45)
	draw_circle(origin, radius, Color(0.1, 0.42, 0.48, 0.075))
	draw_arc(origin, radius, 0.0, TAU, 40, Color(0.42, 0.72, 0.74, 0.20), 1.3)
	draw_circle(origin + joystick_vector * radius, radius * 0.34, Color(0.48, 0.78, 0.78, 0.22))
	var labels := {"interact":"F", "crouch":"C", "sprint":"RUN", "flashlight":"L", "medical":"MED", "battery":"BAT"}
	for action in button_rects:
		var rect: Rect2 = button_rects[action]
		var scale := float(button_scales.get(action, 1.0))
		var button_radius := rect.size.x * 0.48 * scale
		draw_circle(rect.get_center(), button_radius, Color(0.025, 0.045, 0.052, 0.24))
		draw_arc(rect.get_center(), button_radius, 0.0, TAU, 32, Color(0.48, 0.72, 0.74, 0.38), 1.4)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.58), labels[action], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 14, Color(0.78, 0.88, 0.88, 0.76))
