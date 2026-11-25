extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var packed := ResourceLoader.load("res://chapters/epilogue.tscn") as PackedScene
	assert(packed != null, "The 3D epilogue scene must load.")
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.has_node("PADD"), "The thermal PADD must exist.")
	assert(scene.has_node("MountainEyes"), "The mountain presence must exist.")
	var eyes := scene.get_node("MountainEyes") as Node3D
	var game_state := root.get_node("GameState")
	assert(not eyes.visible, "The eyes must remain hidden until the PADD is read.")
	scene.reveal_eyes()
	assert(eyes.visible, "Reading the final report must reveal the eyes.")
	assert(bool(game_state.call("get_flag", "epilogue_presence_revealed", false)), "The ending reveal must persist.")
	game_state.call("set_flag", "epilogue_presence_revealed", false)
	game_state.call("save_game")
	print("NEWBORN 3D snow epilogue / PADD / reveal test: PASS")
	scene.queue_free()
	quit(0)
