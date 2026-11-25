extends Node3D
@export_range(1, 7) var chapter_number: int = 1

const MAT_WALL := preload("res://materials/medical_wall.tres")
const MAT_FLOOR := preload("res://materials/medical_floor.tres")
const MAT_ALERT := preload("res://materials/emergency_red.tres")
const Campaign = preload("res://systems/campaign_data.gd")

func _ready() -> void:
	CampaignDirector.begin_chapter(chapter_number)
	_build_sector()
	_build_objectives()

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
	var wall := MAT_WALL
	var floor_mat := MAT_FLOOR
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
