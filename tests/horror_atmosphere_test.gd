extends SceneTree
const Atmosphere = preload("res://systems/horror_atmosphere.gd")
const PlayerScene = preload("res://scenes/player.tscn")
const HunterScene = preload("res://ai/newborn_hunter.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)
	var hunter := HunterScene.instantiate()
	root.add_child(hunter)
	var atmosphere := Node3D.new()
	atmosphere.set_script(Atmosphere)
	root.add_child(atmosphere)
	await process_frame
	assert(atmosphere.get_node_or_null("CinematicOverlay") != null, "Cinematic overlay must be created.")
	assert(player.get_node_or_null("Head/Camera3D/ArthurFirstPersonArms") != null, "First-person arms must exist.")
	assert(hunter.get_node_or_null("PorcelainTorso") != null, "Organic Newborn torso must exist.")
	assert(hunter.get_node_or_null("SealedSkull/DoubleJaw") != null, "Double jaw must exist.")
	assert(atmosphere.get_node_or_null("FloatingSpores") != null, "Low-count dust particles must exist.")
	print("NEWBORN cinematic atmosphere / viewmodel / organic hunter test: PASS")
	quit(0)
