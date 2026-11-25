extends Node3D
@export_range(1, 7) var chapter_number: int = 1

const MAT_WALL := preload("res://materials/medical_wall.tres")
const MAT_FLOOR := preload("res://materials/medical_floor.tres")
const MAT_ALERT := preload("res://materials/emergency_red.tres")
const Campaign = preload("res://systems/campaign_data.gd")

func _ready() -> void:
	_ensure_environment()
	CampaignDirector.begin_chapter(chapter_number)
	_build_sector()
	_build_chapter_landmarks()
	_build_objectives()
	_spawn_hunter()

func _make_box(label: String, pos: Vector3, size: Vector3, mat: Material, solid: bool = true) -> void:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = label
	node.position = pos
	add_child(node)
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = mat
	node.add_child(mesh_node)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)

func _build_sector() -> void:
	var data := Campaign.get_chapter(chapter_number)
	var wall := _chapter_material(chapter_number, false)
	var floor_mat := _chapter_material(chapter_number, true)
	var alert := MAT_ALERT
	_make_box("Setor_Piso", Vector3(0, -0.2, 0), Vector3(18, 0.4, 70), floor_mat)
	_make_box("Setor_Teto", Vector3(0, 4.0, 0), Vector3(18, 0.3, 70), wall)
	_make_box("Parede_E", Vector3(-9.1, 2, 0), Vector3(0.3, 4, 70), wall)
	_make_box("Parede_D", Vector3(9.1, 2, 0), Vector3(0.3, 4, 70), wall)
	for i in range(11):
		var z := -32.0 + float(i) * 6.4
		_make_box("Arco_Estrutural_%02d" % i, Vector3(0, 3.65, z), Vector3(18, 0.35, 0.45), wall)
		_make_box("Painel_Tecnico_E_%02d" % i, Vector3(-8.88, 2.6, z + 2.1), Vector3(0.12, 1.4, 2.2), floor_mat, false)
		_make_box("Painel_Tecnico_D_%02d" % i, Vector3(8.88, 2.6, z + 2.1), Vector3(0.12, 1.4, 2.2), floor_mat, false)
	for side in [-1.0, 1.0]:
		for j in range(5):
			_make_box("Conduite_%d_%d" % [int(side), j], Vector3(side * 7.8, 3.25, -25.0 + float(j) * 12.0), Vector3(0.35, 0.35, 5.0), alert, false)
	_make_box("Console_Setor", Vector3(-6.8, 1.3, -10), Vector3(0.4, 1.8, 2.4), alert, false)
	_make_box("Porta_Saida", Vector3(0, 1.8, -34), Vector3(3.5, 3.6, 0.4), alert)
	_make_box("Mesa_Operacional", Vector3(4.8, 0.7, 2), Vector3(2.8, 1.4, 1.4), wall)
	_make_box("Armario_Industrial", Vector3(-5.8, 1.2, 10), Vector3(1.2, 2.4, 1.2), floor_mat)
	_make_box("Plataforma_Servico", Vector3(0, 1.0, 19), Vector3(8, 0.25, 4), wall)
	var player := get_node_or_null("Player")
	if player == null:
		_spawn_player()

func _spawn_player() -> void:
	var player_scene := load("res://scenes/player.tscn")
	if player_scene != null:
		var p := player_scene.instantiate()
		p.name = "Player"
		p.position = Vector3(0, 1, 28)
		add_child(p)

func _build_objectives() -> void:
	var data := Campaign.get_chapter(chapter_number)
	var objectives: Array = data.get("objectives", [])
	for i in range(objectives.size()):
		var trigger := Area3D.new()
		trigger.name = "Objective_%02d" % (i + 1)
		trigger.position = Vector3(0, 1.1, 20.0 - float(i) * 11.0)
		trigger.set_script(load("res://scripts/objective_trigger.gd"))
		trigger.set("objective_id", "c%d_o%d" % [chapter_number, i + 1])
		trigger.set("prompt", str(objectives[i]))
		add_child(trigger)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 1.7
		collision.shape = shape
		trigger.add_child(collision)
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		marker.mesh = sphere
		marker.material_override = MAT_ALERT
		trigger.add_child(marker)

func _spawn_hunter() -> void:
	var hunter_scene := load("res://ai/newborn_hunter.tscn")
	if hunter_scene == null:
		return
	var hunter := hunter_scene.instantiate()
	hunter.name = "NewbornHunter"
	hunter.position = Vector3(0, 0.1, -18)
	add_child(hunter)

