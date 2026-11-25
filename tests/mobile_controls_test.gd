extends SceneTree

const TouchControlsScript = preload("res://scripts/mobile_touch_controls.gd")

class LookTarget:
	extends Node
	var look_delta := Vector2.ZERO

	func apply_touch_look(delta: Vector2) -> void:
		look_delta += delta

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		game_state = Node.new()
		game_state.name = "GameState"
		game_state.set_script(load("res://systems/game_state.gd"))
		root.add_child(game_state)
		await process_frame
	var controls := Control.new()
	controls.set_script(TouchControlsScript)
	root.add_child(controls)
	await process_frame
	controls.visible = true
	controls._rebuild_button_rects()
	assert(controls.look_slider != null and controls.movement_slider != null, "Mobile control tuning sliders must exist")
	var previous_look := float(game_state.get("look_sensitivity"))
	controls.look_slider.value = 1.25
	assert(is_equal_approx(float(game_state.get("look_sensitivity")), 1.25), "Look slider must update the global setting")
	var saved_config := ConfigFile.new()
	assert(saved_config.load("user://config.cfg") == OK, "Look sensitivity must persist to user://config.cfg")
	assert(is_equal_approx(float(saved_config.get_value("controls", "look_sensitivity", 0.0)), 1.25), "Saved look sensitivity must match slider")
	controls.look_slider.value = previous_look
	controls._pulse_button("interact")
	assert(controls.button_scales.has("interact"), "Touch press must start a button pulse tween")

	for action in ["interact", "crouch", "sprint", "flashlight", "medical", "battery"]:
		assert(controls.button_rects.has(action), "Missing mobile button: " + action)
		var rect: Rect2 = controls.button_rects[action]
		assert(rect.position.x >= 0.0 and rect.position.y >= 0.0)
		assert(rect.end.x <= controls.get_viewport_rect().size.x)
		assert(rect.end.y <= controls.get_viewport_rect().size.y)

	# Multi-touch joystick must clamp to a unit vector and release cleanly.
	controls._touch_begin(11, Vector2(100, 300))
	assert(controls.joystick_finger == 11)
	controls._touch_drag(11, Vector2(10000, -10000), Vector2.ZERO)
	assert(controls.joystick_vector.length() <= 1.001)
	controls._touch_end(11)
	assert(controls.joystick_finger == -1)
	assert(controls.joystick_vector == Vector2.ZERO)

	# Sprint is held only while its touch is held.
	var sprint_rect: Rect2 = controls.button_rects["sprint"]
	controls._touch_begin(12, sprint_rect.get_center())
	assert(Input.is_action_pressed("sprint"))
	controls._touch_end(12)
	assert(not Input.is_action_pressed("sprint"))

	# Independent right-side touch drives look while left stick remains active.
	var look_target := LookTarget.new()
	look_target.add_to_group("player")
	root.add_child(look_target)
	controls._touch_begin(13, Vector2(controls.get_viewport_rect().size.x * 0.7, 180))
	assert(controls.look_finger == 13)
	controls._touch_drag(13, Vector2.ZERO, Vector2(24, -12))
	assert(look_target.look_delta == Vector2(24, -12))
	controls._touch_end(13)
	assert(controls.look_finger == -1)

	print("NEWBORN mobile touch layout / joystick / multitouch tests: PASS")
	quit(0)
