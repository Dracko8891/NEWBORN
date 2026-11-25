extends Control
## Landscape touch layer: left virtual stick, right look zone and contextual buttons.
## Desktop/gamepad input remains available; this layer is hidden outside mobile devices.

var joystick_finger := -1
var look_finger := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var active_buttons: Dictionary = {}
var button_rects: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = OS.has_feature("mobile")
	z_index = 100
	_rebuild_button_rects()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild_button_rects()
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
	for action in button_rects:
		if button_rects[action].has_point(pos):
			active_buttons[index] = action
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
		# Redraw on every stick movement so the thumb indicator follows the finger.
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

func _draw() -> void:
	if not visible:
		return
	var s := get_viewport_rect().size
	var radius := minf(s.x, s.y) * 0.14
	var origin := joystick_origin if joystick_finger != -1 else Vector2(radius * 1.45, s.y - radius * 1.45)
	draw_circle(origin, radius, Color(0.1, 0.72, 0.78, 0.16))
	draw_circle(origin + joystick_vector * radius, radius * 0.36, Color(0.3, 0.9, 0.9, 0.48))
	for action in button_rects:
		var rect: Rect2 = button_rects[action]
		draw_circle(rect.get_center(), rect.size.x * 0.48, Color(0.06, 0.16, 0.22, 0.72))
		draw_arc(rect.get_center(), rect.size.x * 0.48, 0.0, TAU, 32, Color(0.25, 0.85, 0.88, 0.9), 2.0)
		var labels := {"interact":"F", "crouch":"C", "sprint":"RUN", "flashlight":"L", "medical":"MED", "battery":"BAT"}
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.58), labels[action], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 14, Color(0.85, 0.98, 1.0))
