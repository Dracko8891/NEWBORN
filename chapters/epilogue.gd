extends Node3D
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
var mountain_eyes: Node3D

func _ready() -> void:
	_build_environment()
	_build_snowfield()
	_build_mountain_and_chimney()
	_build_padd()
	_spawn_player()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "EpilogueEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.055, 0.085)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.5, 0.62)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.48, 0.56, 0.68)
	env.fog_density = 0.012
	world.environment = env
	add_child(world)
	var moonlight := DirectionalLight3D.new()
	moonlight.name = "Moonlight"
	moonlight.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	moonlight.light_color = Color(0.62, 0.72, 0.9)
	moonlight.light_energy = 0.42
	moonlight.shadow_enabled = true
	add_child(moonlight)

func _build_snowfield() -> void:
	var snow := StandardMaterial3D.new()
	snow.albedo_color = Color(0.72, 0.79, 0.88)
	snow.roughness = 0.96
	var ground := StaticBody3D.new()
	ground.name = "SnowGround"
	ground.position = Vector3(0, -0.25, -22)
	add_child(ground)
	var mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(100, 0.5, 110)
	mesh.mesh = plane
	mesh.material_override = snow
	ground.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = plane.size
	collision.shape = shape
	ground.add_child(collision)

func _build_mountain_and_chimney() -> void:
	var mountain_material := StandardMaterial3D.new()
	mountain_material.albedo_color = Color(0.22, 0.28, 0.37)
	mountain_material.roughness = 1.0
	var mountain := MeshInstance3D.new()
	mountain.name = "DistantMountain"
	var peak := CylinderMesh.new()
	peak.top_radius = 0.35
	peak.bottom_radius = 34.0
	peak.height = 31.0
	mountain.mesh = peak
	mountain.material_override = mountain_material
	mountain.position = Vector3(0, 14.8, -48)
	add_child(mountain)
	var chimney := StaticBody3D.new()
	chimney.name = "MountainChimney"
	chimney.position = Vector3(0, 4.2, -28)
	add_child(chimney)
	var chimney_mesh := MeshInstance3D.new()
	var chimney_box := BoxMesh.new()
	chimney_box.size = Vector3(1.6, 8.4, 1.6)
	chimney_mesh.mesh = chimney_box
	var chimney_material := StandardMaterial3D.new()
	chimney_material.albedo_color = Color(0.12, 0.15, 0.19)
	chimney_material.roughness = 0.9
	chimney_mesh.material_override = chimney_material
	chimney.add_child(chimney_mesh)
	var chimney_collision := CollisionShape3D.new()
	var chimney_shape := BoxShape3D.new()
	chimney_shape.size = chimney_box.size
	chimney_collision.shape = chimney_shape
	chimney.add_child(chimney_collision)
	mountain_eyes = Node3D.new()
	mountain_eyes.name = "MountainEyes"
	mountain_eyes.position = Vector3(0, 8.2, -27.05)
	mountain_eyes.visible = false
	add_child(mountain_eyes)
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.95, 0.72, 0.52)
	eye_material.emission_enabled = true
	eye_material.emission = Color(1.0, 0.28, 0.08)
	eye_material.emission_energy_multiplier = 3.5
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18
		sphere.height = 0.36
		eye.mesh = sphere
		eye.material_override = eye_material
		eye.position = Vector3(side * 0.38, 0.0, 0.0)
		mountain_eyes.add_child(eye)

func _build_padd() -> void:
	var padd := Area3D.new()
	padd.name = "PADD"
	padd.position = Vector3(0, 1.2, 11.4)
	padd.set_script(load("res://scripts/epilogue_padd.gd"))
	add_child(padd)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.6, 0.45)
	collision.shape = shape
	padd.add_child(collision)
	var mesh := MeshInstance3D.new()
	var device := BoxMesh.new()
	device.size = Vector3(0.65, 1.1, 0.18)
	mesh.mesh = device
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.22, 0.27)
	material.emission_enabled = true
	material.emission = Color(0.04, 0.28, 0.34)
	material.emission_energy_multiplier = 0.8
	mesh.material_override = material
	padd.add_child(mesh)

func _spawn_player() -> void:
	var player := PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector3(0, 0, 14)
	add_child(player)

func reveal_eyes() -> void:
	if mountain_eyes == null:
		return
	mountain_eyes.visible = true
	mountain_eyes.scale = Vector3.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mountain_eyes, "scale", Vector3.ONE, 1.6)
	GameState.set_flag("epilogue_presence_revealed")
	GameState.save_game()