func _chapter_material(chapter: int, floor_surface: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var colors := [
		Color(0.22, 0.27, 0.29), Color(0.12, 0.24, 0.29),
		Color(0.26, 0.22, 0.29), Color(0.18, 0.31, 0.25),
		Color(0.16, 0.20, 0.24), Color(0.12, 0.13, 0.18),
		Color(0.26, 0.24, 0.20)
	]
	var base: Color = colors[clampi(chapter - 1, 0, 6)]
	if floor_surface:
		base = base.darkened(0.58)
	material.albedo_color = base
	material.metallic = 0.42 if not floor_surface else 0.62
	material.roughness = 0.68
	return material

func _build_chapter_landmarks() -> void:
	match chapter_number:
		1:
			for i in range(4):
				_make_box("Leito_Medico_%02d" % i, Vector3(-5.8, 0.55, -22.0 + float(i) * 5.5), Vector3(2.0, 1.1, 2.8), MAT_WALL)
			_make_box("Balcao_Recepcao", Vector3(5.5, 0.65, 12), Vector3(3.2, 1.3, 1.2), MAT_WALL)
		2:
			_make_box("Passarela_Mezzanino", Vector3(0, 3.0, -2), Vector3(14, 0.3, 18), MAT_WALL)
			for i in range(3):
				_make_cylinder("Nucleo_Holografico_%d" % i, Vector3(-4.5 + float(i) * 4.5, 1.6, -5), 0.7, 3.0, MAT_ALERT)
			_make_box("Matriz_Central", Vector3(0, 1.5, 8), Vector3(5.5, 2.6, 2.0), MAT_ALERT)
		3:
			for i in range(6):
				_make_box("Modulo_Alojamento_%02d" % i, Vector3(-6.0 + float(i % 2) * 12.0, 1.1, -22.0 + float(i / 2) * 7.0), Vector3(2.2, 2.2, 3.4), MAT_WALL)
			_make_box("Mesa_Terapia_Acustica", Vector3(0, 0.8, 4), Vector3(4.0, 1.6, 2.0), MAT_ALERT)
		4:
			for i in range(5):
				_make_cylinder("Tanque_Genese_%02d" % i, Vector3(-6.0 + float(i % 3) * 6.0, 2.0, -20.0 + float(i / 3) * 14.0), 1.25, 4.0, MAT_ALERT)
			_make_box("Passarela_Superior_Respiravel", Vector3(0, 2.1, 10), Vector3(15, 0.3, 5), MAT_WALL)
		5:
			_make_cylinder("Reator_Plasma", Vector3(0, 1.8, -12), 3.0, 5.5, MAT_ALERT)
			for i in range(3):
				_make_box("Passarela_Nucleo_%d" % i, Vector3(-5.0 + float(i) * 5.0, 1.0 + float(i % 2) * 0.7, -12), Vector3(1.2, 0.2, 17), MAT_WALL)
			_make_box("Console_Bracos_Roboticos", Vector3(6, 1.0, 10), Vector3(2.5, 2.0, 1.2), MAT_ALERT)
		6:
			for i in range(4):
				_make_cylinder("Tubo_Evolucao_%d" % i, Vector3(-6.0 + float(i) * 4.0, 2.0, -14), 0.85, 4.2, MAT_ALERT)
			_make_box("Camara_00", Vector3(0, 1.8, -28), Vector3(8, 3.6, 0.35), MAT_WALL)
			_make_box("Terminal_Download", Vector3(6, 1.2, -24), Vector3(1.0, 2.4, 1.0), MAT_ALERT)
		7:
			_make_box("Plataforma_Carga", Vector3(0, 0.5, -16), Vector3(14, 1.0, 18), MAT_WALL)
			_make_box("Cabine_Override", Vector3(-6, 1.8, -27), Vector3(3.0, 3.6, 3.0), MAT_ALERT)
			for i in range(3):
				_make_cylinder("Acoplamento_Hidraulico_%d" % i, Vector3(-5.0 + float(i) * 5.0, 1.1, -8), 0.45, 2.2, MAT_ALERT)

func _make_cylinder(label: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var node := Node3D.new()
	node.name = label
	node.position = pos
	add_child(node)
	var mesh_node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_node.mesh = mesh
	mesh_node.material_override = mat
	node.add_child(mesh_node)

func _ensure_environment() -> void:
	if get_tree().current_scene != null and get_tree().current_scene.find_child("WorldEnvironment", true, false) != null:
		return
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.018, 0.024)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.42)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.19, 0.21)
	env.fog_density = 0.018
	world.environment = env
	add_child(world)
