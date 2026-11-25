extends SceneTree

func _initialize() -> void:
	var orientation := int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))
	assert(orientation == 0, "Android orientation must be SCREEN_LANDSCAPE (0), not sensor-controlled.")
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	assert(width > height, "The game viewport must be landscape (width greater than height).")
	print("NEWBORN fixed landscape orientation test: PASS")
	quit(0)
